#!/bin/bash
set -euo pipefail

TRACE_FILE="/tmp/step_423h_runner_trace.log"
RUNNER="/opt/pix2pi/orchestrator/bin/run_api_gateway.sh"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
OUT_FILE="$HOME/pix2pi/pix2pi-SaaS/step_423j_trace_dump.txt"

mask_password() {
  sed -E 's/password=[^ ]+/password=***/g'
}

echo "=== STEP 423J / TRACE ONLY DUMP ==="

echo
echo "1. dosya kontrol..."
for f in "$TRACE_FILE" "$RUNNER" "$COMMON_ENV"; do
  if [ -f "$f" ]; then
    echo "OK ✅ bulundu -> $f"
  else
    echo "HATA ❌ bulunamadi -> $f"
    exit 1
  fi
done

echo
echo "2. dump dosyasi olusturuluyor..."
{
  echo "===== RUNNER HEAD ====="
  nl -ba "$RUNNER" | sed -n '1,220p'
  echo

  echo "===== COMMON.ENV KRITIK ====="
  grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
  echo

  echo "===== TRACE LINE COUNT ====="
  wc -l "$TRACE_FILE"
  echo

  echo "===== TRACE FULL ====="
  nl -ba "$TRACE_FILE" | mask_password
  echo
} > "$OUT_FILE"

echo "OK ✅ dump olustu -> $OUT_FILE"

echo
echo "3. ekrana basiliyor..."
cat "$OUT_FILE"
echo
echo "OK ✅ STEP 423J tamam"
