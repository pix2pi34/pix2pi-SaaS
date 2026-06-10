#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REPORT_DIR="/root/pix2pi/pix2pi-SaaS/reports"
DEFAULT_LOG_DIR="/var/log/pix2pi"

ALERT_STATUS="${ALERT_STATUS:-critical}"
ALERT_REASON="${ALERT_REASON:-ops health alert}"

ALERT_REPORT_FILE="${ALERT_REPORT_FILE:-${REPORT_FILE:-$DEFAULT_REPORT_DIR/ops_health_latest.txt}}"
ALERT_CRON_LOG="${ALERT_CRON_LOG:-${CRON_LOG:-$DEFAULT_LOG_DIR/ops_health_cron.log}}"

ALERT_LATEST_FILE="${ALERT_LATEST_FILE:-${LATEST_ALERT_FILE:-$DEFAULT_REPORT_DIR/ops_alert_latest.txt}}"
ALERT_LOG="${ALERT_LOG:-${ALERT_LOG_FILE:-$DEFAULT_LOG_DIR/ops_health_alert.log}}"

NOTIFY_SCRIPT="${NOTIFY_SCRIPT:-/root/pix2pi/pix2pi-SaaS/scripts/ops_notify_webhook.sh}"

mkdir -p "$(dirname "$ALERT_LATEST_FILE")"
mkdir -p "$(dirname "$ALERT_LOG")"

TS="$(date '+%Y-%m-%d %H:%M:%S %z')"
HOSTNAME_VAL="$(hostname)"

LINE="ALERT status=${ALERT_STATUS} reason=\"${ALERT_REASON}\" host=${HOSTNAME_VAL} time=\"${TS}\" report=\"${ALERT_REPORT_FILE}\" cron=\"${ALERT_CRON_LOG}\""

echo "${TS} ${LINE}" >> "${ALERT_LOG}"

cat <<EOF2 > "${ALERT_LATEST_FILE}"
status=${ALERT_STATUS}
reason=${ALERT_REASON}
host=${HOSTNAME_VAL}
time=${TS}
report=${ALERT_REPORT_FILE}
cron=${ALERT_CRON_LOG}
EOF2

echo "OK ✅ ops health alert log yazildi -> ${ALERT_LOG}"
echo "OK ✅ ops health alert latest yazildi -> ${ALERT_LATEST_FILE}"

export ALERT_STATUS
export ALERT_REASON
export ALERT_REPORT_FILE
export ALERT_CRON_LOG
export ALERT_LATEST_FILE
export ALERT_LOG

# geriye uyumluluk
export REPORT_FILE="${ALERT_REPORT_FILE}"
export CRON_LOG="${ALERT_CRON_LOG}"
export LATEST_ALERT_FILE="${ALERT_LATEST_FILE}"
export ALERT_LOG_FILE="${ALERT_LOG}"

if [ -x "${NOTIFY_SCRIPT}" ]; then
  "${NOTIFY_SCRIPT}" || true
else
  echo "WARN ⚠ notify script executable degil -> ${NOTIFY_SCRIPT}"
fi

exit 0
