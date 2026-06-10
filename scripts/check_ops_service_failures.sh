#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/go/bin:/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

LOG_FILE="${LOG_FILE:-/var/log/pix2pi/ops_service_watch.log}"
REPORT_FILE="${REPORT_FILE:-/root/pix2pi/pix2pi-SaaS/reports/ops_health_latest.txt}"
ALERT_SCRIPT="${ALERT_SCRIPT:-/root/pix2pi/pix2pi-SaaS/scripts/ops_health_alert.sh}"
SYSTEMCTL_BIN="${SYSTEMCTL_BIN:-systemctl}"
STATE_DIR="${STATE_DIR:-/var/log/pix2pi/ops_service_watch_state}"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$STATE_DIR"

sanitize_name() {
  echo "$1" | tr '/: ' '___'
}

services=(
  "pix2pi-api-gateway.service"
  "pix2pi-user-created-consumer.service"
  "pix2pi-accounting.service"
)

echo "===== STEP 57J / SERVICE FAILURE SCAN $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"

fail_count=0

for svc in "${services[@]}"; do
  active="$("$SYSTEMCTL_BIN" is-active "$svc" 2>/dev/null || true)"
  failed="$("$SYSTEMCTL_BIN" is-failed "$svc" 2>/dev/null || true)"

  state_file="$STATE_DIR/$(sanitize_name "$svc").state"
  state_value="active=$active failed=$failed"

  if [ "$active" = "active" ] && [ "$failed" != "failed" ]; then
    echo "OK ✅ service healthy | service=$svc active=$active failed=$failed" >> "$LOG_FILE"

    if [ -f "$state_file" ]; then
      prev_state="$(cat "$state_file" 2>/dev/null || true)"
      echo "OK ✅ service recovery | service=$svc prev=[$prev_state] now=[$state_value]" >> "$LOG_FILE"
      rm -f "$state_file"
    fi

    continue
  fi

  fail_count=$((fail_count + 1))
  prev_state="$(cat "$state_file" 2>/dev/null || true)"

  if [ "$prev_state" != "$state_value" ]; then
    echo "$state_value" > "$state_file"
    echo "ERROR ❌ service unhealthy | service=$svc active=$active failed=$failed" >> "$LOG_FILE"

    ALERT_REASON="service unhealthy: $svc active=$active failed=$failed" \
    ALERT_STATUS="critical" \
    ALERT_REPORT_FILE="$REPORT_FILE" \
    ALERT_CRON_LOG="$LOG_FILE" \
    "$ALERT_SCRIPT" >> "$LOG_FILE" 2>&1 || true
  else
    echo "WARN ⚠ service still unhealthy | service=$svc active=$active failed=$failed" >> "$LOG_FILE"
  fi
done

if [ "$fail_count" -gt 0 ]; then
  echo "ERROR ❌ step_57j_service_failure_scan fail_count=$fail_count" >> "$LOG_FILE"
  exit 1
fi

echo "OK ✅ step_57j_service_failure_scan gecti" >> "$LOG_FILE"
