#!/usr/bin/env bash
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Docker.app/Contents/Resources/bin:$HOME/.docker/bin:$PATH"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$APP_DIR/logs"
LOG_FILE="$LOG_DIR/launcher.log"
URL="http://127.0.0.1:8080"

mkdir -p "$LOG_DIR"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"Free My Mac Desktop\"" >/dev/null 2>&1 || true
}

cd "$APP_DIR" || exit 1

log "Starting Free My Mac Desktop launcher."
log "PATH=$PATH"

DOCKER_BIN="$(command -v docker || true)"

if [[ -z "$DOCKER_BIN" ]]; then
  log "Docker command not found."
  /usr/bin/osascript -e 'display alert "Docker não encontrado" message "Instale ou abra o Docker Desktop antes de executar o Free My Mac Desktop." as critical' >/dev/null 2>&1 || true
  exit 1
fi

log "Docker command: $DOCKER_BIN"

if ! "$DOCKER_BIN" info >/dev/null 2>&1; then
  log "Docker daemon is not available. Trying to open Docker Desktop."
  open -a Docker >/dev/null 2>&1 || true
  notify "Abrindo Docker Desktop..."

  for _ in $(seq 1 60); do
    if "$DOCKER_BIN" info >/dev/null 2>&1; then
      log "Docker daemon became available."
      break
    fi
    sleep 2
  done
fi

if ! "$DOCKER_BIN" info >/dev/null 2>&1; then
  log "Docker daemon still unavailable."
  /usr/bin/osascript -e 'display alert "Docker não iniciou" message "Abra o Docker Desktop e tente novamente." as warning' >/dev/null 2>&1 || true
  exit 1
fi

log "Launching docker compose."
"$DOCKER_BIN" compose up --build >>"$LOG_FILE" 2>&1 &
COMPOSE_PID=$!
log "docker compose PID: $COMPOSE_PID"
notify "Iniciando container..."

for _ in $(seq 1 90); do
  if /usr/bin/curl -fsS "$URL/api/scan-status" >/dev/null 2>&1; then
    log "Web UI is ready at $URL."
    open "$URL" >/dev/null 2>&1 || true
    notify "Interface aberta no navegador."
    wait "$COMPOSE_PID"
    exit $?
  fi
  if ! kill -0 "$COMPOSE_PID" >/dev/null 2>&1; then
    log "docker compose stopped before web UI became ready."
    /usr/bin/osascript -e 'display alert "Container parou" message "O container parou antes da interface ficar disponível. Veja logs/launcher.log." as warning' >/dev/null 2>&1 || true
    exit 1
  fi
  sleep 1
done

log "Timed out waiting for web UI."
/usr/bin/osascript -e 'display alert "Interface não respondeu" message "O container iniciou, mas a interface não respondeu em 90 segundos. Veja logs/launcher.log." as warning' >/dev/null 2>&1 || true
wait "$COMPOSE_PID"
