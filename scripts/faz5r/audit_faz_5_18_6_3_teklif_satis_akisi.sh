#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.6.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_6_3_TEKLIF_SATIS_AKISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_6_3_teklif_satis_akisi.v1.json"
CONTROL_FILE="configs/faz5r/quote_sales_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_6_3_teklif_satis_akisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/quotesalesflow/quote_sales_flow.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/quotesalesflow/quote_sales_flow_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_6_3_TEKLIF_SATIS_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.6.3 TEKLIF / SATIS AKISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"quote_request_intake"' "quote request intake registered"
contains "$CONTROL_FILE" '"crm_stage_verify"' "crm stage verify registered"
contains "$CONTROL_FILE" '"customer_profile_validate"' "customer profile validate registered"
contains "$CONTROL_FILE" '"pricing_snapshot_attach"' "pricing snapshot attach registered"
contains "$CONTROL_FILE" '"discount_approval_queue"' "discount approval queue registered"
contains "$CONTROL_FILE" '"proposal_draft_create"' "proposal draft create registered"
contains "$CONTROL_FILE" '"commercial_terms_review"' "commercial terms review registered"
contains "$CONTROL_FILE" '"quote_approval_record"' "quote approval record registered"
contains "$CONTROL_FILE" '"sales_won_handoff"' "sales won handoff registered"
contains "$CONTROL_FILE" '"sales_ops_report_deferred_marker"' "sales ops report deferred marker registered"
contains "$CONTROL_FILE" '"QUOTE_REQUEST_RECEIVED"' "quote request event registered"
contains "$CONTROL_FILE" '"CRM_STAGE_VERIFIED"' "crm stage event registered"
contains "$CONTROL_FILE" '"CUSTOMER_PROFILE_VALIDATED"' "customer profile event registered"
contains "$CONTROL_FILE" '"PRICING_SNAPSHOT_ATTACHED"' "pricing snapshot event registered"
contains "$CONTROL_FILE" '"DISCOUNT_APPROVAL_QUEUED"' "discount approval event registered"
contains "$CONTROL_FILE" '"PROPOSAL_DRAFT_CREATED"' "proposal draft event registered"
contains "$CONTROL_FILE" '"COMMERCIAL_TERMS_REVIEWED"' "commercial terms event registered"
contains "$CONTROL_FILE" '"QUOTE_APPROVAL_RECORDED"' "quote approval event registered"
contains "$CONTROL_FILE" '"SALES_WON_HANDOFF_READY"' "sales won handoff event registered"
contains "$CONTROL_FILE" '"SALES_OPS_REPORT_DEFERRED"' "sales ops deferred event registered"
contains "$CONTROL_FILE" '"internal_quote_sales_flow_ready": true' "internal quote sales flow ready"
contains "$CONTROL_FILE" '"production_sales_enabled": false' "production sales disabled"
contains "$CONTROL_FILE" '"real_customer_sales_open": false' "real customer sales closed"
contains "$CONTROL_FILE" '"auto_quote_send_enabled": false' "auto quote send disabled"
contains "$CONTROL_FILE" '"auto_contract_activation_enabled": false' "auto contract activation disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_lead_id": true' "lead id required"
contains "$CONTROL_FILE" '"requires_quote_id": true' "quote id required"
contains "$CONTROL_FILE" '"requires_crm_stage": true' "crm stage required"
contains "$CONTROL_FILE" '"requires_customer_profile": true' "customer profile required"
contains "$CONTROL_FILE" '"requires_pricing_snapshot": true' "pricing snapshot required"
contains "$CONTROL_FILE" '"requires_plan_snapshot": true' "plan snapshot required"
contains "$CONTROL_FILE" '"requires_discount_approval": true' "discount approval required"
contains "$CONTROL_FILE" '"requires_commercial_terms": true' "commercial terms required"
contains "$CONTROL_FILE" '"requires_owner_approval": true' "owner approval required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_consent_check": true' "consent check required"
contains "$CONTROL_FILE" '"requires_kvkk_notice": true' "kvkk notice required"
contains "$CONTROL_FILE" '"requires_validity_window": true' "validity window required"
contains "$CONTROL_FILE" '"requires_rollback_path": true' "rollback path required"
contains "$CONTROL_FILE" '"requires_onboarding_handoff": true' "onboarding handoff required"
contains "$CONTROL_FILE" '"blocks_production_sales": true' "production sales block present"
contains "$CONTROL_FILE" '"blocks_real_customer_sales": true' "real customer sales block present"
contains "$CONTROL_FILE" '"blocks_auto_quote_send": true' "auto quote send block present"
contains "$CONTROL_FILE" '"blocks_auto_contract_activation": true' "auto contract activation block present"
contains "$CONTROL_FILE" '"deferred_to_sales_ops_report": true' "sales ops report deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_6_4_SALES_OPS_RAPORU"' "next gate 267 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SALES_BLOCKED" "production sales guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SALES_BLOCKED" "real customer sales guard"
contains "$RUNTIME_FILE" "AUTO_QUOTE_SEND_BLOCKED" "auto quote send guard"
contains "$RUNTIME_FILE" "AUTO_CONTRACT_ACTIVATION_BLOCKED" "auto contract activation guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "LEAD_ID_REQUIRED" "lead id guard"
contains "$RUNTIME_FILE" "QUOTE_ID_REQUIRED" "quote id guard"
contains "$RUNTIME_FILE" "CRM_STAGE_REQUIRED" "crm stage guard"
contains "$RUNTIME_FILE" "CUSTOMER_PROFILE_REQUIRED" "customer profile guard"
contains "$RUNTIME_FILE" "PRICING_SNAPSHOT_REQUIRED" "pricing snapshot guard"
contains "$RUNTIME_FILE" "PLAN_SNAPSHOT_REQUIRED" "plan snapshot guard"
contains "$RUNTIME_FILE" "DISCOUNT_APPROVAL_REQUIRED" "discount approval guard"
contains "$RUNTIME_FILE" "COMMERCIAL_TERMS_REQUIRED" "commercial terms guard"
contains "$RUNTIME_FILE" "OWNER_APPROVAL_REQUIRED" "owner approval guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "CONSENT_CHECK_REQUIRED" "consent check guard"
contains "$RUNTIME_FILE" "KVKK_NOTICE_REQUIRED" "kvkk notice guard"
contains "$RUNTIME_FILE" "VALIDITY_WINDOW_REQUIRED" "validity window guard"
contains "$RUNTIME_FILE" "ROLLBACK_PATH_REQUIRED" "rollback path guard"
contains "$RUNTIME_FILE" "ONBOARDING_HANDOFF_REQUIRED" "onboarding handoff guard"
contains "$RUNTIME_FILE" "PRODUCTION_SALES_BLOCK_REQUIRED" "production sales block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SALES_BLOCK_REQUIRED" "real customer sales block guard"
contains "$RUNTIME_FILE" "AUTO_QUOTE_SEND_BLOCK_REQUIRED" "auto quote send block guard"
contains "$RUNTIME_FILE" "AUTO_CONTRACT_ACTIVATION_BLOCK_REQUIRED" "auto contract activation block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/quotesalesflow; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/quote_sales_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_6_3_teklif_satis_akisi_test.json").read_text())

