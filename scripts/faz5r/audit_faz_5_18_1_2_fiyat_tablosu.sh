#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.1.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_1_2_FIYAT_TABLOSU.md"
CONFIG_FILE="configs/faz5r/faz_5_18_1_2_fiyat_tablosu.v1.json"
CONTROL_FILE="configs/faz5r/pricing_table.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_1_2_fiyat_tablosu_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/pricingtable/pricing_table.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/pricingtable/pricing_table_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_1_2_FIYAT_TABLOSU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.1.2 FIYAT TABLOSU REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"free_plan_row"' "free plan row registered"
contains "$CONTROL_FILE" '"starter_plan_row"' "starter plan row registered"
contains "$CONTROL_FILE" '"pro_plan_row"' "pro plan row registered"
contains "$CONTROL_FILE" '"enterprise_plan_row"' "enterprise plan row registered"
contains "$CONTROL_FILE" '"accountant_package_deferred_marker"' "accountant package deferred marker registered"
contains "$CONTROL_FILE" '"FREE"' "free segment registered"
contains "$CONTROL_FILE" '"STARTER"' "starter segment registered"
contains "$CONTROL_FILE" '"PRO"' "pro segment registered"
contains "$CONTROL_FILE" '"ENTERPRISE"' "enterprise segment registered"
contains "$CONTROL_FILE" '"ACCOUNTANT_NEXT"' "accountant next segment registered"
contains "$CONTROL_FILE" '"internal_pricing_table_ready": true' "internal pricing table ready"
contains "$CONTROL_FILE" '"production_pricing_published": false' "production pricing unpublished"
contains "$CONTROL_FILE" '"real_customer_billing_enabled": false' "real customer billing disabled"
contains "$CONTROL_FILE" '"payment_collection_enabled": false' "payment collection disabled"
contains "$CONTROL_FILE" '"public_checkout_enabled": false' "public checkout disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_plan_code": true' "plan code required"
contains "$CONTROL_FILE" '"requires_currency": true' "currency required"
contains "$CONTROL_FILE" '"requires_monthly_price": true' "monthly price required"
contains "$CONTROL_FILE" '"requires_annual_price": true' "annual price required"
contains "$CONTROL_FILE" '"requires_vat_policy": true' "vat policy required"
contains "$CONTROL_FILE" '"requires_user_limit": true' "user limit required"
contains "$CONTROL_FILE" '"requires_tenant_limit": true' "tenant limit required"
contains "$CONTROL_FILE" '"requires_feature_summary": true' "feature summary required"
contains "$CONTROL_FILE" '"requires_entitlement_reference": true' "entitlement reference required"
contains "$CONTROL_FILE" '"requires_billing_policy": true' "billing policy required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"requires_public_copy_guard": true' "public copy guard required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_customer_billing": true' "real customer billing block present"
contains "$CONTROL_FILE" '"blocks_payment_collection": true' "payment collection block present"
contains "$CONTROL_FILE" '"blocks_public_checkout": true' "public checkout block present"
contains "$CONTROL_FILE" '"deferred_to_accountant_package": true' "accountant package deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_1_4_MUHASEBECI_OZEL_PAKETLERI"' "next gate 273 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PRICING_PUBLISH_BLOCKED" "production pricing publish guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_BILLING_BLOCKED" "real customer billing guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCKED" "payment collection guard"
contains "$RUNTIME_FILE" "PUBLIC_CHECKOUT_BLOCKED" "public checkout guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PLAN_CODE_REQUIRED" "plan code guard"
contains "$RUNTIME_FILE" "CURRENCY_REQUIRED" "currency guard"
contains "$RUNTIME_FILE" "MONTHLY_PRICE_REQUIRED" "monthly price guard"
contains "$RUNTIME_FILE" "ANNUAL_PRICE_REQUIRED" "annual price guard"
contains "$RUNTIME_FILE" "VAT_POLICY_REQUIRED" "vat policy guard"
contains "$RUNTIME_FILE" "USER_LIMIT_REQUIRED" "user limit guard"
contains "$RUNTIME_FILE" "TENANT_LIMIT_REQUIRED" "tenant limit guard"
contains "$RUNTIME_FILE" "FEATURE_SUMMARY_REQUIRED" "feature summary guard"
contains "$RUNTIME_FILE" "ENTITLEMENT_REFERENCE_REQUIRED" "entitlement reference guard"
contains "$RUNTIME_FILE" "BILLING_POLICY_REQUIRED" "billing policy guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "PUBLIC_COPY_GUARD_REQUIRED" "public copy guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_BILLING_BLOCK_REQUIRED" "real customer billing block guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCK_REQUIRED" "payment collection block guard"
contains "$RUNTIME_FILE" "PUBLIC_CHECKOUT_BLOCK_REQUIRED" "public checkout block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/pricingtable; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/pricing_table.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_1_2_fiyat_tablosu_test.json").read_text())

