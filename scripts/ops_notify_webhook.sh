#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/pix2pi/ops_notify.log"

mkdir -p /var/log/pix2pi
touch "$LOG_FILE"

WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
WEBHOOK_MODE="${ALERT_WEBHOOK_MODE:-slack}"

STATUS="${ALERT_STATUS:-critical}"
REASON="${ALERT_REASON:-unknown}"
REPORT_FILE="${ALERT_REPORT_FILE:-}"
CRON_LOG="${ALERT_CRON_LOG:-}"
HOSTNAME_VALUE="$(hostname)"
TIME_VALUE="$(date '+%Y-%m-%d %H:%M:%S %z')"

if [ -z "$WEBHOOK_URL" ]; then
  echo "WARN ⚠ webhook url tanimli degil, skip edildi" | tee -a "$LOG_FILE"
  exit 0
fi

MESSAGE="[PiX2Pi OPS ALERT]
status=${STATUS}
reason=${REASON}
host=${HOSTNAME_VALUE}
time=${TIME_VALUE}
report=${REPORT_FILE}
cron=${CRON_LOG}"

export WEBHOOK_MODE
export MESSAGE
export STATUS
export REASON
export REPORT_FILE
export CRON_LOG
export HOSTNAME_VALUE
export TIME_VALUE

PAYLOAD="$(python3 - <<'PY'
import json, os

mode = os.getenv("WEBHOOK_MODE", "slack")
message = os.getenv("MESSAGE", "")
status = os.getenv("STATUS", "")
reason = os.getenv("REASON", "")
report_file = os.getenv("REPORT_FILE", "")
cron_log = os.getenv("CRON_LOG", "")
host = os.getenv("HOSTNAME_VALUE", "")
time_value = os.getenv("TIME_VALUE", "")

if mode == "discord":
    data = {"content": message}
elif mode == "generic":
    data = {
        "source": "pix2pi",
        "status": status,
        "reason": reason,
        "host": host,
        "time": time_value,
        "report_file": report_file,
        "cron_log": cron_log,
        "message": message,
    }
else:
    data = {"text": message}

print(json.dumps(data, ensure_ascii=False))
PY
)"

curl -fsS -X POST \
  -H "Content-Type: application/json" \
  --data "$PAYLOAD" \
  "$WEBHOOK_URL" >/dev/null

echo "OK ✅ webhook gonderildi | mode=${WEBHOOK_MODE} url=${WEBHOOK_URL}" | tee -a "$LOG_FILE"
