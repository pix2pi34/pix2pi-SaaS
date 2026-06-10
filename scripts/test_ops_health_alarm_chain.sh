#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_REPORT="$TMP_DIR/ops_health_latest.txt"
FAKE_CRON="$TMP_DIR/ops_health_cron.log"
FAKE_ALERT_LOG="$TMP_DIR/ops_health_alert.log"
FAKE_ALERT_FILE="$TMP_DIR/ops_alert_latest.txt"
WATCHDOG_OUT="$TMP_DIR/watchdog_fail_output.log"

cat <<'RPT' > "$FAKE_REPORT"
===== STEP 57C / OPS HEALTH REPORT =====
time=2026-04-13 23:13:22

===== 1) SERVICE STATUS =====
OK ✅ api-gateway active
OK ✅ user-created-consumer active
RPT

cat <<'CRON' > "$FAKE_CRON"
2026-04-13 23:21:19 pix2pi ops health daily start
2026-04-13 23:21:22 pix2pi ops health daily end
CRON

set +e
REPORT_FILE="$FAKE_REPORT" \
CRON_LOG="$FAKE_CRON" \
MAX_AGE_SECONDS=999999 \
~/pix2pi/pix2pi-SaaS/scripts/check_ops_health_watchdog.sh \
> "$WATCHDOG_OUT" 2>&1
RC=$?
set -e

cat "$WATCHDOG_OUT"

if [ "$RC" -eq 0 ]; then
  echo "ERROR ❌ watchdog fail etmeliydi ama 0 dondu"
  exit 1
fi

grep -Fq "ERROR ❌ accounting active satiri yok" "$WATCHDOG_OUT" || {
  echo "ERROR ❌ beklenen watchdog hata mesaji bulunamadi"
  exit 1
}

echo "$(date '+%Y-%m-%d %H:%M:%S') pix2pi ops health daily watchdog fail rc=$RC" >> "$FAKE_CRON"
echo "OK ✅ cron fail satiri yazildi"

ALERT_LOG="$FAKE_ALERT_LOG" \
ALERT_FILE="$FAKE_ALERT_FILE" \
ALERT_REASON="ops health watchdog fail rc=$RC" \
ALERT_STATUS="critical" \
ALERT_REPORT_FILE="$FAKE_REPORT" \
ALERT_CRON_LOG="$FAKE_CRON" \
~/pix2pi/pix2pi-SaaS/scripts/ops_health_alert.sh

grep -Fq "watchdog fail rc=$RC" "$FAKE_ALERT_LOG" || {
  echo "ERROR ❌ alert log icinde fail kaydi bulunamadi"
  exit 1
}

grep -Fq "reason=ops health watchdog fail rc=$RC" "$FAKE_ALERT_FILE" || {
  echo "ERROR ❌ latest alert dosyasinda reason bulunamadi"
  exit 1
}

grep -Fq "pix2pi ops health daily watchdog fail rc=$RC" "$FAKE_CRON" || {
  echo "ERROR ❌ cron fail gorunurlugu bulunamadi"
  exit 1
}

echo "OK ✅ watchdog non-zero exit verdi -> rc=$RC"
echo "OK ✅ alert log dogrulandi"
echo "OK ✅ latest alert dosyasi dogrulandi"
echo "OK ✅ cron fail gorunurlugu dogrulandi"
echo "OK ✅ step_57g_alarm_chain_test gecti"
