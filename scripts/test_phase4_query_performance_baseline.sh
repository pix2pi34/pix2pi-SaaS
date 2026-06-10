#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_query_performance_baseline.sh"
REPORT="docs/phase4/14_4_1_query_performance_baseline_report.md"
TOP_QUERY_FILE="docs/phase4/14_4_1_query_performance_top_queries.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ query performance baseline script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_4_1_query_perf.log 2>&1 || {
  echo "TEST_FAIL ❌ query performance baseline script hata verdi"
  cat /tmp/pix2pi_14_4_1_query_perf.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_PERFORMANCE_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ query performance baseline PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PG_STAT_STATEMENTS_QUERY_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_stat query baseline PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PG_STAT_STATEMENTS_EXTENSION=t" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_stat extension aktif degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "TRACK_IO_TIMING=on" "$REPORT" || {
  echo "TEST_FAIL ❌ track_io_timing on degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$TOP_QUERY_FILE" ]; then
  echo "TEST_FAIL ❌ top query file yok"
  exit 1
fi

grep -q $'queryid\tcalls\ttotal_exec_time_ms' "$TOP_QUERY_FILE" || {
  echo "TEST_FAIL ❌ top query file header hatali"
  sed -n '1,20p' "$TOP_QUERY_FILE" || true
  exit 1
}

if grep -Eiq $'\t(select|insert|update|delete|with|alter|create|drop)[[:space:]]' "$TOP_QUERY_FILE"; then
  echo "TEST_FAIL ❌ top query file query text iceriyor olabilir"
  sed -n '1,40p' "$TOP_QUERY_FILE" || true
  exit 1
fi

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$TOP_QUERY_FILE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_QUERY_PERFORMANCE_BASELINE_TEST=PASS ✅"
echo "PHASE4_QUERY_PERFORMANCE_NO_QUERY_TEXT_TEST=PASS ✅"
echo "PHASE4_QUERY_PERFORMANCE_SECRET_TEST=PASS ✅"
