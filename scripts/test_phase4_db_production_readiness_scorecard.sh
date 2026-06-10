#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_production_readiness_scorecard.sh"
REPORT="docs/phase4/14_5_2_db_production_readiness_scorecard_report.md"
SCORECARD="docs/phase4/14_5_2_db_production_readiness_scorecard.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ production readiness scorecard script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_5_2_scorecard.log 2>&1 || {
  echo "TEST_FAIL ❌ production readiness scorecard script hata verdi"
  cat /tmp/pix2pi_14_5_2_scorecard.log || true
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "DB_PRODUCTION_READINESS_SCORECARD=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ scorecard PASS degil"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "DB_PRODUCTION_READINESS_SCORE=" "$REPORT" || {
  echo "TEST_FAIL ❌ score yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_PRODUCTION_READINESS_GRADE=" "$REPORT" || {
  echo "TEST_FAIL ❌ grade yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_PRODUCTION_READINESS_STATUS=READY_WITH_DEFERRED_ACTIONS" "$REPORT" || {
  echo "TEST_FAIL ❌ expected deferred readiness status yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "BLOCKER_COUNT=0" "$REPORT" || {
  echo "TEST_FAIL ❌ blocker count 0 degil"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB connection PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB role PRIMARY_WRITE yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

if [ ! -f "$SCORECARD" ]; then
  echo "TEST_FAIL ❌ scorecard file yok"
  exit 1
fi

grep -q $'category\tscore\tmax_score\tstatus\tnote' "$SCORECARD" || {
  echo "TEST_FAIL ❌ scorecard header hatali"
  sed -n '1,20p' "$SCORECARD" || true
  exit 1
}

grep -q $'pitr_readiness\t' "$SCORECARD" || {
  echo "TEST_FAIL ❌ PITR scorecard satiri yok"
  sed -n '1,80p' "$SCORECARD" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$SCORECARD"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_PRODUCTION_READINESS_SCORECARD_TEST=PASS ✅"
echo "PHASE4_DB_PRODUCTION_READINESS_DEFERRED_TEST=PASS ✅"
echo "PHASE4_DB_PRODUCTION_READINESS_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_PRODUCTION_READINESS_SECRET_TEST=PASS ✅"
