#!/bin/bash
set -euo pipefail

echo "=== STEP 423F / PORT 9010 PROBE ==="

echo
echo "1. systemd service durumu..."
systemctl --no-pager --full status pix2pi-api-gateway.service | head -n 25 || true
echo "OK ✅ systemd durum bakildi"

echo
echo "2. 9010 portunu kim tutuyor..."
ss -lntp | grep ':9010' || echo "9010 dinleyen proses yok"
echo "OK ✅ port kontrol bitti"

echo
echo "3. PID + komut bilgisi..."
PIDS="$(ss -lntp | awk '/:9010/ {for(i=1;i<=NF;i++) if($i ~ /pid=/){gsub(/.*pid=/,"",$i); gsub(/,.*/,"",$i); print $i}}' | sort -u)"
if [ -n "${PIDS:-}" ]; then
  for pid in $PIDS; do
    echo "--- PID: $pid ---"
    ps -fp "$pid" || true
    echo "--- EXE ---"
    readlink -f "/proc/$pid/exe" || true
    echo "--- CWD ---"
    readlink -f "/proc/$pid/cwd" || true
    echo
  done
else
  echo "PID bulunamadi"
fi
echo "OK ✅ PID analiz bitti"

echo
echo "4. health testi..."
set +e
curl -sS -i http://127.0.0.1:9010/health >/tmp/step_423f_health.out 2>/tmp/step_423f_health.err
HEALTH_RC=$?
set -e
echo "HEALTH_RC=$HEALTH_RC"
echo "--- /health response ---"
cat /tmp/step_423f_health.out 2>/dev/null || true
echo
echo "--- /health stderr ---"
cat /tmp/step_423f_health.err 2>/dev/null || true
echo
echo "OK ✅ health testi bitti"

echo
echo "5. query route testi..."
set +e
curl -sS -i http://127.0.0.1:9010/api/query/users >/tmp/step_423f_query.out 2>/tmp/step_423f_query.err
QUERY_RC=$?
set -e
echo "QUERY_RC=$QUERY_RC"
echo "--- /api/query/users response ---"
cat /tmp/step_423f_query.out 2>/dev/null || true
echo
echo "--- /api/query/users stderr ---"
cat /tmp/step_423f_query.err 2>/dev/null || true
echo
echo "OK ✅ query route testi bitti"

echo
echo "6. son 50 gateway journal log..."
journalctl -u pix2pi-api-gateway.service -n 50 --no-pager || true
echo "OK ✅ journal kontrol bitti"

echo
echo "7. kisa ozet..."
if ss -lntp | grep -q ':9010'; then
  echo "PORT_9010=DINLENIYOR"
else
  echo "PORT_9010=BOS"
fi

if grep -q '200 OK' /tmp/step_423f_health.out 2>/dev/null; then
  echo "HEALTH=OK"
else
  echo "HEALTH=FAIL"
fi

if grep -q 'HTTP/' /tmp/step_423f_query.out 2>/dev/null; then
  echo "QUERY_ROUTE=RESPONDED"
else
  echo "QUERY_ROUTE=NO_RESPONSE"
fi

echo "OK ✅ STEP 423F tamam"
