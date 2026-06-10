#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_health_baseline.sh"
REPORT="docs/phase4/14_4_4_db_health_baseline_report.md"
CONNECTION_METRICS_FILE="docs/phase4/14_4_4_connection_state_metrics.tsv"
LOCK_METRICS_FILE="docs/phase4/14_4_4_lock_wait_metrics.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ DB health baseline script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_4_4_db_health.log 2>&1 || {
  echo "TEST_FAIL ❌ DB health baseline script hata verdi"
  cat /tmp/pix2pi_14_4_4_db_health.log || true
  sed -n '1,300p' "$REPORT" || true
  exit 1
}

grep -q "DB_HEALTH_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ DB health baseline PASS degil"
  sed -n '1,300p' "$REPORT" || true
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

grep -q "DB_HEALTH_RISK_LEVEL=" "$REPORT" || {
  echo "TEST_FAIL ❌ DB health risk level yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_KILL_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query kill NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "LOCK_TERMINATION_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ lock termination NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$CONNECTION_METRICS_FILE" ]; then
  echo "TEST_FAIL ❌ connection metrics file yok"
  exit 1
fi

if [ ! -f "$LOCK_METRICS_FILE" ]; then
  echo "TEST_FAIL ❌ lock metrics file yok"
  exit 1
fi

grep -q $'state\tconnection_count\tmax_query_age_seconds\tmax_xact_age_seconds' "$CONNECTION_METRICS_FILE" || {
  echo "TEST_FAIL ❌ connection metrics header hatali"
  sed -n '1,20p' "$CONNECTION_METRICS_FILE" || true
  exit 1
}

grep -q $'locktype\tmode\tgranted\tlock_count' "$LOCK_METRICS_FILE" || {
  echo "TEST_FAIL ❌ lock metrics header hatali"
  sed -n '1,20p' "$LOCK_METRICS_FILE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$CONNECTION_METRICS_FILE" "$LOCK_METRICS_FILE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_HEALTH_BASELINE_TEST=PASS ✅"
echo "PHASE4_DB_HEALTH_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_HEALTH_SECRET_TEST=PASS ✅"
