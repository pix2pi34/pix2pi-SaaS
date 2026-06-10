#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_final_closure_gate.sh"
REPORT="docs/phase4/14_5_5_db_final_closure_gate_report.md"
FINAL_REPORT="docs/phase4/faz4_db_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ final closure gate script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_5_5_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ final closure gate script hata verdi"
  cat /tmp/pix2pi_14_5_5_final_closure.log || true
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_DB_FINAL_CLOSURE_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final closure gate PASS degil"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_DB_FINAL_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ FAZ4 DB final status PASS yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_DB_READINESS_STATUS=READY_WITH_DEFERRED_ACTIONS" "$REPORT" || {
  echo "TEST_FAIL ❌ readiness status expected deferred degil"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB connection PASS yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB role PRIMARY_WRITE yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if [ ! -f "$FINAL_REPORT" ]; then
  echo "TEST_FAIL ❌ final report yok"
  exit 1
fi

grep -q "FAZ4_DB_FINAL_STATUS=PASS" "$FINAL_REPORT" || {
  echo "TEST_FAIL ❌ final report status PASS degil"
  sed -n '1,320p' "$FINAL_REPORT" || true
  exit 1
}

grep -q "FAZ4_DB_PRODUCTION_READINESS_SCORE=96" "$FINAL_REPORT" || {
  echo "TEST_FAIL ❌ final readiness score 96 yok"
  sed -n '1,320p' "$FINAL_REPORT" || true
  exit 1
}

grep -q "FAZ4_DB_BLOCKER_COUNT=0" "$FINAL_REPORT" || {
  echo "TEST_FAIL ❌ final blocker count 0 yok"
  sed -n '1,320p' "$FINAL_REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$FINAL_REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_FINAL_CLOSURE_GATE_TEST=PASS ✅"
echo "PHASE4_DB_FINAL_READINESS_STATUS_TEST=PASS ✅"
echo "PHASE4_DB_FINAL_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_FINAL_SECRET_TEST=PASS ✅"
