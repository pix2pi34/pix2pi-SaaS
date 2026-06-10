#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_security_rbac_audit_final_closure.sh"
PY_SCRIPT="scripts/phase4b_security_rbac_audit_final_closure.py"
REPORT="docs/phase4/21_7_security_rbac_audit_final_closure_report.md"
MATRIX="docs/phase4/21_7_security_rbac_audit_final_closure_matrix.tsv"
INVENTORY="docs/phase4/21_7_security_rbac_audit_final_closure_inventory.tsv"
CLOSURE="docs/phase4/21_security_rbac_audit_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ security final closure wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ security final closure python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_21_7_security_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ security final closure script hata verdi"
  cat /tmp/pix2pi_21_7_security_final_closure.log || true
  sed -n '1,2600p' "$REPORT" || true
  exit 1
}

for required in \
  "SECURITY_RBAC_AUDIT_FINAL_CLOSURE=PASS" \
  "FAZ4B_21_7_FINAL_STATUS=PASS" \
  "FAZ4B_21_FINAL_STATUS=PASS" \
  "SECURITY_FINAL_ROLE_MATRIX=PASS" \
  "SECURITY_FINAL_PERMISSION_GUARD=PASS" \
  "SECURITY_FINAL_AUDIT_EVENT_MODEL=PASS" \
  "SECURITY_FINAL_TENANT_ACCESS=PASS" \
  "SECURITY_FINAL_SUPPORT_SUPER_ADMIN_BOUNDARY=PASS" \
  "SECURITY_FINAL_SECURITY_TESTS=PASS" \
  "SECURITY_FINAL_ARTIFACT_COVERAGE=PASS" \
  "SECURITY_FINAL_NO_APPLY=PASS" \
  "SECURITY_FINAL_MIGRATION_CHAIN=PASS" \
  "SECURITY_FINAL_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "PERMISSION_GUARD_EXECUTED=NO" \
  "TENANT_ACCESS_CHECK_EXECUTED=NO" \
  "SUPPORT_ACCESS_EXECUTED=NO" \
  "SUPER_ADMIN_ACCESS_EXECUTED=NO" \
  "BREAK_GLASS_EXECUTED=NO" \
  "RBAC_ENFORCEMENT_EXECUTED=NO" \
  "AUDIT_LOG_WRITE_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_21_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure report final status PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  role_matrix \
  permission_guard \
  audit_event_model \
  tenant_access_checks \
  support_super_admin_boundary \
  security_tests \
  artifact_coverage \
  no_apply \
  migration_chain \
  secret_safety
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for block in \
  "21.1" \
  "21.2" \
  "21.3" \
  "21.4" \
  "21.5" \
  "21.6"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_21_7_SECURITY_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_21_FINAL_STATUS_TEST=PASS ✅"
echo "PHASE4B_21_SECURITY_ARTIFACT_TEST=PASS ✅"
echo "PHASE4B_21_SECURITY_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_21_SECURITY_SECRET_TEST=PASS ✅"
