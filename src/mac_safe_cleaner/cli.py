from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


DEFAULT_MIN_SIZE_MB = 50
DEFAULT_OLDER_THAN_DAYS = 30

INSTALLER_SUFFIXES = {
    ".dmg",
    ".iso",
    ".pkg",
    ".mpkg",
    ".zip",
    ".tar",
    ".tgz",
    ".gz",
    ".xz",
    ".bz2",
}

NEVER_TOUCH_PREFIXES = [
    Path("/System"),
    Path("/bin"),
    Path("/sbin"),
    Path("/usr/bin"),
    Path("/usr/sbin"),
    Path("/Library/Apple"),
    Path("/Applications"),
]


@dataclass
class Candidate:
    id: str
    kind: str
    path: str
    size_bytes: int
    modified_at: str
    age_days: int
    reason: str
    risk: str = "baixo"


def scan_home() -> Path:
    configured = os.environ.get("FREE_MY_MAC_HOME") or os.environ.get("MAC_SAFE_CLEANER_HOME")
    return Path(configured or str(Path.home())).expanduser()


def quarantine_root() -> Path:
    default = Path.home() / "Documents" / "dev" / "free-my-mac-desktop" / "quarantine"
    configured = os.environ.get("FREE_MY_MAC_QUARANTINE") or os.environ.get("MAC_SAFE_CLEANER_QUARANTINE")
    return Path(configured or str(default)).expanduser()


def human_size(size: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.1f} {unit}"
        value /= 1024
    return f"{size} B"


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def iso_from_timestamp(timestamp: float) -> str:
    return datetime.fromtimestamp(timestamp, timezone.utc).isoformat()


def age_days(path: Path) -> int:
    modified = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
    return max(0, (now_utc() - modified).days)


def is_under(path: Path, prefix: Path) -> bool:
    try:
        path.resolve().relative_to(prefix.resolve())
        return True
    except ValueError:
        return False
    except OSError:
        return False


def is_protected(path: Path) -> bool:
    return any(is_under(path, prefix) for prefix in NEVER_TOUCH_PREFIXES)


def safe_walk(root: Path) -> Iterable[Path]:
    if not root.exists() or is_protected(root):
        return

    for current, dirs, files in os.walk(root, topdown=True, followlinks=False):
        current_path = Path(current)
        if is_protected(current_path):
            dirs[:] = []
            continue

        kept_dirs = []
        for dirname in dirs:
            child = current_path / dirname
            try:
                if child.is_symlink() or is_protected(child):
                    continue
                kept_dirs.append(dirname)
            except OSError:
                continue
        dirs[:] = kept_dirs

        for filename in files:
            path = current_path / filename
            try:
                if path.is_symlink() or not path.is_file():
                    continue
                yield path
            except OSError:
                continue


def directory_size(path: Path) -> int:
    total = 0
    for item in safe_walk(path):
        try:
            total += item.stat().st_size
        except OSError:
            continue
    return total


def add_candidate(
    candidates: list[Candidate],
    counters: dict[str, int],
    kind: str,
    path: Path,
    size_bytes: int,
    reason: str,
    risk: str = "baixo",
) -> None:
    counters[kind] = counters.get(kind, 0) + 1
    candidate_id = f"{kind}-{counters[kind]:04d}"
    try:
        modified_at = iso_from_timestamp(path.stat().st_mtime)
        days = age_days(path)
    except OSError:
        return

    candidates.append(
        Candidate(
            id=candidate_id,
            kind=kind,
            path=str(path),
            size_bytes=size_bytes,
            modified_at=modified_at,
            age_days=days,
            reason=reason,
            risk=risk,
        )
    )


def scan_files(
    root: Path,
    candidates: list[Candidate],
    counters: dict[str, int],
    kind: str,
    min_size: int,
    older_than_days: int,
    reason: str,
    suffixes: set[str] | None = None,
) -> None:
    for path in safe_walk(root):
        try:
            stat = path.stat()
        except OSError:
            continue

        if stat.st_size < min_size:
            continue
        if age_days(path) < older_than_days:
            continue
        if suffixes and path.suffix.lower() not in suffixes:
            continue

        add_candidate(candidates, counters, kind, path, stat.st_size, reason)


