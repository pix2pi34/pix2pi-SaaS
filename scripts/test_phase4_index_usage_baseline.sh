#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_index_usage_baseline.sh"
REPORT="docs/phase4/14_4_2_index_usage_baseline_report.md"
TABLE_SCAN_FILE="docs/phase4/14_4_2_table_scan_metrics.tsv"
INDEX_USAGE_FILE="docs/phase4/14_4_2_index_usage_metrics.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ index usage baseline script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_4_2_index_usage.log 2>&1 || {
  echo "TEST_FAIL ❌ index usage baseline script hata verdi"
  cat /tmp/pix2pi_14_4_2_index_usage.log || true
  sed -n '1,280p' "$REPORT" || true
  exit 1
}

grep -q "INDEX_USAGE_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ index usage baseline PASS degil"
  sed -n '1,280p' "$REPORT" || true
  exit 1
}

grep -q "DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ DB connection PASS yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB role primary write yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "INDEX_DROP_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ index drop NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "INDEX_CREATE_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ index create NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$TABLE_SCAN_FILE" ]; then
  echo "TEST_FAIL ❌ table scan file yok"
  exit 1
fi

if [ ! -f "$INDEX_USAGE_FILE" ]; then
  echo "TEST_FAIL ❌ index usage file yok"
  exit 1
fi

grep -q $'rank\tschemaname\ttable_name\tseq_scan\tidx_scan' "$TABLE_SCAN_FILE" || {
  echo "TEST_FAIL ❌ table scan header hatali"
  sed -n '1,20p' "$TABLE_SCAN_FILE" || true
  exit 1
}

grep -q $'rank\tschemaname\ttable_name\tindex_name\tidx_scan' "$INDEX_USAGE_FILE" || {
  echo "TEST_FAIL ❌ index usage header hatali"
  sed -n '1,20p' "$INDEX_USAGE_FILE" || true
  exit 1
}

if grep -R "DROP INDEX" "$REPORT" "$TABLE_SCAN_FILE" "$INDEX_USAGE_FILE"; then
  echo "TEST_FAIL ❌ drop index ifadesi rapora girdi"
  exit 1
fi

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$TABLE_SCAN_FILE" "$INDEX_USAGE_FILE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_INDEX_USAGE_BASELINE_TEST=PASS ✅"
echo "PHASE4_INDEX_USAGE_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_INDEX_USAGE_SECRET_TEST=PASS ✅"
