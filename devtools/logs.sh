#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

svc="${1:-}"
if [[ -z "$svc" ]]; then
  echo "Kullanım: ./scripts/logs.sh identity-api|finance-api|gateway|migrate"
  echo
  ls -la logs || true
  exit 0
fi

file="logs/${svc}.log"
if [[ "$svc" == "migrate" ]]; then
  file="logs/migrate.log"
fi

if [[ ! -f "$file" ]]; then
  echo "❌ log yok: $file"
  exit 1
fi

tail -n 200 -f "$file"
