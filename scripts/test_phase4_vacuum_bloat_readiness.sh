#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_vacuum_bloat_readiness.sh"
REPORT="docs/phase4/14_4_3_vacuum_bloat_readiness_report.md"
TABLE_METRICS_FILE="docs/phase4/14_4_3_table_vacuum_metrics.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ vacuum/bloat readiness script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_4_3_vacuum_bloat.log 2>&1 || {
  echo "TEST_FAIL ❌ vacuum/bloat readiness script hata verdi"
  cat /tmp/pix2pi_14_4_3_vacuum_bloat.log || true
  sed -n '1,280p' "$REPORT" || true
  exit 1
}

grep -q "VACUUM_BLOAT_READINESS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ vacuum/bloat readiness PASS degil"
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

grep -q "AUTOVACUUM=on" "$REPORT" || {
  echo "TEST_FAIL ❌ autovacuum on degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "TRACK_COUNTS=on" "$REPORT" || {
  echo "TEST_FAIL ❌ track_counts on degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "VACUUM_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ vacuum executed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "ANALYZE_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ analyze executed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$TABLE_METRICS_FILE" ]; then
  echo "TEST_FAIL ❌ table metrics file yok"
  exit 1
fi

grep -q $'rank\tschemaname\ttable_name\tn_live_tup\tn_dead_tup\tdead_ratio_pct' "$TABLE_METRICS_FILE" || {
  echo "TEST_FAIL ❌ table metrics header hatali"
  sed -n '1,20p' "$TABLE_METRICS_FILE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$TABLE_METRICS_FILE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_VACUUM_BLOAT_READINESS_TEST=PASS ✅"
echo "PHASE4_VACUUM_BLOAT_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_VACUUM_BLOAT_SECRET_TEST=PASS ✅"