def scan_directories(
    root: Path,
    candidates: list[Candidate],
    counters: dict[str, int],
    kind: str,
    min_size: int,
    older_than_days: int,
    reason: str,
) -> None:
    if not root.exists():
        return

    for child in root.iterdir():
        try:
            if child.is_symlink() or not child.is_dir() or is_protected(child):
                continue
            if age_days(child) < older_than_days:
                continue
            size = directory_size(child)
            if size < min_size:
                continue
            add_candidate(candidates, counters, kind, child, size, reason)
        except OSError:
            continue


def build_scan_report(min_size_mb: int, older_than_days: int, include_system: bool) -> dict:
    min_size = min_size_mb * 1024 * 1024
    candidates: list[Candidate] = []
    counters: dict[str, int] = {}
    home = scan_home()

    scan_files(home / "Library" / "Logs", candidates, counters, "log", min_size, older_than_days, "Log antigo e grande em area de usuario.")
    scan_files(home / "Library" / "Caches", candidates, counters, "cache", min_size, older_than_days, "Arquivo antigo e grande em cache de usuario.")
    scan_files(home / ".cache", candidates, counters, "cache", min_size, older_than_days, "Arquivo antigo e grande em cache local.")
    scan_files(home / ".npm" / "_cacache", candidates, counters, "cache", min_size, older_than_days, "Arquivo antigo e grande no cache do npm.")
    scan_files(home / "Downloads", candidates, counters, "installer", min_size, older_than_days, "Instalador ou arquivo compactado antigo em Downloads.", INSTALLER_SUFFIXES)
    scan_directories(home / "Library" / "Developer" / "Xcode" / "DerivedData", candidates, counters, "devdata", min_size, older_than_days, "Dados derivados antigos do Xcode; podem ser recriados pelo Xcode.")
    scan_directories(home / "Library" / "Developer" / "Xcode" / "Archives", candidates, counters, "devarchive", min_size, older_than_days * 3, "Arquivo antigo de build/archive do Xcode. Revisar antes de mover.")

    if include_system:
        scan_files(Path("/Library/Logs"), candidates, counters, "log", min_size, older_than_days, "Log antigo e grande em /Library/Logs.")
        scan_files(Path("/Library/Caches"), candidates, counters, "cache", min_size, older_than_days, "Arquivo antigo e grande em /Library/Caches.")
        scan_files(Path("/private/var/log"), candidates, counters, "log", min_size, older_than_days, "Log antigo e grande em /private/var/log.")

    candidates.sort(key=lambda item: item.size_bytes, reverse=True)
    return {
        "generated_at": now_utc().isoformat(),
        "policy": {
            "scan_home": str(home),
            "min_size_mb": min_size_mb,
            "older_than_days": older_than_days,
            "include_system": include_system,
            "note": "Relatorio informativo. Nenhum arquivo foi removido.",
        },
        "total_size_bytes": sum(item.size_bytes for item in candidates),
        "candidates": [asdict(item) for item in candidates],
    }


