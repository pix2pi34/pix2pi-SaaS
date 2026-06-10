#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_observability_performance.sh"
REPORT="docs/phase4/14_3_1_db_observability_performance_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ db observability performance script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_3_1_db_observability.log 2>&1 || {
  echo "TEST_FAIL ❌ db observability script hata verdi"
  cat /tmp/pix2pi_14_3_1_db_observability.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ observability discovery PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ DB connection PASS yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB primary write degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_PERF_RISK_LEVEL=" "$REPORT" || {
  echo "TEST_FAIL ❌ DB perf risk level yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_TOTAL_CONNECTIONS=" "$REPORT" || {
  echo "TEST_FAIL ❌ connection metric yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_WAITING_LOCK_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ lock metric yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_OBSERVABILITY_PERFORMANCE_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_SECRET_TEST=PASS ✅"
