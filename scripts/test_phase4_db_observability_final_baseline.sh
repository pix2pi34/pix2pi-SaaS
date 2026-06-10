#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_observability_final_baseline.sh"
REPORT="docs/phase4/14_3_5_db_observability_final_baseline_report.md"
CLOSURE="docs/phase4/14_3_final_db_observability_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ final baseline script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_3_5_final_baseline.log 2>&1 || {
  echo "TEST_FAIL ❌ final baseline script hata verdi"
  cat /tmp/pix2pi_14_3_5_final_baseline.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_OBSERVABILITY_FINAL_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final baseline PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PG_STAT_STATEMENTS_EVIDENCE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_stat evidence PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PG_STAT_STATEMENTS_EXTENSION=t" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_stat extension t degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "TRACK_IO_TIMING=on" "$REPORT" || {
  echo "TEST_FAIL ❌ track_io_timing on degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_PERF_RISK_LEVEL=LOW" "$REPORT" || {
  echo "TEST_FAIL ❌ DB perf risk LOW degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$CLOSURE" ]; then
  echo "TEST_FAIL ❌ closure report yok"
  exit 1
fi

grep -q "FAZ4_14_3_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ 14.3 closure PASS degil"
  sed -n '1,220p' "$CLOSURE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_OBSERVABILITY_FINAL_BASELINE_TEST=PASS ✅"
echo "PHASE4_PG_STAT_STATEMENTS_EVIDENCE_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_SECRET_TEST=PASS ✅"
