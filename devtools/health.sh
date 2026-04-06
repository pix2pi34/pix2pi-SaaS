#!/bin/bash
set -euo pipefail

check() {
  local name="$1"
  local url="$2"
  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)"
  if [[ "$code" == "200" ]]; then
    echo "✅ $name OK ($url)"
  else
    echo "❌ $name FAIL http=$code ($url)"
  fi
}

check "Identity" "http://127.0.0.1:9001/health"
check "Finance"  "http://127.0.0.1:9002/health"
check "Gateway"  "http://127.0.0.1:9003/health"
