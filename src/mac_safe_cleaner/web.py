from __future__ import annotations

import json
import os
import secrets
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from .cli import (
    build_scan_report,
    list_quarantine_sessions,
    purge_sessions,
    quarantine_candidates,
    restore_records,
    write_markdown_report,
)


REPORTS_ROOT = Path(os.environ.get("FREE_MY_MAC_REPORTS") or os.environ.get("MAC_SAFE_CLEANER_REPORTS", "/data/reports"))
CSRF_HEADER = "X-Free-My-Mac-Token"
LEGACY_CSRF_HEADER = "X-Mac-Safe-Cleaner-Token"
STATE = {
    "report": None,
    "token": secrets.token_urlsafe(24),
    "scan": {
        "running": False,
        "started_at": None,
        "finished_at": None,
        "elapsed_seconds": 0,
        "message": "Pronto.",
        "error": None,
        "candidate_count": 0,
        "total_size_bytes": 0,
    },
}
STATE_LOCK = threading.Lock()


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temp.write_text(text, encoding="utf-8")
    os.replace(temp, path)


INDEX_HTML = """<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Free My Mac Desktop</title>
  <style>
    :root {
      --bg: #f6f7f8;
      --panel: #ffffff;
      --text: #1f2933;
      --muted: #697386;
      --line: #d8dee7;
      --accent: #176b87;
      --accent-strong: #10566d;
      --danger: #aa2e25;
      --ok: #277a46;
      --warn: #9a6200;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--text);
    }
    header {
      padding: 18px 24px;
      background: var(--panel);
      border-bottom: 1px solid var(--line);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    h1 { margin: 0; font-size: 20px; letter-spacing: 0; }
    main { padding: 20px 24px 32px; display: grid; gap: 16px; }
    .toolbar, .summary, .progress, .sessions {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 16px;
    }
    .toolbar { display: flex; flex-wrap: wrap; align-items: end; gap: 12px; }
    label { display: grid; gap: 6px; font-size: 12px; color: var(--muted); }
    input[type="number"] {
      width: 120px;
      padding: 8px 10px;
      border-radius: 6px;
      border: 1px solid var(--line);
      background: #fff;
      color: var(--text);
    }
    .checkline {
      display: flex;
      align-items: center;
      gap: 8px;
      min-height: 36px;
      color: var(--text);
      font-size: 14px;
    }
    button {
      min-height: 36px;
      border: 1px solid var(--line);
      background: #fff;
      border-radius: 6px;
      padding: 8px 12px;
      color: var(--text);
      cursor: pointer;
      font-weight: 600;
    }
    button.primary { background: var(--accent); border-color: var(--accent); color: #fff; }
    button.primary:hover { background: var(--accent-strong); }
    button.danger { color: #fff; background: var(--danger); border-color: var(--danger); }
    .summary { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
    .progress {
      display: grid;
      gap: 10px;
    }
    .progress-row {
      display: grid;
      grid-template-columns: 180px minmax(0, 1fr);
      gap: 12px;
      align-items: center;
      font-size: 14px;
    }
    .bar {
      height: 10px;
      overflow: hidden;
      border-radius: 999px;
      background: #e5ebf0;
      border: 1px solid var(--line);
    }
    .bar > div {
      width: 35%;
      height: 100%;
      border-radius: 999px;
      background: var(--accent);
      transform: translateX(-100%);
    }
    .bar.running > div {
      animation: sweep 1.4s linear infinite;
    }
    @keyframes sweep {
      from { transform: translateX(-100%); }
      to { transform: translateX(300%); }
    }
    .metric {
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 12px;
      min-height: 76px;
    }
    .metric span { color: var(--muted); font-size: 12px; display: block; margin-bottom: 8px; }
    .metric strong { font-size: 22px; }
    .table-wrap {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      overflow: auto;
    }
    table { width: 100%; min-width: 1000px; border-collapse: collapse; }
    th, td {
      border-bottom: 1px solid var(--line);
      padding: 10px 12px;
      text-align: left;
      vertical-align: top;
      font-size: 13px;
    }
    th { position: sticky; top: 0; background: #eef2f5; z-index: 1; color: #354152; font-size: 12px; }
    code { overflow-wrap: anywhere; white-space: normal; }
    .path { max-width: 520px; }
    .status { min-height: 22px; color: var(--muted); font-size: 14px; }
    .status.ok { color: var(--ok); }
    .status.warn { color: var(--warn); }
    .status.err { color: var(--danger); }
    .actions { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
    .sessions { display: grid; gap: 12px; }
    .session { border: 1px solid var(--line); border-radius: 8px; padding: 12px; display: grid; gap: 10px; }
    .session h3 { margin: 0; font-size: 15px; }
    .small { color: var(--muted); font-size: 12px; }
    @media (max-width: 900px) {
      header { align-items: flex-start; flex-direction: column; }
      .summary { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Free My Mac Desktop</h1>
      <div class="small">Clean Your Mac com varredura conservadora, quarentena reversivel e purga controlada.</div>
    </div>
    <div id="status" class="status">Pronto.</div>
  </header>

  <main>
    <section class="toolbar">
      <label>Tamanho minimo (MB)
        <input id="minSize" type="number" min="1" value="50">
      </label>
      <label>Mais antigo que (dias)
        <input id="olderThan" type="number" min="1" value="30">
      </label>
      <label class="checkline">
        <input id="includeSystem" type="checkbox">
        incluir logs/caches globais acessiveis
      </label>
      <button class="primary" id="scanBtn">Varrer</button>
      <button id="selectAllBtn">Selecionar tudo</button>
      <button id="clearBtn">Limpar selecao</button>
      <button class="danger" id="quarantineBtn">Enviar selecionados para quarentena</button>
    </section>

    <section class="summary">
      <div class="metric"><span>Candidatos</span><strong id="candidateCount">0</strong></div>
      <div class="metric"><span>Espaco potencial</span><strong id="totalSize">0 B</strong></div>
      <div class="metric"><span>Selecionados</span><strong id="selectedCount">0</strong></div>
      <div class="metric"><span>Raiz analisada</span><strong id="scanHome" style="font-size:13px;">-</strong></div>
    </section>

    <section class="progress">
      <div class="progress-row">
        <strong>Varredura</strong>
        <span id="scanMessage">Nenhuma varredura em andamento.</span>
      </div>
      <div class="progress-row">
        <strong>Tempo decorrido</strong>
        <span id="scanElapsed">0s</span>
      </div>
      <div id="scanBar" class="bar"><div></div></div>
    </section>

    <section class="table-wrap">
      <table>
        <thead>
          <tr>
            <th><input id="masterCheck" type="checkbox" /></th>
            <th>ID</th>
            <th>Tipo</th>
            <th>Tamanho</th>
            <th>Idade</th>
            <th>Risco</th>
            <th>Motivo</th>
            <th>Caminho</th>
          </tr>
        </thead>
        <tbody id="candidateRows">
          <tr><td colspan="8">Clique em Varrer para carregar candidatos.</td></tr>
        </tbody>
      </table>
    </section>

    <section class="sessions">
      <div class="actions">
        <button id="refreshSessionsBtn">Atualizar quarentena</button>
        <label>Purga de quarentenas com mais de
          <input id="purgeDays" type="number" min="1" value="30">
        </label>
        <button id="dryPurgeBtn">Simular purga</button>
        <button class="danger" id="executePurgeBtn">Apagar permanentemente</button>
      </div>
      <div id="sessionsList" class="small">Nenhuma sessao carregada.</div>
    </section>
  </main>

  <script>
    const TOKEN = "__TOKEN__";
    let report = null;
    let selected = new Set();
    let scanPoll = null;
    const $ = (id) => document.getElementById(id);

    function fmtSize(bytes) {
      const units = ["B", "KB", "MB", "GB", "TB"];
      let value = Number(bytes || 0);
      for (const unit of units) {
        if (value < 1024 || unit === units[units.length - 1]) return `${value.toFixed(1)} ${unit}`;
        value /= 1024;
      }
      return `${bytes} B`;
    }

    function setStatus(text, kind = "") {
      const el = $("status");
      el.textContent = text;
      el.className = `status ${kind}`;
    }

    function setScanControls(running) {
      $("scanBtn").disabled = running;
      $("quarantineBtn").disabled = running;
      $("scanBar").classList.toggle("running", running);
    }

    function renderScanStatus(scan) {
      $("scanMessage").textContent = scan.message || "Pronto.";
      $("scanElapsed").textContent = `${Math.floor(scan.elapsed_seconds || 0)}s`;
      if (scan.running) {
        setScanControls(true);
        setStatus(`Varredura em andamento: ${Math.floor(scan.elapsed_seconds || 0)}s`, "warn");
      } else {
        setScanControls(false);
      }
    }

    async function api(path, body = null) {
      const options = body ? {
        method: "POST",
        headers: {"Content-Type": "application/json", "X-Free-My-Mac-Token": TOKEN},
        body: JSON.stringify(body)
      } : {};
      const res = await fetch(path, options);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Falha na operacao.");
      return data;
    }

    function updateSelection() {
      $("selectedCount").textContent = selected.size;
      $("masterCheck").checked = report && report.candidates.length > 0 && selected.size === report.candidates.length;
      document.querySelectorAll("[data-candidate]").forEach((box) => box.checked = selected.has(box.dataset.candidate));
    }

    function renderReport(nextReport) {
      report = nextReport;
      selected = new Set();
      $("candidateCount").textContent = report.candidates.length;
      $("totalSize").textContent = fmtSize(report.total_size_bytes);
      $("scanHome").textContent = report.policy.scan_home || "-";
      const rows = $("candidateRows");
      rows.innerHTML = "";
      if (!report.candidates.length) {
        rows.innerHTML = '<tr><td colspan="8">Nenhum candidato encontrado.</td></tr>';
        updateSelection();
        return;
      }
      for (const item of report.candidates) {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td><input type="checkbox" data-candidate="${item.id}"></td>
          <td><code>${item.id}</code></td>
          <td>${item.kind}</td>
          <td>${fmtSize(item.size_bytes)}</td>
          <td>${item.age_days} dias</td>
          <td>${item.risk}</td>
          <td>${item.reason}</td>
          <td class="path"><code>${item.path}</code></td>
        `;
        rows.appendChild(tr);
      }
      document.querySelectorAll("[data-candidate]").forEach((box) => {
        box.addEventListener("change", () => {
          if (box.checked) selected.add(box.dataset.candidate);
          else selected.delete(box.dataset.candidate);
          updateSelection();
        });
      });
      updateSelection();
    }

    async function scan() {
      setStatus("Iniciando varredura...", "warn");
      const data = await api("/api/scan", {
        min_size_mb: Number($("minSize").value),
        older_than_days: Number($("olderThan").value),
        include_system: $("includeSystem").checked
      });
      renderScanStatus(data.scan);
      if (scanPoll) clearInterval(scanPoll);
      scanPoll = setInterval(pollScan, 1000);
      await pollScan();
    }

    async function pollScan() {
      const data = await api("/api/scan-status");
      renderScanStatus(data.scan);
      if (!data.scan.running) {
        if (scanPoll) clearInterval(scanPoll);
        scanPoll = null;
        if (data.report) {
          renderReport(data.report);
          setStatus(`Varredura concluida em ${Math.floor(data.scan.elapsed_seconds || 0)}s: ${data.report.candidates.length} candidatos.`, "ok");
        } else if (data.scan.error) {
          setStatus(data.scan.error, "err");
        }
      }
    }

    async function quarantineSelected() {
      if (!report || selected.size === 0) {
        setStatus("Selecione pelo menos um item.", "warn");
        return;
      }
      if (!confirm(`Mover ${selected.size} item(ns) para quarentena?`)) return;
      setStatus("Movendo para quarentena...", "warn");
      const data = await api("/api/quarantine", {ids: [...selected]});
      setStatus(`Movidos: ${data.result.moved}. Sessao: ${data.result.session}`, "ok");
      await scan();
      await loadSessions();
    }

    async function loadSessions() {
      const data = await api("/api/sessions");
      const el = $("sessionsList");
      el.innerHTML = "";
      if (!data.sessions.length) {
        el.textContent = "Nenhuma sessao de quarentena encontrada.";
        return;
      }
      for (const session of data.sessions) {
        const box = document.createElement("div");
        box.className = "session";
        const items = session.items.map((item) => `
          <label class="checkline">
            <input type="checkbox" data-restore-session="${session.session}" data-restore-id="${item.id}">
            <code>${item.id}</code> ${fmtSize(item.size_bytes)} - <code>${item.original_path}</code>
          </label>
        `).join("");
        box.innerHTML = `
          <h3>${session.session}</h3>
          <div class="small">${session.item_count} item(ns), ${fmtSize(session.size_bytes)}, ${session.age_days} dias - ${session.path}</div>
          <div>${items || "Manifesto vazio."}</div>
          <div class="actions">
            <button data-restore-all="${session.session}">Restaurar tudo</button>
            <button data-restore-selected="${session.session}">Restaurar selecionados</button>
          </div>
        `;
        el.appendChild(box);
      }
      document.querySelectorAll("[data-restore-all]").forEach((btn) => {
        btn.addEventListener("click", async () => {
          if (!confirm("Restaurar todos os itens desta sessao?")) return;
          const data = await api("/api/restore", {session: btn.dataset.restoreAll, all: true});
          setStatus(`Restaurados: ${data.result.restored}`, "ok");
          await loadSessions();
        });
      });
      document.querySelectorAll("[data-restore-selected]").forEach((btn) => {
        btn.addEventListener("click", async () => {
          const session = btn.dataset.restoreSelected;
          const ids = [...document.querySelectorAll(`[data-restore-session="${session}"]:checked`)].map((box) => box.dataset.restoreId);
          if (!ids.length) {
            setStatus("Selecione itens da sessao para restaurar.", "warn");
            return;
          }
          const data = await api("/api/restore", {session, ids});
          setStatus(`Restaurados: ${data.result.restored}`, "ok");
          await loadSessions();
        });
      });
    }

    async function purge(execute) {
      if (execute && !confirm("Apagar permanentemente quarentenas antigas? Esta acao nao pode ser desfeita.")) return;
      const data = await api("/api/purge", {
        older_than_days: Number($("purgeDays").value),
        execute
      });
      setStatus(`${execute ? "Purga executada" : "Simulacao"}: ${data.sessions.length} sessao(oes).`, execute ? "ok" : "warn");
      await loadSessions();
    }

    $("scanBtn").addEventListener("click", () => scan().catch((err) => setStatus(err.message, "err")));
    $("quarantineBtn").addEventListener("click", () => quarantineSelected().catch((err) => setStatus(err.message, "err")));
    $("selectAllBtn").addEventListener("click", () => {
      if (!report) return;
      selected = new Set(report.candidates.map((item) => item.id));
      updateSelection();
    });
    $("clearBtn").addEventListener("click", () => {
      selected.clear();
      updateSelection();
    });
    $("masterCheck").addEventListener("change", (event) => {
      if (!report) return;
      selected = event.target.checked ? new Set(report.candidates.map((item) => item.id)) : new Set();
      updateSelection();
    });
    $("refreshSessionsBtn").addEventListener("click", () => loadSessions().catch((err) => setStatus(err.message, "err")));
    $("dryPurgeBtn").addEventListener("click", () => purge(false).catch((err) => setStatus(err.message, "err")));
    $("executePurgeBtn").addEventListener("click", () => purge(true).catch((err) => setStatus(err.message, "err")));
    pollScan().catch(() => {});
    loadSessions().catch(() => {});
  </script>
</body>
</html>
"""


