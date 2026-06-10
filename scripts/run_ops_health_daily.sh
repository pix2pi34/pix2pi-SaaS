#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/pix2pi/ops_health_cron.log}"
REPORT_FILE="${REPORT_FILE:-/root/pix2pi/pix2pi-SaaS/reports/ops_health_latest.txt}"
REPORT_SCRIPT="${REPORT_SCRIPT:-/root/pix2pi/pix2pi-SaaS/scripts/ops_health_report.sh}"
WATCHDOG_SCRIPT="${WATCHDOG_SCRIPT:-/root/pix2pi/pix2pi-SaaS/scripts/check_ops_health_watchdog.sh}"
ALERT_SCRIPT="${ALERT_SCRIPT:-/root/pix2pi/pix2pi-SaaS/scripts/ops_health_alert.sh}"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$REPORT_FILE")"

run_alert() {
  local reason="$1"

  ALERT_REASON="$reason" \
  ALERT_STATUS="critical" \
  ALERT_REPORT_FILE="$REPORT_FILE" \
  ALERT_CRON_LOG="$LOG_FILE" \
  "$ALERT_SCRIPT" >> "$LOG_FILE" 2>&1 || true
}

START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== pix2pi ops health daily start ${START_TS} =====" >> "$LOG_FILE"

set +e
"$REPORT_SCRIPT" >> "$LOG_FILE" 2>&1
REPORT_RC=$?
set -e

END_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== pix2pi ops health daily end ${END_TS} =====" >> "$LOG_FILE"
echo >> "$LOG_FILE"

if [ "$REPORT_RC" -ne 0 ]; then
  echo "ERROR ❌ ops health report fail rc=${REPORT_RC}" >> "$LOG_FILE"
  run_alert "ops health report fail rc=${REPORT_RC}"
  exit "$REPORT_RC"
fi

set +e
REPORT_FILE="$REPORT_FILE" \
CRON_LOG="$LOG_FILE" \
"$WATCHDOG_SCRIPT" >> "$LOG_FILE" 2>&1
WATCHDOG_RC=$?
set -e

if [ "$WATCHDOG_RC" -ne 0 ]; then
  echo "ERROR ❌ ops health watchdog fail rc=${WATCHDOG_RC}" >> "$LOG_FILE"
  run_alert "ops health watchdog fail rc=${WATCHDOG_RC}"
  exit "$WATCHDOG_RC"
fi

echo "OK ✅ ops health daily pipeline tamam" >> "$LOG_FILE"
echo >> "$LOG_FILE"
