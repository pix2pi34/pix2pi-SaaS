#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_known_risks_deferred_register.sh"
REPORT="docs/phase4/14_5_3_db_known_risks_deferred_register_report.md"
REGISTER="docs/phase4/14_5_3_db_known_risks_register.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ risk register script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_5_3_risk_register.log 2>&1 || {
  echo "TEST_FAIL ❌ risk register script hata verdi"
  cat /tmp/pix2pi_14_5_3_risk_register.log || true
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "DB_KNOWN_RISKS_DEFERRED_REGISTER=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ risk register PASS degil"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "RISK_REGISTER_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ risk register created YES yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "BLOCKER_COUNT=0" "$REPORT" || {
  echo "TEST_FAIL ❌ blocker count 0 degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DEFERRED_ACTION_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ deferred action count yok"
  sed -n '1,260p' "$REPORT" || true
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

if [ ! -f "$REGISTER" ]; then
  echo "TEST_FAIL ❌ risk register file yok"
  exit 1
fi

grep -q $'risk_id\tcategory\tseverity\tstatus\tsource\tevidence\taction\tclosure_gate' "$REGISTER" || {
  echo "TEST_FAIL ❌ risk register header hatali"
  sed -n '1,20p' "$REGISTER" || true
  exit 1
}

grep -q "DB-RISK-001" "$REGISTER" || {
  echo "TEST_FAIL ❌ PITR ana risk satiri yok"
  sed -n '1,80p' "$REGISTER" || true
  exit 1
}

grep -q "PITR_CURRENT_READY=NO" "$REGISTER" || {
  echo "TEST_FAIL ❌ PITR current ready NO evidence yok"
  sed -n '1,80p' "$REGISTER" || true
  exit 1
}

grep -q "OBSERVE_ONLY" "$REGISTER" || {
  echo "TEST_FAIL ❌ observe-only satiri yok"
  sed -n '1,120p' "$REGISTER" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$REGISTER"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_KNOWN_RISKS_REGISTER_TEST=PASS ✅"
echo "PHASE4_DB_DEFERRED_ACTION_REGISTER_TEST=PASS ✅"
echo "PHASE4_DB_RISK_REGISTER_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_RISK_REGISTER_SECRET_TEST=PASS ✅"
