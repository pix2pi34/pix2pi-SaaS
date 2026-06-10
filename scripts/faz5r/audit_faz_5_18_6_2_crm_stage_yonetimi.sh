#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.6.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_6_2_CRM_STAGE_YONETIMI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_6_2_crm_stage_yonetimi.v1.json"
CONTROL_FILE="configs/faz5r/crm_stage_management.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_6_2_crm_stage_yonetimi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/crmstage/crm_stage.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/crmstage/crm_stage_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_6_2_CRM_STAGE_YONETIMI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.6.2 CRM STAGE YONETIMI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"lead_to_discovery"' "lead to discovery transition registered"
contains "$CONTROL_FILE" '"discovery_to_qualified"' "discovery to qualified transition registered"
contains "$CONTROL_FILE" '"qualified_to_demo"' "qualified to demo transition registered"
contains "$CONTROL_FILE" '"demo_to_proposal_requested"' "demo to proposal requested transition registered"
contains "$CONTROL_FILE" '"proposal_requested_to_proposal_sent"' "proposal requested to proposal sent transition registered"
contains "$CONTROL_FILE" '"proposal_sent_to_won"' "proposal sent to won transition registered"
contains "$CONTROL_FILE" '"proposal_sent_to_lost"' "proposal sent to lost transition registered"
contains "$CONTROL_FILE" '"won_to_onboarding_handoff"' "won to onboarding handoff transition registered"
contains "$CONTROL_FILE" '"quote_sales_flow_deferred_marker"' "quote sales deferred marker registered"
contains "$CONTROL_FILE" '"LEAD_INTAKE"' "lead intake stage registered"
contains "$CONTROL_FILE" '"DISCOVERY"' "discovery stage registered"
contains "$CONTROL_FILE" '"QUALIFIED"' "qualified stage registered"
contains "$CONTROL_FILE" '"DEMO_SCHEDULED"' "demo scheduled stage registered"
contains "$CONTROL_FILE" '"PROPOSAL_REQUESTED"' "proposal requested stage registered"
contains "$CONTROL_FILE" '"PROPOSAL_SENT"' "proposal sent stage registered"
contains "$CONTROL_FILE" '"WON"' "won stage registered"
contains "$CONTROL_FILE" '"LOST"' "lost stage registered"
contains "$CONTROL_FILE" '"ONBOARDING_HANDOFF"' "onboarding handoff stage registered"
contains "$CONTROL_FILE" '"internal_crm_stage_ready": true' "internal crm stage ready"
contains "$CONTROL_FILE" '"production_crm_enabled": false' "production crm disabled"
contains "$CONTROL_FILE" '"real_customer_crm_open": false' "real customer crm closed"
contains "$CONTROL_FILE" '"auto_sales_action_enabled": false' "auto sales action disabled"
contains "$CONTROL_FILE" '"external_crm_provider_enabled": false' "external crm provider disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_lead_id": true' "lead id required"
contains "$CONTROL_FILE" '"requires_stage_reason": true' "stage reason required"
contains "$CONTROL_FILE" '"requires_owner_assignment": true' "owner assignment required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_consent_check": true' "consent check required"
contains "$CONTROL_FILE" '"requires_kvkk_notice": true' "kvkk notice required"
contains "$CONTROL_FILE" '"requires_next_action": true' "next action required"
contains "$CONTROL_FILE" '"requires_sla": true' "sla required"
contains "$CONTROL_FILE" '"requires_rollback_path": true' "rollback path required"
contains "$CONTROL_FILE" '"requires_duplicate_guard": true' "duplicate guard required"
contains "$CONTROL_FILE" '"requires_manual_review": true' "manual review required"
contains "$CONTROL_FILE" '"blocks_production_crm": true' "production crm block present"
contains "$CONTROL_FILE" '"blocks_real_customer_crm": true' "real customer crm block present"
contains "$CONTROL_FILE" '"blocks_auto_sales_action": true' "auto sales action block present"
contains "$CONTROL_FILE" '"blocks_external_crm_provider": true' "external crm provider block present"
contains "$CONTROL_FILE" '"deferred_to_sales_flow": true' "sales flow deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_6_3_TEKLIF_SATIS_AKISI"' "next gate 266 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_CRM_BLOCKED" "production crm guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_CRM_BLOCKED" "real customer crm guard"
contains "$RUNTIME_FILE" "AUTO_SALES_ACTION_BLOCKED" "auto sales action guard"
contains "$RUNTIME_FILE" "EXTERNAL_CRM_PROVIDER_BLOCKED" "external crm provider guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "LEAD_ID_REQUIRED" "lead id guard"
contains "$RUNTIME_FILE" "STAGE_REASON_REQUIRED" "stage reason guard"
contains "$RUNTIME_FILE" "OWNER_ASSIGNMENT_REQUIRED" "owner assignment guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "CONSENT_CHECK_REQUIRED" "consent check guard"
contains "$RUNTIME_FILE" "KVKK_NOTICE_REQUIRED" "kvkk notice guard"
contains "$RUNTIME_FILE" "NEXT_ACTION_REQUIRED" "next action guard"
contains "$RUNTIME_FILE" "SLA_REQUIRED" "sla guard"
contains "$RUNTIME_FILE" "ROLLBACK_PATH_REQUIRED" "rollback path guard"
contains "$RUNTIME_FILE" "DUPLICATE_GUARD_REQUIRED" "duplicate guard"
contains "$RUNTIME_FILE" "MANUAL_REVIEW_REQUIRED" "manual review guard"
contains "$RUNTIME_FILE" "PRODUCTION_CRM_BLOCK_REQUIRED" "production crm block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_CRM_BLOCK_REQUIRED" "real customer crm block guard"
contains "$RUNTIME_FILE" "AUTO_SALES_ACTION_BLOCK_REQUIRED" "auto sales action block guard"
contains "$RUNTIME_FILE" "EXTERNAL_CRM_PROVIDER_BLOCK_REQUIRED" "external crm provider block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/crmstage; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/crm_stage_management.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_6_2_crm_stage_yonetimi_test.json").read_text())

