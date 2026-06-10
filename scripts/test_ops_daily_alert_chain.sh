#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TEST_LOG="$TMP_DIR/ops_health_cron.log"
TEST_REPORT="$TMP_DIR/ops_health_latest.txt"
TEST_ALERT_LATEST="$TMP_DIR/ops_alert_latest.txt"
TEST_ALERT_LOG="$TMP_DIR/ops_health_alert.log"

cat <<'RPT' > "$TEST_REPORT"
===== STEP 57Q / OPS HEALTH REPORT =====
time=2026-04-14 01:00:00

===== 1) SERVICE STATUS =====
OK ✅ api-gateway active
OK ✅ user-created-consumer active
RPT

cat <<'EOF2' > "$TMP_DIR/fail_watchdog.sh"
#!/usr/bin/env bash
set -euo pipefail
echo "ERROR ❌ accounting active satiri yok"
exit 1
EOF2
chmod +x "$TMP_DIR/fail_watchdog.sh"

cat <<'EOF3' > "$TMP_DIR/fake_daily_runner.sh"
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:?}"
REPORT_FILE="${REPORT_FILE:?}"
WATCHDOG_SCRIPT="${WATCHDOG_SCRIPT:?}"
ALERT_SCRIPT="${ALERT_SCRIPT:?}"
ALERT_LATEST_FILE="${ALERT_LATEST_FILE:?}"
ALERT_LOG="${ALERT_LOG:?}"

START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== pix2pi ops health daily start ${START_TS} =====" >> "$LOG_FILE"

set +e
REPORT_FILE="$REPORT_FILE" \
CRON_LOG="$LOG_FILE" \
"$WATCHDOG_SCRIPT" >> "$LOG_FILE" 2>&1
WATCHDOG_RC=$?
set -e

END_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== pix2pi ops health daily end ${END_TS} =====" >> "$LOG_FILE"

if [ "$WATCHDOG_RC" -ne 0 ]; then
  ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:?}" \
  ALERT_WEBHOOK_MODE="${ALERT_WEBHOOK_MODE:-slack}" \
  ALERT_STATUS="critical" \
  ALERT_REASON="step_57q_daily_runner_fail rc=${WATCHDOG_RC}" \
  ALERT_REPORT_FILE="$REPORT_FILE" \
  ALERT_CRON_LOG="$LOG_FILE" \
  ALERT_LATEST_FILE="$ALERT_LATEST_FILE" \
  ALERT_LOG="$ALERT_LOG" \
  "$ALERT_SCRIPT" >> "$LOG_FILE" 2>&1 || true
fi

echo "OK ✅ fake daily runner tamam"
EOF3
chmod +x "$TMP_DIR/fake_daily_runner.sh"

ALERT_WEBHOOK_URL="http://127.0.0.1:18081/webhook" \
ALERT_WEBHOOK_MODE="slack" \
LOG_FILE="$TEST_LOG" \
REPORT_FILE="$TEST_REPORT" \
WATCHDOG_SCRIPT="$TMP_DIR/fail_watchdog.sh" \
ALERT_SCRIPT="/root/pix2pi/pix2pi-SaaS/scripts/ops_health_alert.sh" \
ALERT_LATEST_FILE="$TEST_ALERT_LATEST" \
ALERT_LOG="$TEST_ALERT_LOG" \
"$TMP_DIR/fake_daily_runner.sh"

echo
echo "===== 57Q CRON LOG ====="
cat "$TEST_LOG"

echo
echo "===== 57Q ALERT LOG ====="
cat "$TEST_ALERT_LOG"

echo
echo "===== 57Q ALERT LATEST ====="
cat "$TEST_ALERT_LATEST"

echo
echo "OK ✅ step_57q_daily_alert_chain geçti"
