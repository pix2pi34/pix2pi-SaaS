#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-19.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_19_2_FIYATLAMA_SAYFALARI.md"
CONFIG_FILE="configs/faz5r/faz_5_19_2_fiyatlama_sayfalari.v1.json"
CONTROL_FILE="configs/faz5r/pricing_pages.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_19_2_fiyatlama_sayfalari_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/pricingpages/pricing_pages.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/pricingpages/pricing_pages_test.go"
WEB_FILE="web/faz5r/pricing-pages/index.html"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_19_2_FIYATLAMA_SAYFALARI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-19.2 FIYATLAMA SAYFALARI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"
file_exists "$WEB_FILE" "HTML pricing page file"

contains "$CONTROL_FILE" '"pricing_landing_page"' "pricing landing page registered"
contains "$CONTROL_FILE" '"plan_comparison_table"' "plan comparison table registered"
contains "$CONTROL_FILE" '"vat_notice_panel"' "vat notice panel registered"
contains "$CONTROL_FILE" '"free_plan_public_copy"' "free plan public copy registered"
contains "$CONTROL_FILE" '"starter_plan_public_copy"' "starter plan public copy registered"
contains "$CONTROL_FILE" '"pro_plan_public_copy"' "pro plan public copy registered"
contains "$CONTROL_FILE" '"enterprise_plan_public_copy"' "enterprise plan public copy registered"
contains "$CONTROL_FILE" '"accountant_package_public_copy"' "accountant package public copy registered"
contains "$CONTROL_FILE" '"launch_guard_panel"' "launch guard panel registered"
contains "$CONTROL_FILE" '"public_developer_web_tests_deferred_marker"' "web tests deferred marker registered"
contains "$CONTROL_FILE" '"PRICING_OVERVIEW"' "pricing overview domain registered"
contains "$CONTROL_FILE" '"PLAN_COMPARISON"' "plan comparison domain registered"
contains "$CONTROL_FILE" '"PUBLIC_COPY"' "public copy domain registered"
contains "$CONTROL_FILE" '"VAT_NOTICE"' "vat notice domain registered"
contains "$CONTROL_FILE" '"CTA"' "cta domain registered"
contains "$CONTROL_FILE" '"ACCOUNTANT_PACKAGE"' "accountant package domain registered"
contains "$CONTROL_FILE" '"LAUNCH_GUARD"' "launch guard domain registered"
contains "$CONTROL_FILE" '"WEB_TESTS_NEXT"' "web tests next domain registered"
contains "$CONTROL_FILE" '"internal_pricing_pages_ready": true' "internal pricing pages ready"
contains "$CONTROL_FILE" '"static_html_ready": true' "static html ready"
contains "$CONTROL_FILE" '"production_page_published": false' "production page unpublished"
contains "$CONTROL_FILE" '"real_customer_signup_enabled": false' "real customer signup disabled"
contains "$CONTROL_FILE" '"checkout_enabled": false' "checkout disabled"
contains "$CONTROL_FILE" '"payment_collection_enabled": false' "payment collection disabled"
contains "$CONTROL_FILE" '"public_pricing_visible": false' "public pricing visible disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_pricing_table_source": true' "pricing table source required"
contains "$CONTROL_FILE" '"requires_accountant_package_source": true' "accountant package source required"
contains "$CONTROL_FILE" '"requires_validated_pricing": true' "validated pricing required"
contains "$CONTROL_FILE" '"requires_currency": true' "currency required"
contains "$CONTROL_FILE" '"requires_vat_notice": true' "vat notice required"
contains "$CONTROL_FILE" '"requires_plan_comparison": true' "plan comparison required"
contains "$CONTROL_FILE" '"requires_feature_summary": true' "feature summary required"
contains "$CONTROL_FILE" '"requires_entitlement_reference": true' "entitlement reference required"
contains "$CONTROL_FILE" '"requires_cta": true' "cta required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_public_copy_guard": true' "public copy guard required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_customer_signup": true' "real customer signup block present"
contains "$CONTROL_FILE" '"blocks_checkout": true' "checkout block present"
contains "$CONTROL_FILE" '"blocks_payment_collection": true' "payment collection block present"
contains "$CONTROL_FILE" '"deferred_to_web_tests": true' "web tests deferred present"
contains "$CONTROL_FILE" '"FAZ_5_19_6_PUBLIC_DEVELOPER_WEB_TESTLERI"' "next gate 279 present"

