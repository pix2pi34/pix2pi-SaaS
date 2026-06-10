#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_REPORT="$TMP_DIR/ops_health_latest.txt"
FAKE_CRON="$TMP_DIR/ops_health_cron.log"
OUT_LOG="$TMP_DIR/watchdog_fail_output.log"

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
> "$OUT_LOG" 2>&1
RC=$?
set -e

cat "$OUT_LOG"

if [ "$RC" -eq 0 ]; then
  echo "ERROR ❌ watchdog fail etmeliydi ama 0 dondu"
  exit 1
fi

grep -Fq "ERROR ❌ accounting active satiri yok" "$OUT_LOG" || {
  echo "ERROR ❌ beklenen hata mesaji bulunamadi"
  exit 1
}

echo "OK ✅ watchdog non-zero exit verdi -> rc=$RC"
echo "OK ✅ beklenen hata mesaji bulundu"
echo "OK ✅ step_57f_watchdog_negative_test gecti"
