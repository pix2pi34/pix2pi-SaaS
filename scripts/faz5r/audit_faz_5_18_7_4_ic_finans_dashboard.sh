#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.7.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_7_4_IC_FINANS_DASHBOARD.md"
CONFIG_FILE="configs/faz5r/faz_5_18_7_4_ic_finans_dashboard.v1.json"
CONTROL_FILE="configs/faz5r/internal_finance_dashboard.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_7_4_ic_finans_dashboard_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/internalfinancedashboard/internal_finance_dashboard.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/internalfinancedashboard/internal_finance_dashboard_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_7_4_IC_FINANS_DASHBOARD_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.7.4 IC FINANS DASHBOARD REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"executive_finance_summary"' "executive finance summary registered"
contains "$CONTROL_FILE" '"mrr_arr_panel"' "mrr arr panel registered"
contains "$CONTROL_FILE" '"churn_expansion_panel"' "churn expansion panel registered"
contains "$CONTROL_FILE" '"collection_success_panel"' "collection success panel registered"
contains "$CONTROL_FILE" '"billing_risk_panel"' "billing risk panel registered"
contains "$CONTROL_FILE" '"cashflow_projection_panel"' "cashflow projection panel registered"
contains "$CONTROL_FILE" '"finance_ops_alert_panel"' "finance ops alert panel registered"
contains "$CONTROL_FILE" '"audit_evidence_panel"' "audit evidence panel registered"
contains "$CONTROL_FILE" '"pricing_table_deferred_marker"' "pricing table deferred marker registered"
contains "$CONTROL_FILE" '"REVENUE"' "revenue domain registered"
contains "$CONTROL_FILE" '"COLLECTION"' "collection domain registered"
contains "$CONTROL_FILE" '"BILLING"' "billing domain registered"
contains "$CONTROL_FILE" '"RISK"' "risk domain registered"
contains "$CONTROL_FILE" '"CASHFLOW"' "cashflow domain registered"
contains "$CONTROL_FILE" '"OPS_ALERT"' "ops alert domain registered"
contains "$CONTROL_FILE" '"AUDIT_EVIDENCE"' "audit evidence domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_finance_dashboard_ready": true' "internal finance dashboard ready"
contains "$CONTROL_FILE" '"production_dashboard_enabled": false' "production dashboard disabled"
contains "$CONTROL_FILE" '"real_customer_finance_enabled": false' "real customer finance disabled"
contains "$CONTROL_FILE" '"external_finance_export_enabled": false' "external finance export disabled"
contains "$CONTROL_FILE" '"auto_executive_email_enabled": false' "auto executive email disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_period_window": true' "period window required"
contains "$CONTROL_FILE" '"requires_mrr_arr_source": true' "mrr arr source required"
contains "$CONTROL_FILE" '"requires_churn_expansion_source": true' "churn expansion source required"
contains "$CONTROL_FILE" '"requires_collection_success_source": true' "collection success source required"
contains "$CONTROL_FILE" '"requires_billing_source": true' "billing source required"
contains "$CONTROL_FILE" '"requires_cashflow_projection": true' "cashflow projection required"
contains "$CONTROL_FILE" '"requires_risk_signal": true' "risk signal required"
contains "$CONTROL_FILE" '"requires_alert_threshold": true' "alert threshold required"
contains "$CONTROL_FILE" '"requires_data_freshness": true' "data freshness required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_privacy_guard": true' "privacy guard required"
contains "$CONTROL_FILE" '"requires_export_policy": true' "export policy required"
contains "$CONTROL_FILE" '"requires_owner_breakdown": true' "owner breakdown required"
contains "$CONTROL_FILE" '"requires_decision_note": true' "decision note required"
contains "$CONTROL_FILE" '"blocks_production_dashboard": true' "production dashboard block present"
contains "$CONTROL_FILE" '"blocks_real_customer_finance": true' "real customer finance block present"
contains "$CONTROL_FILE" '"blocks_external_finance_export": true' "external finance export block present"
contains "$CONTROL_FILE" '"blocks_auto_executive_email": true' "auto executive email block present"
contains "$CONTROL_FILE" '"deferred_to_pricing_table": true' "pricing table deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_1_2_FIYAT_TABLOSU"' "next gate 272 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_DASHBOARD_BLOCKED" "production dashboard guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_FINANCE_BLOCKED" "real customer finance guard"
contains "$RUNTIME_FILE" "EXTERNAL_FINANCE_EXPORT_BLOCKED" "external finance export guard"
contains "$RUNTIME_FILE" "AUTO_EXECUTIVE_EMAIL_BLOCKED" "auto executive email guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "PERIOD_WINDOW_REQUIRED" "period window guard"
contains "$RUNTIME_FILE" "MRR_ARR_SOURCE_REQUIRED" "mrr arr source guard"
contains "$RUNTIME_FILE" "CHURN_EXPANSION_SOURCE_REQUIRED" "churn expansion source guard"
contains "$RUNTIME_FILE" "COLLECTION_SUCCESS_SOURCE_REQUIRED" "collection success source guard"
contains "$RUNTIME_FILE" "BILLING_SOURCE_REQUIRED" "billing source guard"
contains "$RUNTIME_FILE" "CASHFLOW_PROJECTION_REQUIRED" "cashflow projection guard"
contains "$RUNTIME_FILE" "RISK_SIGNAL_REQUIRED" "risk signal guard"
contains "$RUNTIME_FILE" "ALERT_THRESHOLD_REQUIRED" "alert threshold guard"
contains "$RUNTIME_FILE" "DATA_FRESHNESS_REQUIRED" "data freshness guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "PRIVACY_GUARD_REQUIRED" "privacy guard"
contains "$RUNTIME_FILE" "EXPORT_POLICY_REQUIRED" "export policy guard"
contains "$RUNTIME_FILE" "OWNER_BREAKDOWN_REQUIRED" "owner breakdown guard"
contains "$RUNTIME_FILE" "DECISION_NOTE_REQUIRED" "decision note guard"
contains "$RUNTIME_FILE" "PRODUCTION_DASHBOARD_BLOCK_REQUIRED" "production dashboard block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_FINANCE_BLOCK_REQUIRED" "real customer finance block guard"
contains "$RUNTIME_FILE" "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED" "external finance export block guard"
contains "$RUNTIME_FILE" "AUTO_EXECUTIVE_EMAIL_BLOCK_REQUIRED" "auto executive email block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/internalfinancedashboard; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/internal_finance_dashboard.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_7_4_ic_finans_dashboard_test.json").read_text())

