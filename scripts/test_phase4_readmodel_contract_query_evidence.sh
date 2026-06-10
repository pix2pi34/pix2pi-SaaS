#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_readmodel_contract_query_evidence.sh"
REPORT="docs/phase4/15_4_readmodel_contract_query_evidence_report.md"
INVENTORY="docs/phase4/15_4_readmodel_contract_inventory.tsv"
CLOSURE="docs/phase4/15_readmodel_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ contract/query evidence script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_15_4_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ contract/query evidence script hata verdi"
  cat /tmp/pix2pi_15_4_contract.log || true
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_CONTRACT_QUERY_EVIDENCE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ readmodel contract PASS degil"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_TARGET_TABLE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ target table count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_PRIMARY_KEY_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ primary key count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_TENANT_ID_COLUMN_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ tenant_id column count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_NOT_NULL_TENANT_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ tenant_id not null count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_ROLLBACK_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ rollback smoke PASS yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "ROLLBACK_SMOKE_PERSISTED_COUNT=0" "$REPORT" || {
  echo "TEST_FAIL ❌ rollback smoke persisted count 0 yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "DB_PERSISTENT_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ persistent mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ inventory file yok"
  exit 1
fi

grep -q $'object_type\tobject_name\tcontract_status' "$INVENTORY" || {
  echo "TEST_FAIL ❌ inventory header hatali"
  sed -n '1,20p' "$INVENTORY" || true
  exit 1
}

if [ ! -f "$CLOSURE" ]; then
  echo "TEST_FAIL ❌ closure file yok"
  exit 1
fi

grep -q "READMODEL_FINAL_CLOSURE=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ final closure PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

grep -q "FAZ4_15_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ FAZ4 15 final status PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_READMODEL_CONTRACT_QUERY_EVIDENCE_TEST=PASS ✅"
echo "PHASE4_READMODEL_ROLLBACK_SMOKE_TEST=PASS ✅"
echo "PHASE4_READMODEL_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4_READMODEL_SECRET_TEST=PASS ✅"
