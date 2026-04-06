#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p logs .pids

find_main() {
  local svc="$1"
  find "cmd/$svc" -maxdepth 1 -type f -name "*main*.go" -print -quit 2>/dev/null || true
}

kill_port() {
  local port="$1"
  fuser -k "${port}/tcp" 2>/dev/null || true
}

start_service() {
  local svc="$1"
  local port="$2"

  local main
  main="$(find_main "$svc")"

  if [[ -z "$main" ]]; then
    echo "⚠️  [$svc] cmd/$svc altında *main*.go yok → SKIP"
    return 0
  fi

  echo "🧹 [$svc] port temizleniyor :$port"
  kill_port "$port"
  sleep 1

  echo "🚀 [$svc] başlatılıyor :$port ($main)"
  nohup bash -lc "cd '$ROOT_DIR' && PORT=$port go run ./$main" \
    > "logs/${svc}.log" 2>&1 &

  echo $! > ".pids/${svc}.pid"
  echo "✅ [$svc] PID=$(cat .pids/${svc}.pid)"
}

echo "🧱 Migrations..."
mig="$(find_main migrate)"
if [[ -n "${mig:-}" ]]; then
  go run "./$mig" | tee "logs/migrate.log"
else
  echo "⚠️  [migrate] cmd/migrate altında *main*.go yok → SKIP"
fi

echo
echo "🟦 Services (Ports):"
echo "9001 → Identity API"
echo "9002 → Finance API"
echo "9003 → Gateway"

start_service "identity-api" 9001
start_service "finance-api"  9002
start_service "gateway"      9003

echo
echo "📡 Listening Ports:"
ss -lntp | grep -E ':(9001|9002|9003)\b' || true

echo
echo "✅ core finished."
