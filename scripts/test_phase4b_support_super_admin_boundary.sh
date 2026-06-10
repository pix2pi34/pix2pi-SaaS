#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_support_super_admin_boundary.sh"
PY_SCRIPT="scripts/phase4b_support_super_admin_boundary.py"
REPORT="docs/phase4/21_5_support_super_admin_boundary_report.md"
MATRIX="docs/phase4/21_5_support_super_admin_boundary_matrix.tsv"
CONTRACT="docs/phase4/21_5_support_super_admin_boundary_contract.md"
RULES="docs/phase4/21_5_support_super_admin_boundary_rule_manifest.tsv"
REASONS="docs/phase4/21_5_support_super_admin_boundary_reason_manifest.tsv"
DECISIONS="docs/phase4/21_5_support_super_admin_boundary_decision_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ support/super-admin boundary wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ support/super-admin boundary python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_21_5_support_super_admin_boundary.log 2>&1 || {
  echo "TEST_FAIL ❌ support/super-admin boundary script hata verdi"
  cat /tmp/pix2pi_21_5_support_super_admin_boundary.log || true
  sed -n '1,2200p' "$REPORT" || true
  exit 1
}

for required in \
  "SUPPORT_SUPER_ADMIN_BOUNDARY=PASS" \
  "FAZ4B_21_5_FINAL_STATUS=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_PREVIOUS_21_4=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_MANIFEST=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_MANIFEST=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_MANIFEST=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_TENANT_SAFETY=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_BOUNDARY_STATUS=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_BREAK_GLASS_STATUS=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_READY=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_NO_APPLY=PASS" \
  "SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "SUPPORT_ACCESS_EXECUTED=NO" \
  "SUPER_ADMIN_ACCESS_EXECUTED=NO" \
  "BREAK_GLASS_EXECUTED=NO" \
  "PERMISSION_GUARD_EXECUTED=NO" \
  "RBAC_ENFORCEMENT_EXECUTED=NO" \
  "AUDIT_LOG_WRITE_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$RULES" "$REASONS" "$DECISIONS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for rule_id in \
  support_readonly_requires_reason \
  support_operator_requires_ticket \
  support_timeboxed_access \
  support_no_secret_access \
  support_no_export_default \
  support_tenant_scope_required \
  super_admin_break_glass_required \
  super_admin_dual_approval_required \
  super_admin_timeboxed_access \
  super_admin_no_silent_access \
  cross_tenant_default_deny \
  audit_required_for_all_boundary_access \
  emergency_revocation_required
do
  grep -q "$rule_id" "$RULES" || {
    echo "TEST_FAIL ❌ rule eksik: $rule_id"
    exit 1
  }
done

for reason_code in \
  CUSTOMER_SUPPORT_REQUEST \
  PILOT_UAT_SUPPORT \
  IMPORT_ASSISTANCE \
  INCIDENT_RESPONSE \
  SECURITY_INVESTIGATION \
  DATA_REPAIR_APPROVED \
  BREAK_GLASS_INCIDENT \
  LEGAL_COMPLIANCE_REQUEST \
  INTERNAL_TESTING_DENIED
do
  grep -q "$reason_code" "$REASONS" || {
    echo "TEST_FAIL ❌ reason eksik: $reason_code"
    exit 1
  }
done

for decision in \
  ALLOW_SUPPORT_READONLY_TIMEBOXED \
  ALLOW_SUPPORT_OPERATOR_APPROVED \
  ALLOW_SUPER_ADMIN_BREAK_GLASS_APPROVED \
  DENY_SUPPORT_REASON_MISSING \
  DENY_SUPPORT_TICKET_MISSING \
  DENY_SUPPORT_SECRET_ACCESS \
  DENY_SUPER_ADMIN_BREAK_GLASS_REQUIRED \
  DENY_SUPER_ADMIN_APPROVAL_MISSING \
  DENY_SUPER_ADMIN_SILENT_ACCESS \
  DENY_CROSS_TENANT_BOUNDARY \
  DENY_EMERGENCY_REVOKED
do
  grep -q "$decision" "$DECISIONS" || {
    echo "TEST_FAIL ❌ decision eksik: $decision"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$RULES" "$REASONS" "$DECISIONS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$RULES" "$REASONS" "$DECISIONS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$RULES" "$REASONS" "$DECISIONS"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_BREAK_GLASS_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_READY_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_TEST=PASS ✅"
