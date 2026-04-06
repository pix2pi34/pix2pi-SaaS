#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .pids

stop_pidfile() {
  local svc="$1"
  local pidfile=".pids/${svc}.pid"
  if [[ -f "$pidfile" ]]; then
    pid="$(cat "$pidfile" || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "🛑 [$svc] killing PID=$pid"
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
    else
      echo "ℹ️  [$svc] pidfile var ama process yok (PID=$pid)"
    fi
    rm -f "$pidfile"
  else
    echo "ℹ️  [$svc] pidfile yok"
  fi
}

# Port bazlı temizlik (güvenli)
fuser -k 9001/tcp 2>/dev/null || true
fuser -k 9002/tcp 2>/dev/null || true
fuser -k 9003/tcp 2>/dev/null || true

stop_pidfile "identity-api"
stop_pidfile "finance-api"
stop_pidfile "gateway"

echo "✅ stopped."