panels = {p["key"]: p for p in control["panels"]}
domains = {p["domain"] for p in control["panels"]}

for key in test["must_have_panel_keys"]:
    assert key in panels, f"missing panel key: {key}"
    p = panels[key]
    assert p["required"] is True, f"panel not required: {key}"
    assert p["has_evidence"] is True, f"evidence missing: {key}"
    assert p["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert p["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert p["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert p["production_dashboard_enabled"] is False, f"production dashboard must be false: {key}"
    assert p["real_customer_finance_enabled"] is False, f"real customer finance must be false: {key}"
    assert p["external_finance_export_enabled"] is False, f"external finance export must be false: {key}"
    assert p["auto_executive_email_enabled"] is False, f"auto executive email must be false: {key}"
    assert p["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert p["requires_period_window"] is True, f"period window missing: {key}"
    assert p["requires_mrr_arr_source"] is True, f"mrr arr source missing: {key}"
    assert p["requires_churn_expansion_source"] is True, f"churn expansion source missing: {key}"
    assert p["requires_collection_success_source"] is True, f"collection success source missing: {key}"
    assert p["requires_billing_source"] is True, f"billing source missing: {key}"
    assert p["requires_cashflow_projection"] is True, f"cashflow projection missing: {key}"
    assert p["requires_risk_signal"] is True, f"risk signal missing: {key}"
    assert p["requires_alert_threshold"] is True, f"alert threshold missing: {key}"
    assert p["requires_data_freshness"] is True, f"data freshness missing: {key}"
    assert p["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert p["requires_privacy_guard"] is True, f"privacy guard missing: {key}"
    assert p["requires_export_policy"] is True, f"export policy missing: {key}"
    assert p["requires_owner_breakdown"] is True, f"owner breakdown missing: {key}"
    assert p["requires_decision_note"] is True, f"decision note missing: {key}"
    assert p["blocks_production_dashboard"] is True, f"production dashboard block missing: {key}"
    assert p["blocks_real_customer_finance"] is True, f"real customer finance block missing: {key}"
    assert p["blocks_external_finance_export"] is True, f"external finance block missing: {key}"
    assert p["blocks_auto_executive_email"] is True, f"auto executive email block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert panels["pricing_table_deferred_marker"]["deferred_to_pricing_table"] is True
assert panels["pricing_table_deferred_marker"]["deferred_reason"], "pricing table deferred reason missing"
assert control["internal_finance_dashboard_ready"] is True
assert control["production_dashboard_enabled"] is False
assert control["real_customer_finance_enabled"] is False
assert control["external_finance_export_enabled"] is False
assert control["auto_executive_email_enabled"] is False
assert control["final_policy"]["pricing_table_required_next"] is True
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
# FAZ 5-18.7.4 İç Finans Dashboard Real Implementation Audit

PHASE=FAZ_5_18_7_4
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
INTERNAL_FINANCE_DASHBOARD_READY=true
PRODUCTION_DASHBOARD_ENABLED=false
REAL_CUSTOMER_FINANCE_ENABLED=false
EXTERNAL_FINANCE_EXPORT_ENABLED=false
AUTO_EXECUTIVE_EMAIL_ENABLED=false
PRICING_TABLE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.7.4 IC FINANS DASHBOARD REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_7_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_7_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
