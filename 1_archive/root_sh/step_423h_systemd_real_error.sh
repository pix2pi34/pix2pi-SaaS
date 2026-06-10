#!/bin/bash
set -euo pipefail

SERVICE="pix2pi-api-gateway.service"
UNIT_FILE="/etc/systemd/system/pix2pi-api-gateway.service"
RUNNER="/opt/pix2pi/orchestrator/bin/run_api_gateway.sh"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
BACKUP_DIR="$HOME/pix2pi/pix2pi-SaaS/_backup/step_423h"
TRACE_OUT="/tmp/step_423h_runner_trace.log"

mask_password() {
  sed -E 's/password=[^ ]+/password=***/g'
}

get_pids() {
  ss -lntp 2>/dev/null | awk '/:9010/ {
    while (match($0, /pid=[0-9]+/)) {
      pid = substr($0, RSTART+4, RLENGTH-4)
      print pid
      $0 = substr($0, RSTART+RLENGTH)
    }
  }' | sort -u
}

mkdir -p "$BACKUP_DIR"

echo "=== STEP 423H / SYSTEMD GERCEK HATA YAKALAMA ==="

echo
echo "1. backup aliniyor..."
for f in "$UNIT_FILE" "$RUNNER" "$COMMON_ENV"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").$(date +%F_%H%M%S).bak"
  fi
done
echo "OK ✅ backup alindi"

echo
echo "2. systemd unit inceleme..."
echo "--- systemctl cat $SERVICE ---"
systemctl cat "$SERVICE" || true
echo
echo "--- grep kritik satirlar ---"
grep -nE 'ExecStart|Environment|EnvironmentFile|WorkingDirectory|User|Group' "$UNIT_FILE" || true
echo "OK ✅ unit inceleme bitti"

echo
echo "3. runner script inceleme..."
if [ ! -f "$RUNNER" ]; then
  echo "HATA ❌ runner bulunamadi: $RUNNER"
  exit 1
fi
nl -ba "$RUNNER" | sed -n '1,220p'
echo "OK ✅ runner script gosterildi"

echo
echo "4. common.env kritik alanlar..."
if [ ! -f "$COMMON_ENV" ]; then
  echo "HATA ❌ common.env bulunamadi: $COMMON_ENV"
  exit 1
fi
grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
echo "OK ✅ common.env kontrol bitti"

echo
echo "5. service stop + port temizligi..."
systemctl stop "$SERVICE" || true
sleep 2

PIDS="$(get_pids || true)"
if [ -n "${PIDS:-}" ]; then
  echo "9010 portunu tutan processler kapatiliyor..."
  for pid in $PIDS; do
    kill "$pid" || true
  done
  sleep 2
fi

PIDS2="$(get_pids || true)"
if [ -n "${PIDS2:-}" ]; then
  echo "kalan processlere SIGKILL gonderiliyor..."
  for pid in $PIDS2; do
    kill -9 "$pid" || true
  done
  sleep 1
fi

if ss -lntp | grep -q ':9010'; then
  echo "HATA ❌ 9010 hala dolu"
  ss -lntp | grep ':9010' || true
  exit 1
fi
echo "OK ✅ 9010 portu bos"

echo
echo "6. runner dogrudan bash -x ile calistiriliyor..."
echo "NOT: 15 saniye timeout var. Hemen duserse gerçek hata görünecek."
set +e
timeout 15s bash -x "$RUNNER" > "$TRACE_OUT" 2>&1
RC=$?
set -e

echo "RUNNER_RC=$RC"
echo "--- runner trace ---"
cat "$TRACE_OUT" | mask_password || true
echo
if [ "$RC" -eq 124 ]; then
  echo "OK ✅ runner 15 saniye boyunca ayakta kaldi (timeout)"
else
  echo "OK ✅ runner trace alindi"
fi

echo
echo "7. journal log..."
journalctl -u "$SERVICE" -n 80 --no-pager || true
echo "OK ✅ journal log alindi"

echo
echo "8. kisa ozet..."
echo "UNIT_FILE=$UNIT_FILE"
echo "RUNNER=$RUNNER"
echo "TRACE_FILE=$TRACE_OUT"
echo "RUNNER_RC=$RC"
echo "OK ✅ STEP 423H tamam"