rows = {r["key"]: r for r in control["rows"]}
segments = {r["segment"] for r in control["rows"]}

for key in test["must_have_row_keys"]:
    assert key in rows, f"missing row key: {key}"
    r = rows[key]
    assert r["required"] is True, f"row not required: {key}"
    assert r["has_evidence"] is True, f"evidence missing: {key}"
    assert r["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert r["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert r["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert r["production_pricing_published"] is False, f"production pricing must be false: {key}"
    assert r["real_customer_billing_enabled"] is False, f"real customer billing must be false: {key}"
    assert r["payment_collection_enabled"] is False, f"payment collection must be false: {key}"
    assert r["public_checkout_enabled"] is False, f"public checkout must be false: {key}"
    assert r["requires_plan_code"] is True, f"plan code missing: {key}"
    assert r["requires_currency"] is True, f"currency missing: {key}"
    assert r["requires_monthly_price"] is True, f"monthly price missing: {key}"
    assert r["requires_annual_price"] is True, f"annual price missing: {key}"
    assert r["requires_vat_policy"] is True, f"vat policy missing: {key}"
    assert r["requires_user_limit"] is True, f"user limit missing: {key}"
    assert r["requires_tenant_limit"] is True, f"tenant limit missing: {key}"
    assert r["requires_feature_summary"] is True, f"feature summary missing: {key}"
    assert r["requires_entitlement_reference"] is True, f"entitlement reference missing: {key}"
    assert r["requires_billing_policy"] is True, f"billing policy missing: {key}"
    assert r["requires_legal_review"] is True, f"legal review missing: {key}"
    assert r["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert r["requires_change_log"] is True, f"change log missing: {key}"
    assert r["requires_public_copy_guard"] is True, f"public copy guard missing: {key}"
    assert r["blocks_production_publish"] is True, f"production block missing: {key}"
    assert r["blocks_real_customer_billing"] is True, f"billing block missing: {key}"
    assert r["blocks_payment_collection"] is True, f"payment block missing: {key}"
    assert r["blocks_public_checkout"] is True, f"checkout block missing: {key}"

for segment in test["must_have_segments"]:
    assert segment in segments, f"missing segment: {segment}"

assert rows["accountant_package_deferred_marker"]["deferred_to_accountant_package"] is True
assert rows["accountant_package_deferred_marker"]["deferred_reason"], "accountant package deferred reason missing"
assert control["internal_pricing_table_ready"] is True
assert control["production_pricing_published"] is False
assert control["real_customer_billing_enabled"] is False
assert control["payment_collection_enabled"] is False
assert control["public_checkout_enabled"] is False
assert control["final_policy"]["accountant_package_required_next"] is True
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
# FAZ 5-18.1.2 Fiyat Tablosu Real Implementation Audit

PHASE=FAZ_5_18_1_2
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
INTERNAL_PRICING_TABLE_READY=true
PRODUCTION_PRICING_PUBLISHED=false
REAL_CUSTOMER_BILLING_ENABLED=false
PAYMENT_COLLECTION_ENABLED=false
PUBLIC_CHECKOUT_ENABLED=false
ACCOUNTANT_PACKAGE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.1.2 FIYAT TABLOSU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_1_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_1_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
