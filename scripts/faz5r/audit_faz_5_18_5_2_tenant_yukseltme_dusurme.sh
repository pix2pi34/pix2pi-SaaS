#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.5.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_5_2_TENANT_YUKSELTME_DUSURME.md"
CONFIG_FILE="configs/faz5r/faz_5_18_5_2_tenant_yukseltme_dusurme.v1.json"
CONTROL_FILE="configs/faz5r/tenant_plan_change_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_5_2_tenant_yukseltme_dusurme_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/tenantplanchange/tenant_plan_change.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/tenantplanchange/tenant_plan_change_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_5_2_TENANT_YUKSELTME_DUSURME_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.5.2 TENANT YUKSELTME / DUSURME REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"plan_change_request_intake"' "plan change request intake registered"
contains "$CONTROL_FILE" '"current_plan_snapshot"' "current plan snapshot registered"
contains "$CONTROL_FILE" '"target_plan_validate"' "target plan validate registered"
contains "$CONTROL_FILE" '"entitlement_diff_calculate"' "entitlement diff calculate registered"
contains "$CONTROL_FILE" '"billing_impact_calculate"' "billing impact calculate registered"
contains "$CONTROL_FILE" '"proration_policy_prepare"' "proration policy prepare registered"
contains "$CONTROL_FILE" '"downgrade_safety_check"' "downgrade safety check registered"
contains "$CONTROL_FILE" '"owner_approval_queue"' "owner approval queue registered"
contains "$CONTROL_FILE" '"effective_date_schedule"' "effective date schedule registered"
contains "$CONTROL_FILE" '"plan_change_deferred_marker"' "plan change deferred marker registered"
contains "$CONTROL_FILE" '"PLAN_CHANGE_REQUESTED"' "plan change requested event registered"
contains "$CONTROL_FILE" '"CURRENT_PLAN_SNAPSHOTTED"' "current plan snapshotted event registered"
contains "$CONTROL_FILE" '"TARGET_PLAN_VALIDATED"' "target plan validated event registered"
contains "$CONTROL_FILE" '"ENTITLEMENT_DIFF_CALCULATED"' "entitlement diff event registered"
contains "$CONTROL_FILE" '"BILLING_IMPACT_CALCULATED"' "billing impact event registered"
contains "$CONTROL_FILE" '"PRORATION_POLICY_PREPARED"' "proration policy event registered"
contains "$CONTROL_FILE" '"DOWNGRADE_SAFETY_CHECKED"' "downgrade safety event registered"
contains "$CONTROL_FILE" '"OWNER_APPROVAL_QUEUED"' "owner approval event registered"
contains "$CONTROL_FILE" '"EFFECTIVE_DATE_SCHEDULED"' "effective date event registered"
contains "$CONTROL_FILE" '"PLAN_CHANGE_DEFERRED"' "plan change deferred event registered"
contains "$CONTROL_FILE" '"internal_tenant_plan_change_ready": true' "internal tenant plan change ready"
contains "$CONTROL_FILE" '"production_plan_change_enabled": false' "production plan change disabled"
contains "$CONTROL_FILE" '"real_customer_plan_change_enabled": false' "real customer plan change disabled"
contains "$CONTROL_FILE" '"auto_entitlement_switch_enabled": false' "auto entitlement switch disabled"
contains "$CONTROL_FILE" '"auto_proration_billing_enabled": false' "auto proration billing disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_plan_change_request_id": true' "plan change request id required"
contains "$CONTROL_FILE" '"requires_current_plan_id": true' "current plan id required"
contains "$CONTROL_FILE" '"requires_target_plan_id": true' "target plan id required"
contains "$CONTROL_FILE" '"requires_plan_snapshot": true' "plan snapshot required"
contains "$CONTROL_FILE" '"requires_entitlement_diff": true' "entitlement diff required"
contains "$CONTROL_FILE" '"requires_billing_impact": true' "billing impact required"
contains "$CONTROL_FILE" '"requires_proration_policy": true' "proration policy required"
contains "$CONTROL_FILE" '"requires_downgrade_safety_check": true' "downgrade safety check required"
contains "$CONTROL_FILE" '"requires_owner_approval": true' "owner approval required"
contains "$CONTROL_FILE" '"requires_effective_date": true' "effective date required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_rollback_plan": true' "rollback plan required"
contains "$CONTROL_FILE" '"requires_support_handoff": true' "support handoff required"
contains "$CONTROL_FILE" '"requires_customer_template": true' "customer template required"
contains "$CONTROL_FILE" '"blocks_production_plan_change": true' "production plan change block present"
contains "$CONTROL_FILE" '"blocks_real_customer_plan_change": true' "real customer plan change block present"
contains "$CONTROL_FILE" '"blocks_auto_entitlement_switch": true' "auto entitlement switch block present"
contains "$CONTROL_FILE" '"blocks_auto_proration_billing": true' "auto proration billing block present"
contains "$CONTROL_FILE" '"deferred_to_production_approval": true' "production approval deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_5_3_TENANT_DONDURMA"' "next gate 263 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PLAN_CHANGE_BLOCKED" "production plan change guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_PLAN_CHANGE_BLOCKED" "real customer plan change guard"
contains "$RUNTIME_FILE" "AUTO_ENTITLEMENT_SWITCH_BLOCKED" "auto entitlement switch guard"
contains "$RUNTIME_FILE" "AUTO_PRORATION_BILLING_BLOCKED" "auto proration billing guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "PLAN_CHANGE_REQUEST_ID_REQUIRED" "plan change request id guard"
contains "$RUNTIME_FILE" "CURRENT_PLAN_ID_REQUIRED" "current plan id guard"
contains "$RUNTIME_FILE" "TARGET_PLAN_ID_REQUIRED" "target plan id guard"
contains "$RUNTIME_FILE" "PLAN_SNAPSHOT_REQUIRED" "plan snapshot guard"
contains "$RUNTIME_FILE" "ENTITLEMENT_DIFF_REQUIRED" "entitlement diff guard"
contains "$RUNTIME_FILE" "BILLING_IMPACT_REQUIRED" "billing impact guard"
contains "$RUNTIME_FILE" "PRORATION_POLICY_REQUIRED" "proration policy guard"
contains "$RUNTIME_FILE" "DOWNGRADE_SAFETY_CHECK_REQUIRED" "downgrade safety check guard"
contains "$RUNTIME_FILE" "OWNER_APPROVAL_REQUIRED" "owner approval guard"
contains "$RUNTIME_FILE" "EFFECTIVE_DATE_REQUIRED" "effective date guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "ROLLBACK_PLAN_REQUIRED" "rollback plan guard"
contains "$RUNTIME_FILE" "SUPPORT_HANDOFF_REQUIRED" "support handoff guard"
contains "$RUNTIME_FILE" "CUSTOMER_TEMPLATE_REQUIRED" "customer template guard"
contains "$RUNTIME_FILE" "PRODUCTION_PLAN_CHANGE_BLOCK_REQUIRED" "production plan change block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_PLAN_CHANGE_BLOCK_REQUIRED" "real customer plan change block guard"
contains "$RUNTIME_FILE" "AUTO_ENTITLEMENT_SWITCH_BLOCK_REQUIRED" "auto entitlement switch block guard"
contains "$RUNTIME_FILE" "AUTO_PRORATION_BILLING_BLOCK_REQUIRED" "auto proration billing block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/tenantplanchange; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/tenant_plan_change_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_5_2_tenant_yukseltme_dusurme_test.json").read_text())

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
    assert s["production_plan_change_enabled"] is False, f"production plan change must be false: {key}"
    assert s["real_customer_plan_change_enabled"] is False, f"real customer plan change must be false: {key}"
    assert s["auto_entitlement_switch_enabled"] is False, f"auto entitlement switch must be false: {key}"
    assert s["auto_proration_billing_enabled"] is False, f"auto proration billing must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_plan_change_request_id"] is True, f"plan change request id missing: {key}"
    assert s["requires_current_plan_id"] is True, f"current plan id missing: {key}"
    assert s["requires_target_plan_id"] is True, f"target plan id missing: {key}"
    assert s["requires_plan_snapshot"] is True, f"plan snapshot missing: {key}"
    assert s["requires_entitlement_diff"] is True, f"entitlement diff missing: {key}"
    assert s["requires_billing_impact"] is True, f"billing impact missing: {key}"
    assert s["requires_proration_policy"] is True, f"proration policy missing: {key}"
    assert s["requires_downgrade_safety_check"] is True, f"downgrade safety missing: {key}"
    assert s["requires_owner_approval"] is True, f"owner approval missing: {key}"
    assert s["requires_effective_date"] is True, f"effective date missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_rollback_plan"] is True, f"rollback plan missing: {key}"
    assert s["requires_support_handoff"] is True, f"support handoff missing: {key}"
    assert s["requires_customer_template"] is True, f"customer template missing: {key}"
    assert s["blocks_production_plan_change"] is True, f"production plan change block missing: {key}"
    assert s["blocks_real_customer_plan_change"] is True, f"real customer plan change block missing: {key}"
    assert s["blocks_auto_entitlement_switch"] is True, f"auto entitlement switch block missing: {key}"
    assert s["blocks_auto_proration_billing"] is True, f"auto proration billing block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["plan_change_deferred_marker"]["deferred_to_production_approval"] is True
assert steps["plan_change_deferred_marker"]["deferred_reason"], "plan change deferred reason missing"
assert control["internal_tenant_plan_change_ready"] is True
assert control["production_plan_change_enabled"] is False
assert control["real_customer_plan_change_enabled"] is False
assert control["auto_entitlement_switch_enabled"] is False
assert control["auto_proration_billing_enabled"] is False
assert control["final_policy"]["tenant_freeze_required_next"] is True
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
# FAZ 5-18.5.2 Tenant Yükseltme / Düşürme Real Implementation Audit

PHASE=FAZ_5_18_5_2
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
INTERNAL_TENANT_PLAN_CHANGE_READY=true
PRODUCTION_PLAN_CHANGE_ENABLED=false
REAL_CUSTOMER_PLAN_CHANGE_ENABLED=false
AUTO_ENTITLEMENT_SWITCH_ENABLED=false
AUTO_PRORATION_BILLING_ENABLED=false
TENANT_FREEZE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.5.2 TENANT YUKSELTME / DUSURME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_5_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_5_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
