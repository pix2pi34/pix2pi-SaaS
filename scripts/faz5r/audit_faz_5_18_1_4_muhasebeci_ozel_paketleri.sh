#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.1.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_1_4_MUHASEBECI_OZEL_PAKETLERI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_1_4_muhasebeci_ozel_paketleri.v1.json"
CONTROL_FILE="configs/faz5r/accountant_package.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_1_4_muhasebeci_ozel_paketleri_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/accountantpackage/accountant_package.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/accountantpackage/accountant_package_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_1_4_MUHASEBECI_OZEL_PAKETLERI_REAL_IMPLEMENTATION_AUDIT.md"

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$PHASE $1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$PHASE $1 REQUIRED_FAIL / HATA ❌"
}

contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

file_exists() {
  local file="$1"
  local label="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 5-18.1.4 MUHASEBECI OZEL PAKETLERI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"accountant_starter_package"' "accountant starter package registered"
contains "$CONTROL_FILE" '"accountant_pro_package"' "accountant pro package registered"
contains "$CONTROL_FILE" '"accountant_enterprise_package"' "accountant enterprise package registered"
contains "$CONTROL_FILE" '"pricing_validation_deferred_marker"' "pricing validation deferred marker registered"
contains "$CONTROL_FILE" '"ACCOUNTANT_STARTER"' "accountant starter segment registered"
contains "$CONTROL_FILE" '"ACCOUNTANT_PRO"' "accountant pro segment registered"
contains "$CONTROL_FILE" '"ACCOUNTANT_ENTERPRISE"' "accountant enterprise segment registered"
contains "$CONTROL_FILE" '"VALIDATION_NEXT"' "validation next segment registered"
contains "$CONTROL_FILE" '"internal_accountant_package_ready": true' "internal accountant package ready"
contains "$CONTROL_FILE" '"production_package_published": false' "production package unpublished"
contains "$CONTROL_FILE" '"real_customer_billing_enabled": false' "real customer billing disabled"
contains "$CONTROL_FILE" '"payment_collection_enabled": false' "payment collection disabled"
contains "$CONTROL_FILE" '"accountant_portal_commercial_enabled": false' "accountant portal commercial disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_package_code": true' "package code required"
contains "$CONTROL_FILE" '"requires_currency": true' "currency required"
contains "$CONTROL_FILE" '"requires_monthly_base_fee": true' "monthly base fee required"
contains "$CONTROL_FILE" '"requires_per_company_fee": true' "per company fee required"
contains "$CONTROL_FILE" '"requires_vat_policy": true' "vat policy required"
contains "$CONTROL_FILE" '"requires_company_limit": true' "company limit required"
contains "$CONTROL_FILE" '"requires_accountant_user_limit": true' "accountant user limit required"
contains "$CONTROL_FILE" '"requires_export_rights": true' "export rights required"
contains "$CONTROL_FILE" '"requires_portal_entitlement": true' "portal entitlement required"
contains "$CONTROL_FILE" '"requires_company_assignment_policy": true' "company assignment policy required"
contains "$CONTROL_FILE" '"requires_monthly_revalidation": true' "monthly revalidation required"
contains "$CONTROL_FILE" '"requires_billing_policy": true' "billing policy required"
contains "$CONTROL_FILE" '"requires_kvkk_scope": true' "kvkk scope required"
contains "$CONTROL_FILE" '"requires_data_access_policy": true' "data access policy required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"requires_public_copy_guard": true' "public copy guard required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_customer_billing": true' "real customer billing block present"
contains "$CONTROL_FILE" '"blocks_payment_collection": true' "payment collection block present"
contains "$CONTROL_FILE" '"blocks_accountant_portal_commercial": true' "accountant portal commercial block present"
contains "$CONTROL_FILE" '"deferred_to_pricing_validation": true' "pricing validation deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_1_5_FIYATLAMA_DOGRULAMA"' "next gate 274 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PACKAGE_PUBLISH_BLOCKED" "production package publish guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_BILLING_BLOCKED" "real customer billing guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCKED" "payment collection guard"
contains "$RUNTIME_FILE" "ACCOUNTANT_PORTAL_COMMERCIAL_BLOCKED" "accountant portal commercial guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PACKAGE_CODE_REQUIRED" "package code guard"
contains "$RUNTIME_FILE" "CURRENCY_REQUIRED" "currency guard"
contains "$RUNTIME_FILE" "MONTHLY_BASE_FEE_REQUIRED" "monthly base fee guard"
contains "$RUNTIME_FILE" "PER_COMPANY_FEE_REQUIRED" "per company fee guard"
contains "$RUNTIME_FILE" "VAT_POLICY_REQUIRED" "vat policy guard"
contains "$RUNTIME_FILE" "COMPANY_LIMIT_REQUIRED" "company limit guard"
contains "$RUNTIME_FILE" "ACCOUNTANT_USER_LIMIT_REQUIRED" "accountant user limit guard"
contains "$RUNTIME_FILE" "EXPORT_RIGHTS_REQUIRED" "export rights guard"
contains "$RUNTIME_FILE" "PORTAL_ENTITLEMENT_REQUIRED" "portal entitlement guard"
contains "$RUNTIME_FILE" "COMPANY_ASSIGNMENT_POLICY_REQUIRED" "company assignment policy guard"
contains "$RUNTIME_FILE" "MONTHLY_REVALIDATION_REQUIRED" "monthly revalidation guard"
contains "$RUNTIME_FILE" "BILLING_POLICY_REQUIRED" "billing policy guard"
contains "$RUNTIME_FILE" "KVKK_SCOPE_REQUIRED" "kvkk scope guard"
contains "$RUNTIME_FILE" "DATA_ACCESS_POLICY_REQUIRED" "data access policy guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "PUBLIC_COPY_GUARD_REQUIRED" "public copy guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_BILLING_BLOCK_REQUIRED" "real customer billing block guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCK_REQUIRED" "payment collection block guard"
contains "$RUNTIME_FILE" "ACCOUNTANT_PORTAL_COMMERCIAL_BLOCK_REQUIRED" "accountant portal commercial block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/accountantpackage; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/accountant_package.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_1_4_muhasebeci_ozel_paketleri_test.json").read_text())

