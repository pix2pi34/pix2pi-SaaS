#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/pix2pi/pix2pi-SaaS}"
SMOKE_SCRIPT="$ROOT/scripts/query_smoke_prod.sh"
RESTART_SCRIPT="$ROOT/scripts/query_post_restart_check.sh"
RUN_RESTART_CHECK="${RUN_RESTART_CHECK:-1}"

echo "===== STEP 54A / QUERY OPS SUITE ====="

echo
echo "===== 1) DOSYA KONTROL ====="
[ -f "$SMOKE_SCRIPT" ] || { echo "HATA ❌ eksik: $SMOKE_SCRIPT"; exit 1; }
[ -f "$RESTART_SCRIPT" ] || { echo "HATA ❌ eksik: $RESTART_SCRIPT"; exit 1; }
echo "OK ✅ query_smoke_prod.sh var"
echo "OK ✅ query_post_restart_check.sh var"

echo
echo "===== 2) FAST SMOKE ====="
bash "$SMOKE_SCRIPT"
echo "OK ✅ fast smoke gecti"

echo
echo "===== 3) POST RESTART CHECK ====="
if [ "$RUN_RESTART_CHECK" = "1" ]; then
  bash "$RESTART_SCRIPT"
  echo "OK ✅ post restart check gecti"
else
  echo "INFO ▶ restart check skip edildi (RUN_RESTART_CHECK=$RUN_RESTART_CHECK)"
fi

echo
echo "OK ✅ step_54a query ops suite gecti"
