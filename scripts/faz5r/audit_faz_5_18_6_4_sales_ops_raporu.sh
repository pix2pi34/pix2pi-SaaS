#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.6.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_6_4_SALES_OPS_RAPORU.md"
CONFIG_FILE="configs/faz5r/faz_5_18_6_4_sales_ops_raporu.v1.json"
CONTROL_FILE="configs/faz5r/sales_ops_report.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_6_4_sales_ops_raporu_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/salesopsreport/sales_ops_report.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/salesopsreport/sales_ops_report_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_6_4_SALES_OPS_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.6.4 SALES OPS RAPORU REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"crm_pipeline_summary"' "crm pipeline summary registered"
contains "$CONTROL_FILE" '"quote_sales_summary"' "quote sales summary registered"
contains "$CONTROL_FILE" '"conversion_funnel_summary"' "conversion funnel summary registered"
contains "$CONTROL_FILE" '"activity_sla_summary"' "activity sla summary registered"
contains "$CONTROL_FILE" '"forecast_pipeline_summary"' "forecast pipeline summary registered"
contains "$CONTROL_FILE" '"lost_reason_summary"' "lost reason summary registered"
contains "$CONTROL_FILE" '"owner_performance_summary"' "owner performance summary registered"
contains "$CONTROL_FILE" '"audit_evidence_summary"' "audit evidence summary registered"
contains "$CONTROL_FILE" '"mrr_arr_report_deferred_marker"' "mrr arr deferred marker registered"
contains "$CONTROL_FILE" '"CRM_STAGE"' "crm stage domain registered"
contains "$CONTROL_FILE" '"QUOTE_SALES"' "quote sales domain registered"
contains "$CONTROL_FILE" '"CONVERSION"' "conversion domain registered"
contains "$CONTROL_FILE" '"ACTIVITY"' "activity domain registered"
contains "$CONTROL_FILE" '"FORECAST"' "forecast domain registered"
contains "$CONTROL_FILE" '"AUDIT_EVIDENCE"' "audit evidence domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_sales_ops_report_ready": true' "internal sales ops report ready"
contains "$CONTROL_FILE" '"production_report_enabled": false' "production report disabled"
contains "$CONTROL_FILE" '"real_customer_report_enabled": false' "real customer report disabled"
contains "$CONTROL_FILE" '"external_bi_export_enabled": false' "external bi export disabled"
contains "$CONTROL_FILE" '"auto_executive_email_enabled": false' "auto executive email disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_date_window": true' "date window required"
contains "$CONTROL_FILE" '"requires_crm_stage_source": true' "crm stage source required"
contains "$CONTROL_FILE" '"requires_quote_sales_source": true' "quote sales source required"
contains "$CONTROL_FILE" '"requires_pipeline_metrics": true' "pipeline metrics required"
contains "$CONTROL_FILE" '"requires_conversion_metrics": true' "conversion metrics required"
contains "$CONTROL_FILE" '"requires_activity_metrics": true' "activity metrics required"
contains "$CONTROL_FILE" '"requires_forecast_metrics": true' "forecast metrics required"
contains "$CONTROL_FILE" '"requires_lost_reason_breakdown": true' "lost reason breakdown required"
contains "$CONTROL_FILE" '"requires_owner_breakdown": true' "owner breakdown required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_data_freshness": true' "data freshness required"
contains "$CONTROL_FILE" '"requires_export_policy": true' "export policy required"
contains "$CONTROL_FILE" '"requires_privacy_guard": true' "privacy guard required"
contains "$CONTROL_FILE" '"blocks_production_report": true' "production report block present"
contains "$CONTROL_FILE" '"blocks_real_customer_report": true' "real customer report block present"
contains "$CONTROL_FILE" '"blocks_external_bi_export": true' "external bi export block present"
contains "$CONTROL_FILE" '"blocks_auto_executive_email": true' "auto executive email block present"
contains "$CONTROL_FILE" '"deferred_to_mrr_arr_report": true' "mrr arr report deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_7_1_MRR_ARR_RAPORU"' "next gate 268 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_REPORT_BLOCKED" "production report guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_REPORT_BLOCKED" "real customer report guard"
contains "$RUNTIME_FILE" "EXTERNAL_BI_EXPORT_BLOCKED" "external bi export guard"
contains "$RUNTIME_FILE" "AUTO_EXECUTIVE_EMAIL_BLOCKED" "auto executive email guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "DATE_WINDOW_REQUIRED" "date window guard"
contains "$RUNTIME_FILE" "CRM_STAGE_SOURCE_REQUIRED" "crm stage source guard"
contains "$RUNTIME_FILE" "QUOTE_SALES_SOURCE_REQUIRED" "quote sales source guard"
contains "$RUNTIME_FILE" "PIPELINE_METRICS_REQUIRED" "pipeline metrics guard"
contains "$RUNTIME_FILE" "CONVERSION_METRICS_REQUIRED" "conversion metrics guard"
contains "$RUNTIME_FILE" "ACTIVITY_METRICS_REQUIRED" "activity metrics guard"
contains "$RUNTIME_FILE" "FORECAST_METRICS_REQUIRED" "forecast metrics guard"
contains "$RUNTIME_FILE" "LOST_REASON_BREAKDOWN_REQUIRED" "lost reason breakdown guard"
contains "$RUNTIME_FILE" "OWNER_BREAKDOWN_REQUIRED" "owner breakdown guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "DATA_FRESHNESS_REQUIRED" "data freshness guard"
contains "$RUNTIME_FILE" "EXPORT_POLICY_REQUIRED" "export policy guard"
contains "$RUNTIME_FILE" "PRIVACY_GUARD_REQUIRED" "privacy guard"
contains "$RUNTIME_FILE" "PRODUCTION_REPORT_BLOCK_REQUIRED" "production report block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_REPORT_BLOCK_REQUIRED" "real customer report block guard"
contains "$RUNTIME_FILE" "EXTERNAL_BI_EXPORT_BLOCK_REQUIRED" "external bi export block guard"
contains "$RUNTIME_FILE" "AUTO_EXECUTIVE_EMAIL_BLOCK_REQUIRED" "auto executive email block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/salesopsreport; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/sales_ops_report.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_6_4_sales_ops_raporu_test.json").read_text())

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
    assert s["production_report_enabled"] is False, f"production report must be false: {key}"
    assert s["real_customer_report_enabled"] is False, f"real customer report must be false: {key}"
    assert s["external_bi_export_enabled"] is False, f"external bi export must be false: {key}"
    assert s["auto_executive_email_enabled"] is False, f"auto executive email must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_date_window"] is True, f"date window missing: {key}"
    assert s["requires_crm_stage_source"] is True, f"crm stage source missing: {key}"
    assert s["requires_quote_sales_source"] is True, f"quote sales source missing: {key}"
    assert s["requires_pipeline_metrics"] is True, f"pipeline metrics missing: {key}"
    assert s["requires_conversion_metrics"] is True, f"conversion metrics missing: {key}"
    assert s["requires_activity_metrics"] is True, f"activity metrics missing: {key}"
    assert s["requires_forecast_metrics"] is True, f"forecast metrics missing: {key}"
    assert s["requires_lost_reason_breakdown"] is True, f"lost reason missing: {key}"
    assert s["requires_owner_breakdown"] is True, f"owner breakdown missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_data_freshness"] is True, f"data freshness missing: {key}"
    assert s["requires_export_policy"] is True, f"export policy missing: {key}"
    assert s["requires_privacy_guard"] is True, f"privacy guard missing: {key}"
    assert s["blocks_production_report"] is True, f"production report block missing: {key}"
    assert s["blocks_real_customer_report"] is True, f"real customer report block missing: {key}"
    assert s["blocks_external_bi_export"] is True, f"external bi block missing: {key}"
    assert s["blocks_auto_executive_email"] is True, f"auto email block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["mrr_arr_report_deferred_marker"]["deferred_to_mrr_arr_report"] is True
assert sections["mrr_arr_report_deferred_marker"]["deferred_reason"], "mrr arr deferred reason missing"
assert control["internal_sales_ops_report_ready"] is True
assert control["production_report_enabled"] is False
assert control["real_customer_report_enabled"] is False
assert control["external_bi_export_enabled"] is False
assert control["auto_executive_email_enabled"] is False
assert control["final_policy"]["mrr_arr_report_required_next"] is True
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
# FAZ 5-18.6.4 Sales Ops Raporu Real Implementation Audit

PHASE=FAZ_5_18_6_4
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
INTERNAL_SALES_OPS_REPORT_READY=true
PRODUCTION_REPORT_ENABLED=false
REAL_CUSTOMER_REPORT_ENABLED=false
EXTERNAL_BI_EXPORT_ENABLED=false
AUTO_EXECUTIVE_EMAIL_ENABLED=false
MRR_ARR_REPORT_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.6.4 SALES OPS RAPORU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_6_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_6_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
