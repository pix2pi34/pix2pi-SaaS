#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_security_tests.sh"
PY_SCRIPT="scripts/phase4b_security_tests.py"
REPORT="docs/phase4/21_6_security_tests_report.md"
MATRIX="docs/phase4/21_6_security_tests_matrix.tsv"
INVENTORY="docs/phase4/21_6_security_tests_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ security tests wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ security tests python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_21_6_security_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ security tests script hata verdi"
  cat /tmp/pix2pi_21_6_security_tests.log || true
  sed -n '1,2400p' "$REPORT" || true
  exit 1
}

for required in \
  "SECURITY_TESTS=PASS" \
  "FAZ4B_21_6_FINAL_STATUS=PASS" \
  "SECURITY_ROLE_MATRIX_TEST=PASS" \
  "SECURITY_PERMISSION_GUARD_TEST=PASS" \
  "SECURITY_AUDIT_EVENT_MODEL_TEST=PASS" \
  "SECURITY_TENANT_ACCESS_TEST=PASS" \
  "SECURITY_SUPPORT_SUPER_ADMIN_BOUNDARY_TEST=PASS" \
  "SECURITY_ARTIFACT_COVERAGE_TEST=PASS" \
  "SECURITY_NO_APPLY_TEST=PASS" \
  "SECURITY_SECRET_SAFETY_TEST=PASS" \
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
    sed -n '1,2400p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  role_matrix \
  permission_guard \
  audit_event_model \
  tenant_access_checks \
  support_super_admin_boundary \
  artifact_coverage \
  no_apply \
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
  "21.5"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_SECURITY_TESTS_TEST=PASS ✅"
echo "PHASE4B_SECURITY_ROLE_MATRIX_TEST=PASS ✅"
echo "PHASE4B_SECURITY_PERMISSION_GUARD_TEST=PASS ✅"
echo "PHASE4B_SECURITY_AUDIT_EVENT_MODEL_TEST=PASS ✅"
echo "PHASE4B_SECURITY_TENANT_ACCESS_TEST=PASS ✅"
echo "PHASE4B_SECURITY_SUPPORT_SUPER_ADMIN_BOUNDARY_TEST=PASS ✅"
echo "PHASE4B_SECURITY_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_SECURITY_SECRET_TEST=PASS ✅"
