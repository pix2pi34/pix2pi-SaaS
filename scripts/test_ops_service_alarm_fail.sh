#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_SYSTEMCTL="$TMP_DIR/fake_systemctl.sh"
FAKE_ALERT="$TMP_DIR/fake_alert.sh"
WATCH_LOG="$TMP_DIR/ops_service_watch.log"
ALERT_LOG="$TMP_DIR/ops_health_alert.log"
ALERT_FILE="$TMP_DIR/ops_health_alert_latest.txt"
REPORT_FILE="$TMP_DIR/ops_health_latest.txt"

cat <<'RPT' > "$REPORT_FILE"
===== STEP 57C / OPS HEALTH REPORT =====
time=2026-04-14 00:19:02

OK ✅ api-gateway active
OK ✅ user-created-consumer active
OK ✅ accounting active
RPT

cat <<'SYS' > "$FAKE_SYSTEMCTL"
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
svc="${2:-}"

case "$cmd:$svc" in
  is-active:pix2pi-api-gateway.service) echo "active" ;;
  is-failed:pix2pi-api-gateway.service) echo "active" ;;

  is-active:pix2pi-user-created-consumer.service) echo "failed" ;;
  is-failed:pix2pi-user-created-consumer.service) echo "failed" ;;

  is-active:pix2pi-accounting.service) echo "active" ;;
  is-failed:pix2pi-accounting.service) echo "active" ;;

  *) echo "unknown" ;;
esac
SYS
chmod +x "$FAKE_SYSTEMCTL"

cat <<'ALT' > "$FAKE_ALERT"
#!/usr/bin/env bash
set -euo pipefail

: "${ALERT_REASON:?}"
: "${ALERT_STATUS:?}"
: "${ALERT_REPORT_FILE:?}"
: "${ALERT_CRON_LOG:?}"
: "${ALERT_LOG:?}"
: "${ALERT_FILE:?}"

echo "alert_status=$ALERT_STATUS reason=$ALERT_REASON" >> "$ALERT_LOG"

cat > "$ALERT_FILE" <<EOF2
status=$ALERT_STATUS
reason=$ALERT_REASON
report=$ALERT_REPORT_FILE
cron=$ALERT_CRON_LOG
EOF2
ALT
chmod +x "$FAKE_ALERT"

set +e
SYSTEMCTL_BIN="$FAKE_SYSTEMCTL" \
ALERT_SCRIPT="$FAKE_ALERT" \
ALERT_LOG="$ALERT_LOG" \
ALERT_FILE="$ALERT_FILE" \
LOG_FILE="$WATCH_LOG" \
REPORT_FILE="$REPORT_FILE" \
STATE_DIR="$TMP_DIR/state" \
~/pix2pi/pix2pi-SaaS/scripts/check_ops_service_failures.sh >/dev/null 2>&1
RC=$?
set -e

if [ "$RC" -eq 0 ]; then
  echo "ERROR ❌ negative test fail etmeliydi ama rc=0 dondu"
  exit 1
fi

grep -Fq "service unhealthy | service=pix2pi-user-created-consumer.service" "$WATCH_LOG"
grep -Fq "service unhealthy: pix2pi-user-created-consumer.service" "$ALERT_LOG"
grep -Fq "pix2pi-user-created-consumer.service" "$ALERT_FILE"

echo "OK ✅ watchdog service fail non-zero rc -> rc=$RC"
echo "OK ✅ alert log yazildi -> $ALERT_LOG"
echo "OK ✅ latest alert dosyasi yazildi -> $ALERT_FILE"
echo "OK ✅ step_57j_negative_test gecti"