steps = {s["key"]: s for s in control["steps"]}
events = {s["event"] for s in control["steps"]}

for key in test["must_have_step_keys"]:
    assert key in steps, f"missing step key: {key}"
    s = steps[key]
    assert s["required"] is True, f"step not required: {key}"
    assert s["has_evidence"] is True, f"evidence missing: {key}"
    assert s["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert s["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert s["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert s["production_sales_enabled"] is False, f"production sales must be false: {key}"
    assert s["real_customer_sales_open"] is False, f"real customer sales must be false: {key}"
    assert s["auto_quote_send_enabled"] is False, f"auto quote send must be false: {key}"
    assert s["auto_contract_activation_enabled"] is False, f"auto activation must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_lead_id"] is True, f"lead id missing: {key}"
    assert s["requires_quote_id"] is True, f"quote id missing: {key}"
    assert s["requires_crm_stage"] is True, f"crm stage missing: {key}"
    assert s["requires_customer_profile"] is True, f"customer profile missing: {key}"
    assert s["requires_pricing_snapshot"] is True, f"pricing snapshot missing: {key}"
    assert s["requires_plan_snapshot"] is True, f"plan snapshot missing: {key}"
    assert s["requires_discount_approval"] is True, f"discount approval missing: {key}"
    assert s["requires_commercial_terms"] is True, f"commercial terms missing: {key}"
    assert s["requires_owner_approval"] is True, f"owner approval missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_consent_check"] is True, f"consent check missing: {key}"
    assert s["requires_kvkk_notice"] is True, f"kvkk notice missing: {key}"
    assert s["requires_validity_window"] is True, f"validity window missing: {key}"
    assert s["requires_rollback_path"] is True, f"rollback path missing: {key}"
    assert s["requires_onboarding_handoff"] is True, f"onboarding handoff missing: {key}"
    assert s["blocks_production_sales"] is True, f"production sales block missing: {key}"
    assert s["blocks_real_customer_sales"] is True, f"real customer sales block missing: {key}"
    assert s["blocks_auto_quote_send"] is True, f"auto quote block missing: {key}"
    assert s["blocks_auto_contract_activation"] is True, f"auto activation block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["sales_ops_report_deferred_marker"]["deferred_to_sales_ops_report"] is True
assert steps["sales_ops_report_deferred_marker"]["deferred_reason"], "sales ops deferred reason missing"
assert control["internal_quote_sales_flow_ready"] is True
assert control["production_sales_enabled"] is False
assert control["real_customer_sales_open"] is False
assert control["auto_quote_send_enabled"] is False
assert control["auto_contract_activation_enabled"] is False
assert control["final_policy"]["sales_ops_report_required_next"] is True
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
# FAZ 5-18.6.3 Teklif / Satış Akışı Real Implementation Audit

PHASE=FAZ_5_18_6_3
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
INTERNAL_QUOTE_SALES_FLOW_READY=true
PRODUCTION_SALES_ENABLED=false
REAL_CUSTOMER_SALES_OPEN=false
AUTO_QUOTE_SEND_ENABLED=false
AUTO_CONTRACT_ACTIVATION_ENABLED=false
SALES_OPS_REPORT_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.6.3 TEKLIF / SATIS AKISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_6_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_6_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
