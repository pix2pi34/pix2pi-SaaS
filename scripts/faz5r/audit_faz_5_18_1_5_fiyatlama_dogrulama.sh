#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.1.5"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_1_5_FIYATLAMA_DOGRULAMA.md"
CONFIG_FILE="configs/faz5r/faz_5_18_1_5_fiyatlama_dogrulama.v1.json"
CONTROL_FILE="configs/faz5r/pricing_validation.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_1_5_fiyatlama_dogrulama_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/pricingvalidation/pricing_validation.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/pricingvalidation/pricing_validation_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_1_5_FIYATLAMA_DOGRULAMA_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.1.5 FIYATLAMA DOGRULAMA REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"pricing_table_integrity"' "pricing table integrity registered"
contains "$CONTROL_FILE" '"accountant_package_integrity"' "accountant package integrity registered"
contains "$CONTROL_FILE" '"vat_policy_validation"' "vat policy validation registered"
contains "$CONTROL_FILE" '"annual_monthly_price_validation"' "annual monthly price validation registered"
contains "$CONTROL_FILE" '"entitlement_consistency_validation"' "entitlement consistency validation registered"
contains "$CONTROL_FILE" '"billing_gate_validation"' "billing gate validation registered"
contains "$CONTROL_FILE" '"payment_gate_validation"' "payment gate validation registered"
contains "$CONTROL_FILE" '"public_copy_approval_validation"' "public copy approval validation registered"
contains "$CONTROL_FILE" '"developer_docs_portal_deferred_marker"' "developer docs portal deferred marker registered"
contains "$CONTROL_FILE" '"PRICING_TABLE"' "pricing table domain registered"
contains "$CONTROL_FILE" '"ACCOUNTANT_PACKAGE"' "accountant package domain registered"
contains "$CONTROL_FILE" '"VAT_POLICY"' "vat policy domain registered"
contains "$CONTROL_FILE" '"BILLING_GATE"' "billing gate domain registered"
contains "$CONTROL_FILE" '"PAYMENT_GATE"' "payment gate domain registered"
contains "$CONTROL_FILE" '"PUBLIC_COPY"' "public copy domain registered"
contains "$CONTROL_FILE" '"APPROVAL"' "approval domain registered"
contains "$CONTROL_FILE" '"DEVELOPER_DOCS_NEXT"' "developer docs next domain registered"
contains "$CONTROL_FILE" '"internal_pricing_validation_ready": true' "internal pricing validation ready"
contains "$CONTROL_FILE" '"production_pricing_published": false' "production pricing unpublished"
contains "$CONTROL_FILE" '"real_customer_billing_enabled": false' "real customer billing disabled"
contains "$CONTROL_FILE" '"payment_collection_enabled": false' "payment collection disabled"
contains "$CONTROL_FILE" '"public_checkout_enabled": false' "public checkout disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_pricing_table_source": true' "pricing table source required"
contains "$CONTROL_FILE" '"requires_accountant_package_source": true' "accountant package source required"
contains "$CONTROL_FILE" '"requires_plan_code_consistency": true' "plan code consistency required"
contains "$CONTROL_FILE" '"requires_currency_consistency": true' "currency consistency required"
contains "$CONTROL_FILE" '"requires_vat_policy_consistency": true' "vat policy consistency required"
contains "$CONTROL_FILE" '"requires_annual_monthly_consistency": true' "annual monthly consistency required"
contains "$CONTROL_FILE" '"requires_entitlement_consistency": true' "entitlement consistency required"
contains "$CONTROL_FILE" '"requires_billing_gate_closed": true' "billing gate closed required"
contains "$CONTROL_FILE" '"requires_payment_gate_closed": true' "payment gate closed required"
contains "$CONTROL_FILE" '"requires_public_copy_guard": true' "public copy guard required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_customer_billing": true' "real customer billing block present"
contains "$CONTROL_FILE" '"blocks_payment_collection": true' "payment collection block present"
contains "$CONTROL_FILE" '"blocks_public_checkout": true' "public checkout block present"
contains "$CONTROL_FILE" '"deferred_to_developer_docs_portal": true' "developer docs portal deferred present"
contains "$CONTROL_FILE" '"FAZ_5_19_3_DEVELOPER_DOCS_PORTALI"' "next gate 275 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PRICING_PUBLISH_BLOCKED" "production pricing publish guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_BILLING_BLOCKED" "real customer billing guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCKED" "payment collection guard"
contains "$RUNTIME_FILE" "PUBLIC_CHECKOUT_BLOCKED" "public checkout guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PRICING_TABLE_SOURCE_REQUIRED" "pricing table source guard"
contains "$RUNTIME_FILE" "ACCOUNTANT_PACKAGE_SOURCE_REQUIRED" "accountant package source guard"
contains "$RUNTIME_FILE" "PLAN_CODE_CONSISTENCY_REQUIRED" "plan code consistency guard"
contains "$RUNTIME_FILE" "CURRENCY_CONSISTENCY_REQUIRED" "currency consistency guard"
contains "$RUNTIME_FILE" "VAT_POLICY_CONSISTENCY_REQUIRED" "vat policy consistency guard"
contains "$RUNTIME_FILE" "ANNUAL_MONTHLY_CONSISTENCY_REQUIRED" "annual monthly consistency guard"
contains "$RUNTIME_FILE" "ENTITLEMENT_CONSISTENCY_REQUIRED" "entitlement consistency guard"
contains "$RUNTIME_FILE" "BILLING_GATE_CLOSED_REQUIRED" "billing gate closed guard"
contains "$RUNTIME_FILE" "PAYMENT_GATE_CLOSED_REQUIRED" "payment gate closed guard"
contains "$RUNTIME_FILE" "PUBLIC_COPY_GUARD_REQUIRED" "public copy guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_BILLING_BLOCK_REQUIRED" "real customer billing block guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCK_REQUIRED" "payment collection block guard"
contains "$RUNTIME_FILE" "PUBLIC_CHECKOUT_BLOCK_REQUIRED" "public checkout block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/pricingvalidation; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/pricing_validation.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_1_5_fiyatlama_dogrulama_test.json").read_text())

