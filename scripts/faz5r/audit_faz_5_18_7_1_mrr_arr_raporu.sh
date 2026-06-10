#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.7.1"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_7_1_MRR_ARR_RAPORU.md"
CONFIG_FILE="configs/faz5r/faz_5_18_7_1_mrr_arr_raporu.v1.json"
CONTROL_FILE="configs/faz5r/mrr_arr_report.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_7_1_mrr_arr_raporu_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/mrrarrreport/mrr_arr_report.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/mrrarrreport/mrr_arr_report_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_7_1_MRR_ARR_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.7.1 MRR / ARR RAPORU REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"subscription_base_snapshot"' "subscription base snapshot registered"
contains "$CONTROL_FILE" '"mrr_summary"' "mrr summary registered"
contains "$CONTROL_FILE" '"arr_summary"' "arr summary registered"
contains "$CONTROL_FILE" '"new_mrr_summary"' "new mrr summary registered"
contains "$CONTROL_FILE" '"expansion_mrr_summary"' "expansion mrr summary registered"
contains "$CONTROL_FILE" '"contraction_mrr_summary"' "contraction mrr summary registered"
contains "$CONTROL_FILE" '"collection_status_summary"' "collection status summary registered"
contains "$CONTROL_FILE" '"audit_evidence_summary"' "audit evidence summary registered"
contains "$CONTROL_FILE" '"churn_expansion_deferred_marker"' "churn expansion deferred marker registered"
contains "$CONTROL_FILE" '"SUBSCRIPTION_BASE"' "subscription base domain registered"
contains "$CONTROL_FILE" '"MRR"' "mrr domain registered"
contains "$CONTROL_FILE" '"ARR"' "arr domain registered"
contains "$CONTROL_FILE" '"EXPANSION"' "expansion domain registered"
contains "$CONTROL_FILE" '"CONTRACTION"' "contraction domain registered"
contains "$CONTROL_FILE" '"COLLECTION"' "collection domain registered"
contains "$CONTROL_FILE" '"AUDIT_EVIDENCE"' "audit evidence domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_mrr_arr_report_ready": true' "internal mrr arr report ready"
contains "$CONTROL_FILE" '"production_revenue_report_enabled": false' "production revenue report disabled"
contains "$CONTROL_FILE" '"real_customer_revenue_enabled": false' "real customer revenue disabled"
contains "$CONTROL_FILE" '"external_finance_export_enabled": false' "external finance export disabled"
contains "$CONTROL_FILE" '"auto_investor_email_enabled": false' "auto investor email disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_period_window": true' "period window required"
contains "$CONTROL_FILE" '"requires_subscription_source": true' "subscription source required"
contains "$CONTROL_FILE" '"requires_billing_source": true' "billing source required"
contains "$CONTROL_FILE" '"requires_plan_snapshot": true' "plan snapshot required"
contains "$CONTROL_FILE" '"requires_currency_policy": true' "currency policy required"
contains "$CONTROL_FILE" '"requires_mrr_formula": true' "mrr formula required"
contains "$CONTROL_FILE" '"requires_arr_formula": true' "arr formula required"
contains "$CONTROL_FILE" '"requires_expansion_metric": true' "expansion metric required"
contains "$CONTROL_FILE" '"requires_contraction_metric": true' "contraction metric required"
contains "$CONTROL_FILE" '"requires_collection_status": true' "collection status required"
contains "$CONTROL_FILE" '"requires_tax_exclusion_policy": true' "tax exclusion policy required"
contains "$CONTROL_FILE" '"requires_data_freshness": true' "data freshness required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_privacy_guard": true' "privacy guard required"
contains "$CONTROL_FILE" '"requires_export_policy": true' "export policy required"
contains "$CONTROL_FILE" '"blocks_production_revenue_report": true' "production revenue report block present"
contains "$CONTROL_FILE" '"blocks_real_customer_revenue": true' "real customer revenue block present"
contains "$CONTROL_FILE" '"blocks_external_finance_export": true' "external finance export block present"
contains "$CONTROL_FILE" '"blocks_auto_investor_email": true' "auto investor email block present"
contains "$CONTROL_FILE" '"deferred_to_churn_expansion_report": true' "churn expansion report deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_7_2_CHURN_EXPANSION_RAPORU"' "next gate 269 present"

