#!/bin/bash
set -euo pipefail

TRACE_FILE="/tmp/step_423h_runner_trace.log"
RUNNER="/opt/pix2pi/orchestrator/bin/run_api_gateway.sh"
UNIT_FILE="/etc/systemd/system/pix2pi-api-gateway.service"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

mask_password() {
  sed -E 's/password=[^ ]+/password=***/g'
}

echo "=== STEP 423I / RUNNER TRACE DUMP ==="

echo
echo "1. dosya varlik kontrol..."
for f in "$TRACE_FILE" "$RUNNER" "$UNIT_FILE" "$COMMON_ENV"; do
  if [ -f "$f" ]; then
    echo "OK ✅ bulundu -> $f"
  else
    echo "HATA ❌ bulunamadi -> $f"
  fi
done

echo
echo "2. systemd unit ozet..."
grep -nE 'ExecStart|Environment|EnvironmentFile|WorkingDirectory|User|Group' "$UNIT_FILE" || true
echo "OK ✅ unit ozet bitti"

echo
echo "3. runner script tam icerik..."
nl -ba "$RUNNER" | sed -n '1,220p'
echo "OK ✅ runner script bitti"

echo
echo "4. common.env kritik alanlar..."
grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
echo "OK ✅ common.env ozet bitti"

echo
echo "5. runner trace tam icerik..."
if [ -f "$TRACE_FILE" ]; then
  cat "$TRACE_FILE" | mask_password
  echo
  echo "OK ✅ runner trace basildi"
else
  echo "HATA ❌ trace file yok"
fi

echo
echo "6. son 40 journal log..."
journalctl -u pix2pi-api-gateway.service -n 40 --no-pager || true
echo "OK ✅ journal log bitti"
