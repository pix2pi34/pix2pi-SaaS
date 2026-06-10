#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_role_matrix.sh"
PY_SCRIPT="scripts/phase4b_role_matrix.py"
REPORT="docs/phase4/21_1_role_matrix_report.md"
INVENTORY="docs/phase4/21_1_role_matrix_inventory.tsv"
MATRIX="docs/phase4/21_1_role_matrix_matrix.tsv"
UP_FILE="db/migrations/20260429_211001_security_role_matrix.up.sql"
DOWN_FILE="db/migrations/20260429_211001_security_role_matrix.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ role matrix wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ role matrix python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_21_1_role_matrix.log 2>&1 || {
  echo "TEST_FAIL ❌ role matrix script hata verdi"
  cat /tmp/pix2pi_21_1_role_matrix.log || true
  sed -n '1,1800p' "$REPORT" || true
  exit 1
}

for required in \
  "ROLE_MATRIX=PASS" \
  "FAZ4B_21_1_FINAL_STATUS=PASS" \
  "PREVIOUS_19_FINAL_STATUS=PASS" \
  "ROLE_MATRIX_MIGRATION_PAIR=PASS" \
  "ROLE_MATRIX_SCHEMA_STATUS=PASS" \
  "ROLE_MATRIX_TABLE_STATUS=PASS" \
  "ROLE_MATRIX_TENANT_SAFETY_STATUS=PASS" \
  "ROLE_MATRIX_ROLE_STATUS=PASS" \
  "ROLE_MATRIX_PERMISSION_STATUS=PASS" \
  "ROLE_MATRIX_AUDIT_READY_STATUS=PASS" \
  "ROLE_MATRIX_BOUNDARY_STATUS=PASS" \
  "ROLE_MATRIX_INDEX_STATUS=PASS" \
  "ROLE_MATRIX_DOWN_STATUS=PASS" \
  "ROLE_MATRIX_RISK_STATUS=PASS" \
  "ROLE_MATRIX_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "RBAC_ENFORCEMENT_EXECUTED=NO" \
  "AUDIT_LOG_WRITE_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1800p' "$REPORT" || true
    exit 1
  }
done

for f in "$INVENTORY" "$MATRIX" "$UP_FILE" "$DOWN_FILE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for table in \
  role_matrix_profiles \
  role_definitions \
  permission_definitions \
  role_permission_matrix \
  role_scope_rules \
  role_matrix_validation_errors
do
  grep -q "$table" "$UP_FILE" || {
    echo "TEST_FAIL ❌ up migration table eksik: $table"
    exit 1
  }

  grep -q "$table" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory table eksik: $table"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "tenant_id text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ tenant_id not null yok"
  exit 1
}

grep -q "role_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ role_code yok"
  exit 1
}

grep -q "permission_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ permission_code yok"
  exit 1
}

grep -q "allow_access boolean NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ allow_access yok"
  exit 1
}

grep -q "requires_audit boolean NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ requires_audit yok"
  exit 1
}

if grep -Ei "ALTER SYSTEM|docker|systemctl|psql " "$UP_FILE"; then
  echo "TEST_FAIL ❌ up migration icinde sistem tokeni var"
  exit 1
fi

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_ROLE_MATRIX_TEST=PASS ✅"
echo "PHASE4B_ROLE_MATRIX_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_ROLE_MATRIX_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_ROLE_MATRIX_BOUNDARY_TEST=PASS ✅"
echo "PHASE4B_ROLE_MATRIX_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_ROLE_MATRIX_SECRET_TEST=PASS ✅"
