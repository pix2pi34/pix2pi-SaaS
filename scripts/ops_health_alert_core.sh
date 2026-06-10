#!/usr/bin/env bash
set -euo pipefail

ALERT_LOG="${ALERT_LOG:-/var/log/pix2pi/ops_health_alert.log}"
ALERT_FILE="${ALERT_FILE:-/root/pix2pi/pix2pi-SaaS/reports/ops_alert_latest.txt}"
ALERT_REASON="${ALERT_REASON:-ops health watchdog fail}"
ALERT_STATUS="${ALERT_STATUS:-critical}"
ALERT_REPORT_FILE="${ALERT_REPORT_FILE:-unknown}"
ALERT_CRON_LOG="${ALERT_CRON_LOG:-unknown}"

mkdir -p "$(dirname "$ALERT_LOG")"
mkdir -p "$(dirname "$ALERT_FILE")"

TS="$(date '+%Y-%m-%d %H:%M:%S')"

echo "$TS ALERT status=$ALERT_STATUS reason=\"$ALERT_REASON\" report=\"$ALERT_REPORT_FILE\" cron=\"$ALERT_CRON_LOG\"" >> "$ALERT_LOG"

cat <<EOT > "$ALERT_FILE"
===== OPS HEALTH ALERT =====
time=$TS
status=$ALERT_STATUS
reason=$ALERT_REASON
report_file=$ALERT_REPORT_FILE
cron_log=$ALERT_CRON_LOG
EOT

echo "OK ✅ ops health alert log yazildi -> $ALERT_LOG"
echo "OK ✅ ops health alert latest yazildi -> $ALERT_FILE"