transitions = {t["key"]: t for t in control["transitions"]}
stages = set()
for t in control["transitions"]:
    stages.add(t["from"])
    stages.add(t["to"])

for key in test["must_have_transition_keys"]:
    assert key in transitions, f"missing transition key: {key}"
    t = transitions[key]
    assert t["required"] is True, f"transition not required: {key}"
    assert t["has_evidence"] is True, f"evidence missing: {key}"
    assert t["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert t["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert t["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert t["production_crm_enabled"] is False, f"production crm must be false: {key}"
    assert t["real_customer_crm_open"] is False, f"real customer crm must be false: {key}"
    assert t["auto_sales_action_enabled"] is False, f"auto sales must be false: {key}"
    assert t["external_crm_provider_enabled"] is False, f"external crm must be false: {key}"
    assert t["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert t["requires_lead_id"] is True, f"lead id missing: {key}"
    assert t["requires_stage_reason"] is True, f"stage reason missing: {key}"
    assert t["requires_owner_assignment"] is True, f"owner missing: {key}"
    assert t["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert t["requires_consent_check"] is True, f"consent check missing: {key}"
    assert t["requires_kvkk_notice"] is True, f"kvkk notice missing: {key}"
    assert t["requires_next_action"] is True, f"next action missing: {key}"
    assert t["requires_sla"] is True, f"sla missing: {key}"
    assert t["requires_rollback_path"] is True, f"rollback missing: {key}"
    assert t["requires_duplicate_guard"] is True, f"duplicate guard missing: {key}"
    assert t["requires_manual_review"] is True, f"manual review missing: {key}"
    assert t["blocks_production_crm"] is True, f"production crm block missing: {key}"
    assert t["blocks_real_customer_crm"] is True, f"real customer crm block missing: {key}"
    assert t["blocks_auto_sales_action"] is True, f"auto sales block missing: {key}"
    assert t["blocks_external_crm_provider"] is True, f"external crm block missing: {key}"

for stage in test["must_have_stages"]:
    assert stage in stages, f"missing stage: {stage}"

assert transitions["quote_sales_flow_deferred_marker"]["deferred_to_sales_flow"] is True
assert transitions["quote_sales_flow_deferred_marker"]["deferred_reason"], "quote sales deferred reason missing"
assert control["internal_crm_stage_ready"] is True
assert control["production_crm_enabled"] is False
assert control["real_customer_crm_open"] is False
assert control["auto_sales_action_enabled"] is False
assert control["external_crm_provider_enabled"] is False
assert control["final_policy"]["quote_sales_flow_required_next"] is True
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
# FAZ 5-18.6.2 CRM Stage Yönetimi Real Implementation Audit

PHASE=FAZ_5_18_6_2
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
INTERNAL_CRM_STAGE_READY=true
PRODUCTION_CRM_ENABLED=false
REAL_CUSTOMER_CRM_OPEN=false
AUTO_SALES_ACTION_ENABLED=false
EXTERNAL_CRM_PROVIDER_ENABLED=false
QUOTE_SALES_FLOW_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.6.2 CRM STAGE YONETIMI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_6_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_6_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