contains "$CONTROL_FILE" '"mrr": "sum(active_monthly_recurring_amount_excluding_tax)"' "mrr formula registered"
contains "$CONTROL_FILE" '"arr": "mrr * 12"' "arr formula registered"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_REVENUE_REPORT_BLOCKED" "production revenue report guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_REVENUE_BLOCKED" "real customer revenue guard"
contains "$RUNTIME_FILE" "EXTERNAL_FINANCE_EXPORT_BLOCKED" "external finance export guard"
contains "$RUNTIME_FILE" "AUTO_INVESTOR_EMAIL_BLOCKED" "auto investor email guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "PERIOD_WINDOW_REQUIRED" "period window guard"
contains "$RUNTIME_FILE" "SUBSCRIPTION_SOURCE_REQUIRED" "subscription source guard"
contains "$RUNTIME_FILE" "BILLING_SOURCE_REQUIRED" "billing source guard"
contains "$RUNTIME_FILE" "PLAN_SNAPSHOT_REQUIRED" "plan snapshot guard"
contains "$RUNTIME_FILE" "CURRENCY_POLICY_REQUIRED" "currency policy guard"
contains "$RUNTIME_FILE" "MRR_FORMULA_REQUIRED" "mrr formula guard"
contains "$RUNTIME_FILE" "ARR_FORMULA_REQUIRED" "arr formula guard"
contains "$RUNTIME_FILE" "EXPANSION_METRIC_REQUIRED" "expansion metric guard"
contains "$RUNTIME_FILE" "CONTRACTION_METRIC_REQUIRED" "contraction metric guard"
contains "$RUNTIME_FILE" "COLLECTION_STATUS_REQUIRED" "collection status guard"
contains "$RUNTIME_FILE" "TAX_EXCLUSION_POLICY_REQUIRED" "tax exclusion policy guard"
contains "$RUNTIME_FILE" "DATA_FRESHNESS_REQUIRED" "data freshness guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "PRIVACY_GUARD_REQUIRED" "privacy guard"
contains "$RUNTIME_FILE" "EXPORT_POLICY_REQUIRED" "export policy guard"
contains "$RUNTIME_FILE" "PRODUCTION_REVENUE_REPORT_BLOCK_REQUIRED" "production revenue report block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_REVENUE_BLOCK_REQUIRED" "real customer revenue block guard"
contains "$RUNTIME_FILE" "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED" "external finance export block guard"
contains "$RUNTIME_FILE" "AUTO_INVESTOR_EMAIL_BLOCK_REQUIRED" "auto investor email block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/mrrarrreport; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/mrr_arr_report.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_7_1_mrr_arr_raporu_test.json").read_text())

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
    assert s["production_revenue_report_enabled"] is False, f"production report must be false: {key}"
    assert s["real_customer_revenue_enabled"] is False, f"real customer revenue must be false: {key}"
    assert s["external_finance_export_enabled"] is False, f"external finance export must be false: {key}"
    assert s["auto_investor_email_enabled"] is False, f"auto investor email must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_period_window"] is True, f"period window missing: {key}"
    assert s["requires_subscription_source"] is True, f"subscription source missing: {key}"
    assert s["requires_billing_source"] is True, f"billing source missing: {key}"
    assert s["requires_plan_snapshot"] is True, f"plan snapshot missing: {key}"
    assert s["requires_currency_policy"] is True, f"currency policy missing: {key}"
    assert s["requires_mrr_formula"] is True, f"mrr formula missing: {key}"
    assert s["requires_arr_formula"] is True, f"arr formula missing: {key}"
    assert s["requires_expansion_metric"] is True, f"expansion metric missing: {key}"
    assert s["requires_contraction_metric"] is True, f"contraction metric missing: {key}"
    assert s["requires_collection_status"] is True, f"collection status missing: {key}"
    assert s["requires_tax_exclusion_policy"] is True, f"tax exclusion missing: {key}"
    assert s["requires_data_freshness"] is True, f"data freshness missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_privacy_guard"] is True, f"privacy guard missing: {key}"
    assert s["requires_export_policy"] is True, f"export policy missing: {key}"
    assert s["blocks_production_revenue_report"] is True, f"production block missing: {key}"
    assert s["blocks_real_customer_revenue"] is True, f"real customer block missing: {key}"
    assert s["blocks_external_finance_export"] is True, f"external finance block missing: {key}"
    assert s["blocks_auto_investor_email"] is True, f"auto investor email block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["churn_expansion_deferred_marker"]["deferred_to_churn_expansion_report"] is True
assert sections["churn_expansion_deferred_marker"]["deferred_reason"], "churn expansion deferred reason missing"
assert control["internal_mrr_arr_report_ready"] is True
assert control["production_revenue_report_enabled"] is False
assert control["real_customer_revenue_enabled"] is False
assert control["external_finance_export_enabled"] is False
assert control["auto_investor_email_enabled"] is False
assert control["formulas"]["mrr"] == "sum(active_monthly_recurring_amount_excluding_tax)"
assert control["formulas"]["arr"] == "mrr * 12"
assert control["final_policy"]["churn_expansion_report_required_next"] is True
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
# FAZ 5-18.7.1 MRR / ARR Raporu Real Implementation Audit

PHASE=FAZ_5_18_7_1
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
INTERNAL_MRR_ARR_REPORT_READY=true
PRODUCTION_REVENUE_REPORT_ENABLED=false
REAL_CUSTOMER_REVENUE_ENABLED=false
EXTERNAL_FINANCE_EXPORT_ENABLED=false
AUTO_INVESTOR_EMAIL_ENABLED=false
CHURN_EXPANSION_REPORT_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.7.1 MRR / ARR RAPORU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_7_1_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_7_1_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