def write_markdown_report(path: Path, report: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Relatorio de limpeza macOS",
        "",
        f"Gerado em: `{report['generated_at']}`",
        "",
        "Nenhum arquivo foi removido durante a varredura.",
        "",
        f"Espaco potencial: **{human_size(report['total_size_bytes'])}**",
        "",
        "| ID | Tipo | Tamanho | Idade | Risco | Motivo | Caminho |",
        "|---|---|---:|---:|---|---|---|",
    ]

    for item in report["candidates"]:
        path_text = item["path"].replace("|", "\\|")
        reason = item["reason"].replace("|", "\\|")
        lines.append(
            f"| `{item['id']}` | {item['kind']} | {human_size(item['size_bytes'])} | "
            f"{item['age_days']} dias | {item['risk']} | {reason} | `{path_text}` |"
        )

    if not report["candidates"]:
        lines.append("| - | - | - | - | - | Nenhum candidato encontrado | - |")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def load_report(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def selected_candidates(report: dict, ids: list[str] | None, all_items: bool) -> list[dict]:
    candidates = report.get("candidates", [])
    if all_items:
        return candidates
    wanted = set(ids or [])
    return [item for item in candidates if item["id"] in wanted]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_payload_path(session_dir: Path, original: Path) -> Path:
    parts = [part for part in original.parts if part not in ("/", "")]
    destination = session_dir / "payload" / Path(*parts)
    if not destination.exists():
        return destination

    suffix = 1
    while True:
        candidate = destination.with_name(f"{destination.name}.duplicate-{suffix}")
        if not candidate.exists():
            return candidate
        suffix += 1


def quarantine_candidates(report: dict, ids: list[str] | None = None, all_items: bool = False) -> dict:
    chosen = selected_candidates(report, ids, all_items)
    if not chosen:
        return {"moved": 0, "session": None, "manifest": None, "errors": ["Nenhum candidato selecionado."]}

    session = datetime.now().strftime("%Y%m%d-%H%M%S")
    session_dir = quarantine_root() / session
    session_dir.mkdir(parents=True, exist_ok=False)
    manifest_path = session_dir / "manifest.jsonl"
    moved = 0
    errors: list[str] = []

    with manifest_path.open("w", encoding="utf-8") as manifest:
        for item in chosen:
            original = Path(item["path"])
            if is_protected(original) or original.is_symlink() or not original.exists():
                errors.append(f"Ignorado: {original}")
                continue

            destination = safe_payload_path(session_dir, original)
            destination.parent.mkdir(parents=True, exist_ok=True)
            file_hash = None
            if original.is_file():
                try:
                    file_hash = sha256_file(original)
                except OSError:
                    file_hash = None

            try:
                shutil.move(str(original), str(destination))
            except OSError as exc:
                errors.append(f"Falha ao mover {original}: {exc}")
                continue

            record = {
                "id": item["id"],
                "kind": item["kind"],
                "original_path": str(original),
                "quarantine_path": str(destination),
                "size_bytes": item["size_bytes"],
                "reason": item["reason"],
                "sha256": file_hash,
                "moved_at": now_utc().isoformat(),
            }
            manifest.write(json.dumps(record, ensure_ascii=False) + "\n")
            moved += 1

    return {"moved": moved, "session": session, "manifest": str(manifest_path), "errors": errors}


def read_manifest(session: str) -> list[dict]:
    manifest = quarantine_root() / session / "manifest.jsonl"
    records = []
    with manifest.open("r", encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                records.append(json.loads(line))
    return records


def restore_records(session: str, ids: list[str] | None = None, all_items: bool = False) -> dict:
    records = read_manifest(session)
    wanted = {record["id"] for record in records} if all_items else set(ids or [])
    restored = 0
    errors: list[str] = []

    for record in records:
        if record["id"] not in wanted:
            continue

        source = Path(record["quarantine_path"])
        destination = Path(record["original_path"])
        if not source.exists():
            errors.append(f"Origem nao existe: {source}")
            continue
        if destination.exists():
            errors.append(f"Destino ja existe, pulando: {destination}")
            continue

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))
        restored += 1

    return {"restored": restored, "errors": errors}


def list_quarantine_sessions(older_than_days: int | None = None) -> list[dict]:
    root = quarantine_root()
    if not root.exists():
        return []

    sessions = []
    for child in root.iterdir():
        try:
            if not child.is_dir():
                continue
            days = age_days(child)
            if older_than_days is not None and days < older_than_days:
                continue
            records = []
            if (child / "manifest.jsonl").exists():
                records = read_manifest(child.name)
            sessions.append(
                {
                    "session": child.name,
                    "path": str(child),
                    "age_days": days,
                    "size_bytes": directory_size(child),
                    "item_count": len(records),
                    "items": records,
                }
            )
        except OSError:
            continue

    return sorted(sessions, key=lambda item: item["session"], reverse=True)