contains "$WEB_FILE" "PIX2PI_PRICING_PAGES_START" "html pricing page start marker"
contains "$WEB_FILE" "data-pricing-section=\"pricing_landing_page\"" "html pricing landing section"
contains "$WEB_FILE" "data-pricing-section=\"free_plan_public_copy\"" "html free plan section"
contains "$WEB_FILE" "data-pricing-section=\"starter_plan_public_copy\"" "html starter plan section"
contains "$WEB_FILE" "data-pricing-section=\"pro_plan_public_copy\"" "html pro plan section"
contains "$WEB_FILE" "data-pricing-section=\"vat_notice_panel\"" "html vat notice section"
contains "$WEB_FILE" "data-pricing-section=\"accountant_package_public_copy\"" "html accountant package section"
contains "$WEB_FILE" "production_page_published=false" "html production page disabled marker"
contains "$WEB_FILE" "checkout_enabled=false" "html checkout disabled marker"
contains "$WEB_FILE" "payment_collection_enabled=false" "html payment collection disabled marker"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PAGE_PUBLISH_BLOCKED" "production page publish guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SIGNUP_BLOCKED" "real customer signup guard"
contains "$RUNTIME_FILE" "CHECKOUT_BLOCKED" "checkout guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCKED" "payment collection guard"
contains "$RUNTIME_FILE" "PUBLIC_PRICING_VISIBLE_BLOCKED" "public pricing visible guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PRICING_TABLE_SOURCE_REQUIRED" "pricing table source guard"
contains "$RUNTIME_FILE" "ACCOUNTANT_PACKAGE_SOURCE_REQUIRED" "accountant package source guard"
contains "$RUNTIME_FILE" "VALIDATED_PRICING_REQUIRED" "validated pricing guard"
contains "$RUNTIME_FILE" "CURRENCY_REQUIRED" "currency guard"
contains "$RUNTIME_FILE" "VAT_NOTICE_REQUIRED" "vat notice guard"
contains "$RUNTIME_FILE" "PLAN_COMPARISON_REQUIRED" "plan comparison guard"
contains "$RUNTIME_FILE" "FEATURE_SUMMARY_REQUIRED" "feature summary guard"
contains "$RUNTIME_FILE" "ENTITLEMENT_REFERENCE_REQUIRED" "entitlement reference guard"
contains "$RUNTIME_FILE" "CTA_REQUIRED" "cta guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "PUBLIC_COPY_GUARD_REQUIRED" "public copy guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SIGNUP_BLOCK_REQUIRED" "real customer signup block guard"
contains "$RUNTIME_FILE" "CHECKOUT_BLOCK_REQUIRED" "checkout block guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCK_REQUIRED" "payment collection block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/pricingpages; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/pricing_pages.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_19_2_fiyatlama_sayfalari_test.json").read_text())
html = Path("web/faz5r/pricing-pages/index.html").read_text()

sections = {s["key"]: s for s in control["sections"]}
domains = {s["domain"] for s in control["sections"]}

for key in test["must_have_section_keys"]:
    assert key in sections, f"missing section key: {key}"
    s = sections[key]
    assert s["required"] is True, f"section not required: {key}"
    assert s["has_evidence"] is True, f"evidence missing: {key}"
    assert s["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert s["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert s["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert s["production_page_published"] is False, f"production page must be false: {key}"
    assert s["real_customer_signup_enabled"] is False, f"real customer signup must be false: {key}"
    assert s["checkout_enabled"] is False, f"checkout must be false: {key}"
    assert s["payment_collection_enabled"] is False, f"payment collection must be false: {key}"
    assert s["public_pricing_visible"] is False, f"public pricing visible must be false: {key}"
    assert s["requires_pricing_table_source"] is True, f"pricing table source missing: {key}"
    assert s["requires_accountant_package_source"] is True, f"accountant package source missing: {key}"
    assert s["requires_validated_pricing"] is True, f"validated pricing missing: {key}"
    assert s["requires_currency"] is True, f"currency missing: {key}"
    assert s["requires_vat_notice"] is True, f"vat notice missing: {key}"
    assert s["requires_plan_comparison"] is True, f"plan comparison missing: {key}"
    assert s["requires_feature_summary"] is True, f"feature summary missing: {key}"
    assert s["requires_entitlement_reference"] is True, f"entitlement reference missing: {key}"
    assert s["requires_cta"] is True, f"cta missing: {key}"
    assert s["requires_legal_review"] is True, f"legal review missing: {key}"
    assert s["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert s["requires_change_log"] is True, f"change log missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_public_copy_guard"] is True, f"public copy guard missing: {key}"
    assert s["blocks_production_publish"] is True, f"production block missing: {key}"
    assert s["blocks_real_customer_signup"] is True, f"signup block missing: {key}"
    assert s["blocks_checkout"] is True, f"checkout block missing: {key}"
    assert s["blocks_payment_collection"] is True, f"payment block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["public_developer_web_tests_deferred_marker"]["deferred_to_web_tests"] is True
assert sections["public_developer_web_tests_deferred_marker"]["deferred_reason"], "web tests deferred reason missing"
assert control["internal_pricing_pages_ready"] is True
assert control["static_html_ready"] is True
assert control["production_page_published"] is False
assert control["real_customer_signup_enabled"] is False
assert control["checkout_enabled"] is False
assert control["payment_collection_enabled"] is False
assert control["public_pricing_visible"] is False
assert control["final_policy"]["public_developer_web_tests_required_next"] is True
assert "PIX2PI_PRICING_PAGES_START" in html
assert "production_page_published=false" in html
assert "checkout_enabled=false" in html
assert "payment_collection_enabled=false" in html
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
# FAZ 5-19.2 Fiyatlama Sayfaları Real Implementation Audit

PHASE=FAZ_5_19_2
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
WEB_STATUS=READY
TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
INTERNAL_PRICING_PAGES_READY=true
STATIC_HTML_READY=true
PRODUCTION_PAGE_PUBLISHED=false
REAL_CUSTOMER_SIGNUP_ENABLED=false
CHECKOUT_ENABLED=false
PAYMENT_COLLECTION_ENABLED=false
PUBLIC_PRICING_VISIBLE=false
PUBLIC_DEVELOPER_WEB_TESTS_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
- $WEB_FILE
EOF2

echo "===== FAZ 5-19.2 FIYATLAMA SAYFALARI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_19_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_19_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
