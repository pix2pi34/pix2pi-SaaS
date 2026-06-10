#!/bin/bash
set -euo pipefail

echo "=== STEP 423G / 9010 CONFLICT TEMIZLE + SYSTEMD SABITLE ==="

PORT=9010
SERVICE="pix2pi-api-gateway.service"

get_pids() {
  ss -lntp 2>/dev/null | awk -v p=":$PORT" '
    $0 ~ p {
      while (match($0, /pid=[0-9]+/)) {
        pid = substr($0, RSTART+4, RLENGTH-4)
        print pid
        $0 = substr($0, RSTART+RLENGTH)
      }
    }
  ' | sort -u
}

echo
echo "1. mevcut service durumu..."
systemctl --no-pager --full status "$SERVICE" | head -n 20 || true
echo "OK ✅ mevcut durum alindi"

echo
echo "2. 9010 dinleyen PID bilgileri..."
PIDS_BEFORE="$(get_pids || true)"
if [ -n "${PIDS_BEFORE:-}" ]; then
  for pid in $PIDS_BEFORE; do
    echo "--- PID: $pid ---"
    ps -fp "$pid" || true
    echo "--- EXE ---"
    readlink -f "/proc/$pid/exe" || true
    echo "--- CWD ---"
    readlink -f "/proc/$pid/cwd" || true
    echo
  done
else
  echo "9010 dinleyen proses yok"
fi
echo "OK ✅ PID bilgileri alindi"

echo
echo "3. service stop..."
systemctl stop "$SERVICE" || true
sleep 2
echo "OK ✅ service stop denendi"

echo
echo "4. elde kalmis 9010 prosesleri temizleniyor..."
PIDS_AFTER_STOP="$(get_pids || true)"
if [ -n "${PIDS_AFTER_STOP:-}" ]; then
  echo "SIGTERM gönderiliyor..."
  for pid in $PIDS_AFTER_STOP; do
    kill "$pid" || true
  done
  sleep 2
fi

PIDS_AFTER_TERM="$(get_pids || true)"
if [ -n "${PIDS_AFTER_TERM:-}" ]; then
  echo "SIGKILL gönderiliyor..."
  for pid in $PIDS_AFTER_TERM; do
    kill -9 "$pid" || true
  done
  sleep 1
fi

if ss -lntp | grep -q ":$PORT"; then
  echo "HATA ❌ 9010 portu hala dolu"
  ss -lntp | grep ":$PORT" || true
  exit 1
fi
echo "OK ✅ 9010 portu bos"

echo
echo "5. systemd failed state reset..."
systemctl reset-failed "$SERVICE" || true
echo "OK ✅ reset-failed tamam"

echo
echo "6. service start..."
systemctl start "$SERVICE"
sleep 3
echo "OK ✅ service start tamam"

echo
echo "7. service status test..."
systemctl --no-pager --full status "$SERVICE" | head -n 25 || true
echo "OK ✅ status testi bitti"

echo
echo "8. health test..."
curl -fsS http://127.0.0.1:$PORT/health >/tmp/step_423g_health.out 2>/tmp/step_423g_health.err
cat /tmp/step_423g_health.out
echo
echo "OK ✅ health testi basarili"

echo
echo "9. query route test..."
set +e
curl -sS -i http://127.0.0.1:$PORT/api/query/users >/tmp/step_423g_query.out 2>/tmp/step_423g_query.err
QUERY_RC=$?
set -e

echo "--- /api/query/users response ---"
cat /tmp/step_423g_query.out 2>/dev/null || true
echo
echo "--- /api/query/users stderr ---"
cat /tmp/step_423g_query.err 2>/dev/null || true
echo
echo "OK ✅ query route testi bitti (RC=$QUERY_RC)"

echo
echo "10. son 40 journal log..."
journalctl -u "$SERVICE" -n 40 --no-pager || true
echo "OK ✅ journal log alindi"

echo
echo "11. final ozet..."
if systemctl is-active --quiet "$SERVICE"; then
  echo "SERVICE=ACTIVE"
else
  echo "SERVICE=INACTIVE"
fi

if ss -lntp | grep -q ":$PORT"; then
  echo "PORT_9010=DINLENIYOR"
else
  echo "PORT_9010=BOS"
fi

if grep -q '200 OK' /tmp/step_423g_query.out 2>/dev/null; then
  echo "QUERY_ROUTE=200_OK"
else
  echo "QUERY_ROUTE=NON_200_OR_EMPTY"
fi

echo "OK ✅ STEP 423G tamam"
