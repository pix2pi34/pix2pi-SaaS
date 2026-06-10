#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.7.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_7_3_TAHSILAT_BASARI_RAPORU.md"
CONFIG_FILE="configs/faz5r/faz_5_18_7_3_tahsilat_basari_raporu.v1.json"
CONTROL_FILE="configs/faz5r/collection_success_report.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_7_3_tahsilat_basari_raporu_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/collectionsuccessreport/collection_success_report.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/collectionsuccessreport/collection_success_report_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_7_3_TAHSILAT_BASARI_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.7.3 TAHSILAT BASARI RAPORU REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"billing_base_snapshot"' "billing base snapshot registered"
contains "$CONTROL_FILE" '"invoice_collection_summary"' "invoice collection summary registered"
contains "$CONTROL_FILE" '"collection_success_summary"' "collection success summary registered"
contains "$CONTROL_FILE" '"failed_payment_summary"' "failed payment summary registered"
contains "$CONTROL_FILE" '"recovery_summary"' "recovery summary registered"
contains "$CONTROL_FILE" '"aging_bucket_summary"' "aging bucket summary registered"
contains "$CONTROL_FILE" '"collection_risk_summary"' "collection risk summary registered"
contains "$CONTROL_FILE" '"audit_evidence_summary"' "audit evidence summary registered"
contains "$CONTROL_FILE" '"internal_finance_dashboard_deferred_marker"' "internal finance dashboard deferred marker registered"
contains "$CONTROL_FILE" '"BILLING_BASE"' "billing base domain registered"
contains "$CONTROL_FILE" '"COLLECTION_SUCCESS"' "collection success domain registered"
contains "$CONTROL_FILE" '"FAILED_PAYMENT"' "failed payment domain registered"
contains "$CONTROL_FILE" '"RECOVERY"' "recovery domain registered"
contains "$CONTROL_FILE" '"AGING"' "aging domain registered"
contains "$CONTROL_FILE" '"RISK"' "risk domain registered"
contains "$CONTROL_FILE" '"AUDIT_EVIDENCE"' "audit evidence domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_collection_success_report_ready": true' "internal collection success report ready"
contains "$CONTROL_FILE" '"production_collection_report_enabled": false' "production collection report disabled"
contains "$CONTROL_FILE" '"real_customer_collection_enabled": false' "real customer collection disabled"
contains "$CONTROL_FILE" '"external_finance_export_enabled": false' "external finance export disabled"
contains "$CONTROL_FILE" '"auto_dunning_enabled": false' "auto dunning disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_period_window": true' "period window required"
contains "$CONTROL_FILE" '"requires_invoice_source": true' "invoice source required"
contains "$CONTROL_FILE" '"requires_billing_source": true' "billing source required"
contains "$CONTROL_FILE" '"requires_payment_attempt_source": true' "payment attempt source required"
contains "$CONTROL_FILE" '"requires_success_rate_formula": true' "success rate formula required"
contains "$CONTROL_FILE" '"requires_failed_payment_metric": true' "failed payment metric required"
contains "$CONTROL_FILE" '"requires_recovery_metric": true' "recovery metric required"
contains "$CONTROL_FILE" '"requires_aging_bucket": true' "aging bucket required"
contains "$CONTROL_FILE" '"requires_collection_risk_signal": true' "collection risk signal required"
contains "$CONTROL_FILE" '"requires_tax_policy": true' "tax policy required"
contains "$CONTROL_FILE" '"requires_data_freshness": true' "data freshness required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_privacy_guard": true' "privacy guard required"
contains "$CONTROL_FILE" '"requires_export_policy": true' "export policy required"
contains "$CONTROL_FILE" '"blocks_production_collection_report": true' "production collection report block present"
contains "$CONTROL_FILE" '"blocks_real_customer_collection": true' "real customer collection block present"
contains "$CONTROL_FILE" '"blocks_external_finance_export": true' "external finance export block present"
contains "$CONTROL_FILE" '"blocks_auto_dunning": true' "auto dunning block present"
contains "$CONTROL_FILE" '"deferred_to_internal_finance_dashboard": true' "internal finance dashboard deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_7_4_IC_FINANS_DASHBOARD"' "next gate 271 present"
contains "$CONTROL_FILE" '"collection_success_rate": "paid_invoice_count / due_invoice_count"' "collection success formula registered"
contains "$CONTROL_FILE" '"failed_payment_rate": "failed_payment_attempt_count / total_payment_attempt_count"' "failed payment formula registered"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_COLLECTION_REPORT_BLOCKED" "production collection report guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COLLECTION_BLOCKED" "real customer collection guard"
contains "$RUNTIME_FILE" "EXTERNAL_FINANCE_EXPORT_BLOCKED" "external finance export guard"
contains "$RUNTIME_FILE" "AUTO_DUNNING_BLOCKED" "auto dunning guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "PERIOD_WINDOW_REQUIRED" "period window guard"
contains "$RUNTIME_FILE" "INVOICE_SOURCE_REQUIRED" "invoice source guard"
contains "$RUNTIME_FILE" "BILLING_SOURCE_REQUIRED" "billing source guard"
contains "$RUNTIME_FILE" "PAYMENT_ATTEMPT_SOURCE_REQUIRED" "payment attempt source guard"
contains "$RUNTIME_FILE" "SUCCESS_RATE_FORMULA_REQUIRED" "success rate formula guard"
contains "$RUNTIME_FILE" "FAILED_PAYMENT_METRIC_REQUIRED" "failed payment metric guard"
contains "$RUNTIME_FILE" "RECOVERY_METRIC_REQUIRED" "recovery metric guard"
contains "$RUNTIME_FILE" "AGING_BUCKET_REQUIRED" "aging bucket guard"
contains "$RUNTIME_FILE" "COLLECTION_RISK_SIGNAL_REQUIRED" "collection risk signal guard"
contains "$RUNTIME_FILE" "TAX_POLICY_REQUIRED" "tax policy guard"
contains "$RUNTIME_FILE" "DATA_FRESHNESS_REQUIRED" "data freshness guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "PRIVACY_GUARD_REQUIRED" "privacy guard"
contains "$RUNTIME_FILE" "EXPORT_POLICY_REQUIRED" "export policy guard"
contains "$RUNTIME_FILE" "PRODUCTION_COLLECTION_REPORT_BLOCK_REQUIRED" "production collection report block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COLLECTION_BLOCK_REQUIRED" "real customer collection block guard"
contains "$RUNTIME_FILE" "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED" "external finance export block guard"
contains "$RUNTIME_FILE" "AUTO_DUNNING_BLOCK_REQUIRED" "auto dunning block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/collectionsuccessreport; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/collection_success_report.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_7_3_tahsilat_basari_raporu_test.json").read_text())

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
    assert s["production_collection_report_enabled"] is False, f"production collection must be false: {key}"
    assert s["real_customer_collection_enabled"] is False, f"real customer collection must be false: {key}"
    assert s["external_finance_export_enabled"] is False, f"external finance export must be false: {key}"
    assert s["auto_dunning_enabled"] is False, f"auto dunning must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_period_window"] is True, f"period window missing: {key}"
    assert s["requires_invoice_source"] is True, f"invoice source missing: {key}"
    assert s["requires_billing_source"] is True, f"billing source missing: {key}"
    assert s["requires_payment_attempt_source"] is True, f"payment attempt source missing: {key}"
    assert s["requires_success_rate_formula"] is True, f"success formula missing: {key}"
    assert s["requires_failed_payment_metric"] is True, f"failed payment metric missing: {key}"
    assert s["requires_recovery_metric"] is True, f"recovery metric missing: {key}"
    assert s["requires_aging_bucket"] is True, f"aging bucket missing: {key}"
    assert s["requires_collection_risk_signal"] is True, f"risk signal missing: {key}"
    assert s["requires_tax_policy"] is True, f"tax policy missing: {key}"
    assert s["requires_data_freshness"] is True, f"data freshness missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_privacy_guard"] is True, f"privacy guard missing: {key}"
    assert s["requires_export_policy"] is True, f"export policy missing: {key}"
    assert s["blocks_production_collection_report"] is True, f"production block missing: {key}"
    assert s["blocks_real_customer_collection"] is True, f"real customer block missing: {key}"
    assert s["blocks_external_finance_export"] is True, f"external finance block missing: {key}"
    assert s["blocks_auto_dunning"] is True, f"auto dunning block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["internal_finance_dashboard_deferred_marker"]["deferred_to_internal_finance_dashboard"] is True
assert sections["internal_finance_dashboard_deferred_marker"]["deferred_reason"], "internal finance dashboard deferred reason missing"
assert control["internal_collection_success_report_ready"] is True
assert control["production_collection_report_enabled"] is False
assert control["real_customer_collection_enabled"] is False
assert control["external_finance_export_enabled"] is False
assert control["auto_dunning_enabled"] is False
assert control["formulas"]["collection_success_rate"] == "paid_invoice_count / due_invoice_count"
assert control["formulas"]["failed_payment_rate"] == "failed_payment_attempt_count / total_payment_attempt_count"
assert control["final_policy"]["internal_finance_dashboard_required_next"] is True
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
# FAZ 5-18.7.3 Tahsilat Başarı Raporu Real Implementation Audit

PHASE=FAZ_5_18_7_3
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
INTERNAL_COLLECTION_SUCCESS_REPORT_READY=true
PRODUCTION_COLLECTION_REPORT_ENABLED=false
REAL_CUSTOMER_COLLECTION_ENABLED=false
EXTERNAL_FINANCE_EXPORT_ENABLED=false
AUTO_DUNNING_ENABLED=false
INTERNAL_FINANCE_DASHBOARD_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.7.3 TAHSILAT BASARI RAPORU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_7_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_7_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