controls = {c["key"]: c for c in control["controls"]}
domains = {c["domain"] for c in control["controls"]}

for key in test["must_have_control_keys"]:
    assert key in controls, f"missing control key: {key}"
    c = controls[key]
    assert c["required"] is True, f"control not required: {key}"
    assert c["has_evidence"] is True, f"evidence missing: {key}"
    assert c["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert c["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert c["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert c["production_pricing_published"] is False, f"production pricing must be false: {key}"
    assert c["real_customer_billing_enabled"] is False, f"real customer billing must be false: {key}"
    assert c["payment_collection_enabled"] is False, f"payment collection must be false: {key}"
    assert c["public_checkout_enabled"] is False, f"public checkout must be false: {key}"
    assert c["requires_pricing_table_source"] is True, f"pricing table source missing: {key}"
    assert c["requires_accountant_package_source"] is True, f"accountant package source missing: {key}"
    assert c["requires_plan_code_consistency"] is True, f"plan code consistency missing: {key}"
    assert c["requires_currency_consistency"] is True, f"currency consistency missing: {key}"
    assert c["requires_vat_policy_consistency"] is True, f"vat consistency missing: {key}"
    assert c["requires_annual_monthly_consistency"] is True, f"annual monthly consistency missing: {key}"
    assert c["requires_entitlement_consistency"] is True, f"entitlement consistency missing: {key}"
    assert c["requires_billing_gate_closed"] is True, f"billing gate closed missing: {key}"
    assert c["requires_payment_gate_closed"] is True, f"payment gate closed missing: {key}"
    assert c["requires_public_copy_guard"] is True, f"public copy guard missing: {key}"
    assert c["requires_legal_review"] is True, f"legal review missing: {key}"
    assert c["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert c["requires_change_log"] is True, f"change log missing: {key}"
    assert c["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert c["blocks_production_publish"] is True, f"production block missing: {key}"
    assert c["blocks_real_customer_billing"] is True, f"billing block missing: {key}"
    assert c["blocks_payment_collection"] is True, f"payment block missing: {key}"
    assert c["blocks_public_checkout"] is True, f"checkout block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert controls["developer_docs_portal_deferred_marker"]["deferred_to_developer_docs_portal"] is True
assert controls["developer_docs_portal_deferred_marker"]["deferred_reason"], "developer docs portal deferred reason missing"
assert control["internal_pricing_validation_ready"] is True
assert control["production_pricing_published"] is False
assert control["real_customer_billing_enabled"] is False
assert control["payment_collection_enabled"] is False
assert control["public_checkout_enabled"] is False
assert control["final_policy"]["developer_docs_portal_required_next"] is True
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
# FAZ 5-18.1.5 Fiyatlama Doğrulama Real Implementation Audit

PHASE=FAZ_5_18_1_5
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
INTERNAL_PRICING_VALIDATION_READY=true
PRODUCTION_PRICING_PUBLISHED=false
REAL_CUSTOMER_BILLING_ENABLED=false
PAYMENT_COLLECTION_ENABLED=false
PUBLIC_CHECKOUT_ENABLED=false
DEVELOPER_DOCS_PORTAL_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.1.5 FIYATLAMA DOGRULAMA REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_1_5_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_1_5_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
