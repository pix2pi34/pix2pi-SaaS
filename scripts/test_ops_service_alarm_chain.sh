#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_SYSTEMCTL="$TMP_DIR/fake_systemctl.sh"
WATCH_LOG="$TMP_DIR/ops_service_watch.log"
ALERT_LOG="$TMP_DIR/ops_health_alert.log"
ALERT_FILE="$TMP_DIR/ops_health_alert_latest.txt"
REPORT_FILE="$TMP_DIR/ops_health_latest.txt"
STATE_DIR="$TMP_DIR/state"

mkdir -p "$STATE_DIR"

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

set +e
SYSTEMCTL_BIN="$FAKE_SYSTEMCTL" \
LOG_FILE="$WATCH_LOG" \
REPORT_FILE="$REPORT_FILE" \
STATE_DIR="$STATE_DIR" \
ALERT_SCRIPT="/root/pix2pi/pix2pi-SaaS/scripts/ops_health_alert.sh" \
ALERT_LOG="$ALERT_LOG" \
ALERT_FILE="$ALERT_FILE" \
~/pix2pi/pix2pi-SaaS/scripts/check_ops_service_failures.sh >/dev/null 2>&1
RC=$?
set -e

if [ "$RC" -eq 0 ]; then
  echo "ERROR ❌ service fail integration rc=0 dondu"
  exit 1
fi

grep -Fq "service unhealthy | service=pix2pi-user-created-consumer.service active=failed failed=failed" "$WATCH_LOG"
grep -Fq "step_57j_service_failure_scan fail_count=1" "$WATCH_LOG"

grep -Fq "service unhealthy: pix2pi-user-created-consumer.service active=failed failed=failed" "$ALERT_LOG"
grep -Fq "status=critical" "$ALERT_FILE"
grep -Fq "reason=service unhealthy: pix2pi-user-created-consumer.service active=failed failed=failed" "$ALERT_FILE"

echo "OK ✅ service fail watchdog non-zero rc -> rc=$RC"
echo "OK ✅ alert log yazildi -> $ALERT_LOG"
echo "OK ✅ latest alert dosyasi yazildi -> $ALERT_FILE"
echo "OK ✅ step_57k_alarm_chain_test gecti"
