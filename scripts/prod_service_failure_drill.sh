#!/usr/bin/env bash
set -euo pipefail

TARGET_SERVICE="pix2pi-user-created-consumer.service"
WATCH_SCRIPT="/root/pix2pi/pix2pi-SaaS/scripts/check_ops_service_failures.sh"
ALERT_LOG="/var/log/pix2pi/ops_health_alert.log"

find_alert_latest_file() {
  local f
  for f in \
    /root/pix2pi/pix2pi-SaaS/reports/ops_health_alert_latest.txt \
    /root/pix2pi/pix2pi-SaaS/reports/ops_alert_latest.txt
  do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  return 1
}

cleanup() {
  local active_now=""
  active_now="$(systemctl is-active "$TARGET_SERVICE" 2>/dev/null || true)"
  if [ "$active_now" != "active" ]; then
    systemctl restart "$TARGET_SERVICE" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "===== STEP 57L / REAL SERVICE FAILURE DRILL ====="

echo
echo "==== 1) PRECHECK ===="
systemctl is-active "$TARGET_SERVICE"
echo "OK ✅ target servis aktif"

echo
echo "==== 2) STOP TARGET SERVICE ===="
systemctl stop "$TARGET_SERVICE"
sleep 2
ACTIVE_NOW="$(systemctl is-active "$TARGET_SERVICE" || true)"
FAILED_NOW="$(systemctl is-failed "$TARGET_SERVICE" || true)"
echo "OK ✅ target servis durduruldu | active=$ACTIVE_NOW failed=$FAILED_NOW"

echo
echo "==== 3) WATCHDOG CHECK (FAIL BEKLENIYOR) ===="
set +e
"$WATCH_SCRIPT"
RC=$?
set -e

if [ "$RC" -eq 0 ]; then
  echo "ERROR ❌ watchdog fail vermeliydi ama rc=0 dondu"
  exit 1
fi
echo "OK ✅ watchdog non-zero rc verdi -> rc=$RC"

echo
echo "==== 4) ALERT DOGRULAMA ===="
ALERT_FILE=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
  ALERT_FILE="$(find_alert_latest_file || true)"
  if [ -n "$ALERT_FILE" ] \
    && [ -f "$ALERT_LOG" ] \
    && grep -Fq "service unhealthy: $TARGET_SERVICE" "$ALERT_LOG" \
    && grep -Fq "service unhealthy: $TARGET_SERVICE" "$ALERT_FILE"
  then
    break
  fi
  sleep 1
done

if [ -z "$ALERT_FILE" ]; then
  echo "ERROR ❌ latest alert dosyasi bulunamadi"
  exit 1
fi

grep -Fq "service unhealthy: $TARGET_SERVICE" "$ALERT_LOG"
grep -Fq "service unhealthy: $TARGET_SERVICE" "$ALERT_FILE"
echo "OK ✅ alert log dogrulandi"
echo "OK ✅ latest alert dogrulandi -> $ALERT_FILE"

echo
echo "==== 5) TARGET SERVICE RECOVERY ===="
systemctl restart "$TARGET_SERVICE"
sleep 3
systemctl is-active "$TARGET_SERVICE" | grep -Fxq active
echo "OK ✅ target servis restart edildi ve active"

echo
echo "==== 6) CLEAN RECOVERY CHECK ===="
"$WATCH_SCRIPT"
echo "OK ✅ recovery scan temiz"

echo
echo "OK ✅ step_57l_real_service_failure_drill gecti"
