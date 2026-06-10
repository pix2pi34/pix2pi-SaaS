#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="${REPORT_FILE:-/root/pix2pi/pix2pi-SaaS/reports/ops_health_latest.txt}"
CRON_LOG="${CRON_LOG:-/var/log/pix2pi/ops_health_cron.log}"
MAX_AGE_SECONDS="${MAX_AGE_SECONDS:-$((26 * 60 * 60))}"

fail() {
  echo "ERROR ❌ $1"
  exit 1
}

ok() {
  echo "OK ✅ $1"
}

echo "===== STEP 57E / OPS HEALTH WATCHDOG ====="

[ -f "$REPORT_FILE" ] || fail "ops_health_latest.txt yok"
ok "latest report bulundu -> $REPORT_FILE"

[ -f "$CRON_LOG" ] || fail "ops_health_cron.log yok"
ok "cron log bulundu -> $CRON_LOG"

NOW_TS=$(date +%s)
REPORT_TS=$(stat -c %Y "$REPORT_FILE")
AGE=$((NOW_TS - REPORT_TS))

echo "INFO ▶ report_age_seconds=$AGE"

if [ "$AGE" -gt "$MAX_AGE_SECONDS" ]; then
  fail "latest report cok eski: ${AGE}s"
fi
ok "latest report taze"

grep -Fq "OK ✅ api-gateway active" "$REPORT_FILE" || fail "api-gateway active satiri yok"
ok "api-gateway satiri bulundu"

grep -Fq "OK ✅ user-created-consumer active" "$REPORT_FILE" || fail "user-created-consumer active satiri yok"
ok "user-created-consumer satiri bulundu"

grep -Fq "OK ✅ accounting active" "$REPORT_FILE" || fail "accounting active satiri yok"
ok "accounting active satiri bulundu"

grep -Fq "OK ✅ step_57b_prod_ops_suite gecti" "$REPORT_FILE" || fail "step_57b_prod_ops_suite gecti satiri yok"
ok "prod ops suite gecis satiri bulundu"

grep -Fq "OK ✅ step_57c_ops_health_report gecti" "$REPORT_FILE" || fail "step_57c_ops_health_report gecti satiri yok"
ok "ops health report gecis satiri bulundu"

START_LINE="$(grep -n 'pix2pi ops health daily start' "$CRON_LOG" | tail -n 1 | cut -d: -f1 || true)"
END_LINE="$(grep -n 'pix2pi ops health daily end' "$CRON_LOG" | tail -n 1 | cut -d: -f1 || true)"

[ -n "$START_LINE" ] || fail "cron start log bulunamadi"
ok "cron start log bulundu -> line=$START_LINE"

[ -n "$END_LINE" ] || fail "cron end log bulunamadi"
ok "cron end log bulundu -> line=$END_LINE"

if [ "$END_LINE" -lt "$START_LINE" ]; then
  fail "cron start/end sirasi bozuk"
fi
ok "cron start/end sirasi dogru"

echo "OK ✅ step_57e_ops_health_watchdog gecti"
