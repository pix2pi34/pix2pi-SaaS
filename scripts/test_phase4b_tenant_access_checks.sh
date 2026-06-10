#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_tenant_access_checks.sh"
PY_SCRIPT="scripts/phase4b_tenant_access_checks.py"
REPORT="docs/phase4/21_4_tenant_access_checks_report.md"
MATRIX="docs/phase4/21_4_tenant_access_checks_matrix.tsv"
CONTRACT="docs/phase4/21_4_tenant_access_checks_contract.md"
CHECKS="docs/phase4/21_4_tenant_access_checks_check_manifest.tsv"
DECISIONS="docs/phase4/21_4_tenant_access_checks_decision_manifest.tsv"
SURFACES="docs/phase4/21_4_tenant_access_checks_surface_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ tenant access checks wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ tenant access checks python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_21_4_tenant_access_checks.log 2>&1 || {
  echo "TEST_FAIL ❌ tenant access checks script hata verdi"
  cat /tmp/pix2pi_21_4_tenant_access_checks.log || true
  sed -n '1,2100p' "$REPORT" || true
  exit 1
}

for required in \
  "TENANT_ACCESS_CHECKS=PASS" \
  "FAZ4B_21_4_FINAL_STATUS=PASS" \
  "TENANT_ACCESS_CHECKS_PREVIOUS_21_3=PASS" \
  "TENANT_ACCESS_CHECKS_CONTRACT=PASS" \
  "TENANT_ACCESS_CHECKS_CHECK_MANIFEST=PASS" \
  "TENANT_ACCESS_CHECKS_DECISION_MANIFEST=PASS" \
  "TENANT_ACCESS_CHECKS_SURFACE_MANIFEST=PASS" \
  "TENANT_ACCESS_CHECKS_TENANT_SAFETY=PASS" \
  "TENANT_ACCESS_CHECKS_IDENTITY_MATCH_STATUS=PASS" \
  "TENANT_ACCESS_CHECKS_BOUNDARY_STATUS=PASS" \
  "TENANT_ACCESS_CHECKS_AUDIT_READY=PASS" \
  "TENANT_ACCESS_CHECKS_NO_APPLY=PASS" \
  "TENANT_ACCESS_CHECKS_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "TENANT_ACCESS_CHECK_EXECUTED=NO" \
  "PERMISSION_GUARD_EXECUTED=NO" \
  "RBAC_ENFORCEMENT_EXECUTED=NO" \
  "AUDIT_LOG_WRITE_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "API_ROUTE_DEPLOYED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2100p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$CHECKS" "$DECISIONS" "$SURFACES"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for check_id in \
  tenant_context_required \
  jwt_tenant_required \
  header_tenant_match \
  actor_tenant_match \
  resource_tenant_match \
  permission_tenant_scope \
  role_tenant_scope \
  audit_tenant_scope \
  cross_tenant_default_deny
do
  grep -q "$check_id" "$CHECKS" || {
    echo "TEST_FAIL ❌ check eksik: $check_id"
    exit 1
  }
done

for decision in \
  ALLOW_TENANT_MATCH \
  DENY_NO_TENANT \
  DENY_JWT_TENANT_MISSING \
  DENY_HEADER_TENANT_MISMATCH \
  DENY_ACTOR_TENANT_MISMATCH \
  DENY_RESOURCE_TENANT_MISMATCH \
  DENY_CROSS_TENANT \
  DENY_SUPPORT_BOUNDARY_TENANT \
  DENY_SUPER_ADMIN_BOUNDARY_TENANT
do
  grep -q "$decision" "$DECISIONS" || {
    echo "TEST_FAIL ❌ decision eksik: $decision"
    exit 1
  }
done

for surface in \
  panel_admin_tenant_check \
  api_route_tenant_check \
  import_batch_tenant_check \
  inventory_resource_tenant_check \
  reporting_resource_tenant_check \
  uat_checklist_tenant_check \
  issue_feedback_tenant_check \
  audit_event_tenant_check \
  support_access_tenant_check \
  super_admin_tenant_check
do
  grep -q "$surface" "$SURFACES" || {
    echo "TEST_FAIL ❌ surface eksik: $surface"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$CHECKS" "$DECISIONS" "$SURFACES"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$CHECKS" "$DECISIONS" "$SURFACES"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$CHECKS" "$DECISIONS" "$SURFACES"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_TENANT_ACCESS_CHECKS_TEST=PASS ✅"
echo "PHASE4B_TENANT_ACCESS_CHECKS_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_TENANT_ACCESS_CHECKS_IDENTITY_MATCH_TEST=PASS ✅"
echo "PHASE4B_TENANT_ACCESS_CHECKS_BOUNDARY_TEST=PASS ✅"
echo "PHASE4B_TENANT_ACCESS_CHECKS_AUDIT_READY_TEST=PASS ✅"
echo "PHASE4B_TENANT_ACCESS_CHECKS_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_TENANT_ACCESS_CHECKS_SECRET_TEST=PASS ✅"