def scan_status_payload() -> dict:
    with STATE_LOCK:
        scan = dict(STATE["scan"])
        if scan["running"] and scan["started_at"]:
            scan["elapsed_seconds"] = time.time() - float(scan["started_at"])
        report = STATE.get("report")
    return {"scan": scan, "report": report if not scan["running"] else None}


def run_scan_job(min_size_mb: int, older_than_days: int, include_system: bool) -> None:
    started = time.time()
    try:
        with STATE_LOCK:
            STATE["scan"]["message"] = "Percorrendo logs, caches, Downloads e dados de desenvolvimento..."

        report = build_scan_report(min_size_mb, older_than_days, include_system)
        REPORTS_ROOT.mkdir(parents=True, exist_ok=True)
        atomic_write_text(
            REPORTS_ROOT / "web-latest.json",
            json.dumps(report, indent=2, ensure_ascii=False),
        )

        temp_markdown = REPORTS_ROOT / f".web-latest.{os.getpid()}.md.tmp"
        write_markdown_report(temp_markdown, report)
        os.replace(temp_markdown, REPORTS_ROOT / "web-latest.md")

        elapsed = time.time() - started
        with STATE_LOCK:
            STATE["report"] = report
            STATE["scan"] = {
                "running": False,
                "started_at": started,
                "finished_at": time.time(),
                "elapsed_seconds": elapsed,
                "message": f"Varredura concluida em {elapsed:.1f}s.",
                "error": None,
                "candidate_count": len(report["candidates"]),
                "total_size_bytes": report["total_size_bytes"],
            }
    except Exception as exc:
        elapsed = time.time() - started
        with STATE_LOCK:
            STATE["scan"] = {
                "running": False,
                "started_at": started,
                "finished_at": time.time(),
                "elapsed_seconds": elapsed,
                "message": "Varredura falhou.",
                "error": str(exc),
                "candidate_count": 0,
                "total_size_bytes": 0,
            }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: object) -> None:
        return

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/":
            html = INDEX_HTML.replace("__TOKEN__", str(STATE["token"]))
            self.respond_text(html, "text/html; charset=utf-8")
            return
        if parsed.path == "/api/sessions":
            self.respond_json({"sessions": list_quarantine_sessions()})
            return
        if parsed.path == "/api/scan-status":
            self.respond_json(scan_status_payload())
            return
        self.respond_json({"error": "Nao encontrado."}, HTTPStatus.NOT_FOUND)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        token = self.headers.get(CSRF_HEADER) or self.headers.get(LEGACY_CSRF_HEADER)
        if token != STATE["token"]:
            self.respond_json({"error": "Token invalido."}, HTTPStatus.FORBIDDEN)
            return
        try:
            payload = self.read_json()
            if parsed.path == "/api/scan":
                self.handle_scan(payload)
            elif parsed.path == "/api/quarantine":
                self.handle_quarantine(payload)
            elif parsed.path == "/api/restore":
                self.handle_restore(payload)
            elif parsed.path == "/api/purge":
                self.handle_purge(payload)
            else:
                self.respond_json({"error": "Nao encontrado."}, HTTPStatus.NOT_FOUND)
        except Exception as exc:
            self.respond_json({"error": str(exc)}, HTTPStatus.INTERNAL_SERVER_ERROR)

    def handle_scan(self, payload: dict) -> None:
        with STATE_LOCK:
            if STATE["scan"]["running"]:
                self.respond_json(scan_status_payload())
                return

            started = time.time()
            STATE["scan"] = {
                "running": True,
                "started_at": started,
                "finished_at": None,
                "elapsed_seconds": 0,
                "message": "Varredura iniciada.",
                "error": None,
                "candidate_count": 0,
                "total_size_bytes": 0,
            }

        thread = threading.Thread(
            target=run_scan_job,
            args=(
                int(payload.get("min_size_mb", 50)),
                int(payload.get("older_than_days", 30)),
                bool(payload.get("include_system", False)),
            ),
            daemon=True,
        )
        thread.start()
        self.respond_json(scan_status_payload())

    def handle_quarantine(self, payload: dict) -> None:
        report = STATE.get("report")
        if not report:
            latest = REPORTS_ROOT / "web-latest.json"
            if latest.exists():
                try:
                    report = json.loads(latest.read_text(encoding="utf-8"))
                except OSError:
                    report = None
        if not report:
            self.respond_json({"error": "Rode uma varredura antes."}, HTTPStatus.BAD_REQUEST)
            return
        result = quarantine_candidates(report, payload.get("ids"), bool(payload.get("all", False)))
        self.respond_json({"result": result})

    def handle_restore(self, payload: dict) -> None:
        session = payload.get("session")
        if not session:
            self.respond_json({"error": "Sessao obrigatoria."}, HTTPStatus.BAD_REQUEST)
            return
        result = restore_records(session, payload.get("ids"), bool(payload.get("all", False)))
        self.respond_json({"result": result})

    def handle_purge(self, payload: dict) -> None:
        sessions = purge_sessions(int(payload.get("older_than_days", 30)), bool(payload.get("execute", False)))
        self.respond_json({"sessions": sessions})

    def read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", "0") or 0)
        if length <= 0:
            return {}
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def respond_text(self, text: str, content_type: str, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def respond_json(self, payload: dict, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> int:
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8080"))
    server = ThreadingHTTPServer((host, port), Handler)
    print(f"Free My Mac Desktop web em http://{host}:{port}")
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