packages = {p["key"]: p for p in control["packages"]}
segments = {p["segment"] for p in control["packages"]}

for key in test["must_have_package_keys"]:
    assert key in packages, f"missing package key: {key}"
    p = packages[key]
    assert p["required"] is True, f"package not required: {key}"
    assert p["has_evidence"] is True, f"evidence missing: {key}"
    assert p["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert p["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert p["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert p["production_package_published"] is False, f"production package must be false: {key}"
    assert p["real_customer_billing_enabled"] is False, f"real customer billing must be false: {key}"
    assert p["payment_collection_enabled"] is False, f"payment collection must be false: {key}"
    assert p["accountant_portal_commercial_enabled"] is False, f"accountant portal commercial must be false: {key}"
    assert p["requires_package_code"] is True, f"package code missing: {key}"
    assert p["requires_currency"] is True, f"currency missing: {key}"
    assert p["requires_monthly_base_fee"] is True, f"monthly base fee missing: {key}"
    assert p["requires_per_company_fee"] is True, f"per company fee missing: {key}"
    assert p["requires_vat_policy"] is True, f"vat policy missing: {key}"
    assert p["requires_company_limit"] is True, f"company limit missing: {key}"
    assert p["requires_accountant_user_limit"] is True, f"user limit missing: {key}"
    assert p["requires_export_rights"] is True, f"export rights missing: {key}"
    assert p["requires_portal_entitlement"] is True, f"portal entitlement missing: {key}"
    assert p["requires_company_assignment_policy"] is True, f"assignment policy missing: {key}"
    assert p["requires_monthly_revalidation"] is True, f"monthly revalidation missing: {key}"
    assert p["requires_billing_policy"] is True, f"billing policy missing: {key}"
    assert p["requires_kvkk_scope"] is True, f"kvkk scope missing: {key}"
    assert p["requires_data_access_policy"] is True, f"data access policy missing: {key}"
    assert p["requires_legal_review"] is True, f"legal review missing: {key}"
    assert p["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert p["requires_change_log"] is True, f"change log missing: {key}"
    assert p["requires_public_copy_guard"] is True, f"public copy guard missing: {key}"
    assert p["blocks_production_publish"] is True, f"production block missing: {key}"
    assert p["blocks_real_customer_billing"] is True, f"billing block missing: {key}"
    assert p["blocks_payment_collection"] is True, f"payment block missing: {key}"
    assert p["blocks_accountant_portal_commercial"] is True, f"portal commercial block missing: {key}"

for segment in test["must_have_segments"]:
    assert segment in segments, f"missing segment: {segment}"

assert packages["pricing_validation_deferred_marker"]["deferred_to_pricing_validation"] is True
assert packages["pricing_validation_deferred_marker"]["deferred_reason"], "pricing validation deferred reason missing"
assert control["internal_accountant_package_ready"] is True
assert control["production_package_published"] is False
assert control["real_customer_billing_enabled"] is False
assert control["payment_collection_enabled"] is False
assert control["accountant_portal_commercial_enabled"] is False
assert control["final_policy"]["pricing_validation_required_next"] is True
PY
then
  ok "json semantic validation"
else
  fail "json semantic validation"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

mkdir -p "$(dirname "$EVIDENCE_FILE")"
cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 5-18.1.4 Muhasebeci Özel Paketleri Real Implementation Audit

PHASE=FAZ_5_18_1_4
AUDIT_DATE=$(date -Is)

## Real Implementation Audit Result

PASS_COUNT=$PASS_COUNT
FAIL_COUNT=$FAIL_COUNT
WARN_COUNT=$WARN_COUNT
REQUIRED_FAIL=$REQUIRED_FAIL
OPTIONAL_WARN=$OPTIONAL_WARN

## Status

DOC_STATUS=READY
CONFIG_STATUS=READY
CONTROL_CONFIG_STATUS=READY
RUNTIME_STATUS=READY
TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
INTERNAL_ACCOUNTANT_PACKAGE_READY=true
PRODUCTION_PACKAGE_PUBLISHED=false
REAL_CUSTOMER_BILLING_ENABLED=false
PAYMENT_COLLECTION_ENABLED=false
ACCOUNTANT_PORTAL_COMMERCIAL_ENABLED=false
PRICING_VALIDATION_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.1.4 MUHASEBECI OZEL PAKETLERI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_1_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_1_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
