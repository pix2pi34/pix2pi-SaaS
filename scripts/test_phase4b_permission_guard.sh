#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_permission_guard.sh"
PY_SCRIPT="scripts/phase4b_permission_guard.py"
REPORT="docs/phase4/21_2_permission_guard_report.md"
MATRIX="docs/phase4/21_2_permission_guard_matrix.tsv"
CONTRACT="docs/phase4/21_2_permission_guard_contract.md"
MIDDLEWARE="docs/phase4/21_2_permission_guard_middleware_manifest.tsv"
DECISIONS="docs/phase4/21_2_permission_guard_decision_manifest.tsv"
SURFACES="docs/phase4/21_2_permission_guard_surface_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ permission guard wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ permission guard python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_21_2_permission_guard.log 2>&1 || {
  echo "TEST_FAIL ❌ permission guard script hata verdi"
  cat /tmp/pix2pi_21_2_permission_guard.log || true
  sed -n '1,1900p' "$REPORT" || true
  exit 1
}

for required in \
  "PERMISSION_GUARD=PASS" \
  "FAZ4B_21_2_FINAL_STATUS=PASS" \
  "PERMISSION_GUARD_PREVIOUS_21_1=PASS" \
  "PERMISSION_GUARD_CONTRACT=PASS" \
  "PERMISSION_GUARD_MIDDLEWARE_MANIFEST=PASS" \
  "PERMISSION_GUARD_DECISION_MANIFEST=PASS" \
  "PERMISSION_GUARD_SURFACE_MANIFEST=PASS" \
  "PERMISSION_GUARD_TENANT_SAFETY=PASS" \
  "PERMISSION_GUARD_BOUNDARY_STATUS=PASS" \
  "PERMISSION_GUARD_AUDIT_READY=PASS" \
  "PERMISSION_GUARD_NO_APPLY=PASS" \
  "PERMISSION_GUARD_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "PERMISSION_GUARD_EXECUTED=NO" \
  "RBAC_ENFORCEMENT_EXECUTED=NO" \
  "AUDIT_LOG_WRITE_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "API_ROUTE_DEPLOYED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1900p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$MIDDLEWARE" "$DECISIONS" "$SURFACES"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for decision in \
  ALLOW \
  DENY_NO_TENANT \
  DENY_TENANT_MISMATCH \
  DENY_ROLE_MISSING \
  DENY_PERMISSION_MISSING \
  DENY_SCOPE_MISMATCH \
  DENY_CROSS_TENANT \
  DENY_SUPPORT_BOUNDARY \
  DENY_SUPER_ADMIN_BOUNDARY \
  DENY_HIGH_RISK_APPROVAL_REQUIRED
do
  grep -q "$decision" "$DECISIONS" || {
    echo "TEST_FAIL ❌ decision eksik: $decision"
    exit 1
  }
done

for middleware in \
  RequestIdMiddleware \
  AuthMiddleware \
  TenantContextMiddleware \
  RoleContextMiddleware \
  PermissionGuardMiddleware \
  BoundaryGuardMiddleware \
  AuditReadyMiddleware
do
  grep -q "$middleware" "$MIDDLEWARE" || {
    echo "TEST_FAIL ❌ middleware eksik: $middleware"
    exit 1
  }
done

for surface in \
  panel_route_guard \
  api_route_guard \
  import_action_guard \
  inventory_action_guard \
  reporting_access_guard \
  uat_action_guard \
  issue_feedback_guard \
  security_admin_guard \
  support_boundary_guard \
  super_admin_boundary_guard
do
  grep -q "$surface" "$SURFACES" || {
    echo "TEST_FAIL ❌ surface eksik: $surface"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$MIDDLEWARE" "$DECISIONS" "$SURFACES"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$MIDDLEWARE" "$DECISIONS" "$SURFACES"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$MIDDLEWARE" "$DECISIONS" "$SURFACES"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_PERMISSION_GUARD_TEST=PASS ✅"
echo "PHASE4B_PERMISSION_GUARD_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_PERMISSION_GUARD_DECISION_TEST=PASS ✅"
echo "PHASE4B_PERMISSION_GUARD_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_PERMISSION_GUARD_BOUNDARY_TEST=PASS ✅"
echo "PHASE4B_PERMISSION_GUARD_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_PERMISSION_GUARD_SECRET_TEST=PASS ✅"
