#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_readmodel_apply_gate.sh"
MIGRATION_BASE="20260427_151001_readmodel_operational_tables"
REPORT="docs/phase4/15_2_readmodel_apply_gate_report.md"
PLAN="docs/phase4/15_2_readmodel_apply_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ apply gate script executable degil"
  exit 1
fi

bash "$SCRIPT" . "$MIGRATION_BASE" >/tmp/pix2pi_15_2_apply_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ apply gate script hata verdi"
  cat /tmp/pix2pi_15_2_apply_gate.log || true
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_APPLY_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ apply gate PASS degil"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_15_1_OPERATIONAL_READMODEL_TABLES=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 15.1 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_CHAIN_VALIDATOR_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ chain validator PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ DB connection PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB role primary write yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "SCHEMA_MIGRATIONS_DIRTY_STATE=f" "$REPORT" || {
  echo "TEST_FAIL ❌ schema_migrations dirty normalized f degil"
  sed -n '1,280p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_APPLY_DECISION=PLAN_READY_APPLY_NOT_EXECUTED" "$REPORT" || {
  echo "TEST_FAIL ❌ apply decision expected degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_APPLY_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB apply NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if [ ! -f "$PLAN" ]; then
  echo "TEST_FAIL ❌ candidate plan yok"
  exit 1
fi

grep -q "exit 99" "$PLAN" || {
  echo "TEST_FAIL ❌ candidate plan blocked degil"
  sed -n '1,120p' "$PLAN" || true
  exit 1
}

grep -q "APPLY_READMODEL" "$PLAN" || {
  echo "TEST_FAIL ❌ explicit APPLY_READMODEL gate yok"
  sed -n '1,160p' "$PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$PLAN"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_READMODEL_APPLY_GATE_TEST=PASS ✅"
echo "PHASE4_READMODEL_DIRTY_BOOL_NORMALIZATION_TEST=PASS ✅"
echo "PHASE4_READMODEL_APPLY_PLAN_BLOCK_TEST=PASS ✅"
echo "PHASE4_READMODEL_NO_APPLY_TEST=PASS ✅"
echo "PHASE4_READMODEL_SECRET_TEST=PASS ✅"