def purge_sessions(older_than_days: int, execute: bool) -> list[dict]:
    sessions = list_quarantine_sessions(older_than_days)
    for session in sessions:
        if execute:
            shutil.rmtree(Path(session["path"]))
    return sessions


def scan(args: argparse.Namespace) -> int:
    report = build_scan_report(args.min_size_mb, args.older_than_days, args.include_system)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    if args.markdown:
        write_markdown_report(Path(args.markdown), report)

    print(f"Encontrados {len(report['candidates'])} candidatos.")
    print(f"Espaco potencial: {human_size(report['total_size_bytes'])}.")
    print(f"Relatorio JSON: {output}")
    if args.markdown:
        print(f"Relatorio Markdown: {args.markdown}")
    return 0


def quarantine(args: argparse.Namespace) -> int:
    report = load_report(Path(args.report))
    result = quarantine_candidates(report, args.ids, args.all)
    if result["moved"] == 0:
        print("Nenhum candidato movido.")
        for error in result["errors"]:
            print(error, file=sys.stderr)
        return 1

    print(f"Movidos para quarentena: {result['moved']}")
    print(f"Sessao: {result['session']}")
    print(f"Manifesto: {result['manifest']}")
    for error in result["errors"]:
        print(error, file=sys.stderr)
    return 0


def restore(args: argparse.Namespace) -> int:
    result = restore_records(args.session, args.ids, args.all)
    print(f"Restaurados: {result['restored']}")
    for error in result["errors"]:
        print(error, file=sys.stderr)
    return 0


def purge(args: argparse.Namespace) -> int:
    if not quarantine_root().exists():
        print("Nenhuma quarentena encontrada.")
        return 0

    sessions = purge_sessions(args.older_than_days, args.execute)
    if not sessions:
        print("Nenhuma sessao antiga o suficiente para purga.")
        return 0

    for session in sessions:
        action = "apagaria" if not args.execute else "apagando"
        print(
            f"{action}: {session['path']} "
            f"({session['age_days']} dias, {human_size(session['size_bytes'])})"
        )

    if not args.execute:
        print("Simulacao apenas. Use --execute para apagar permanentemente.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="free-my-mac",
        description="Varredura conservadora do macOS com quarentena reversivel.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    scan_parser = subparsers.add_parser("scan", help="Gera relatorio de candidatos.")
    scan_parser.add_argument("--output", default="reports/scan.json")
    scan_parser.add_argument("--markdown", default="reports/scan.md")
    scan_parser.add_argument("--min-size-mb", type=int, default=DEFAULT_MIN_SIZE_MB)
    scan_parser.add_argument("--older-than-days", type=int, default=DEFAULT_OLDER_THAN_DAYS)
    scan_parser.add_argument("--include-system", action="store_true")
    scan_parser.set_defaults(func=scan)

    quarantine_parser = subparsers.add_parser("quarantine", help="Move itens aprovados para quarentena.")
    quarantine_parser.add_argument("--report", required=True)
    quarantine_group = quarantine_parser.add_mutually_exclusive_group(required=True)
    quarantine_group.add_argument("--ids", nargs="+")
    quarantine_group.add_argument("--all", action="store_true")
    quarantine_parser.set_defaults(func=quarantine)

    restore_parser = subparsers.add_parser("restore", help="Restaura itens da quarentena.")
    restore_parser.add_argument("--session", required=True)
    restore_group = restore_parser.add_mutually_exclusive_group(required=True)
    restore_group.add_argument("--ids", nargs="+")
    restore_group.add_argument("--all", action="store_true")
    restore_parser.set_defaults(func=restore)

    purge_parser = subparsers.add_parser("purge", help="Apaga quarentenas antigas.")
    purge_parser.add_argument("--older-than-days", type=int, default=30)
    purge_parser.add_argument("--execute", action="store_true")
    purge_parser.set_defaults(func=purge)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)

