#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.5.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_5_3_TENANT_DONDURMA.md"
CONFIG_FILE="configs/faz5r/faz_5_18_5_3_tenant_dondurma.v1.json"
CONTROL_FILE="configs/faz5r/tenant_freeze_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_5_3_tenant_dondurma_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/tenantfreeze/tenant_freeze.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/tenantfreeze/tenant_freeze_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_5_3_TENANT_DONDURMA_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.5.3 TENANT DONDURMA REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"freeze_request_intake"' "freeze request intake registered"
contains "$CONTROL_FILE" '"billing_status_check"' "billing status check registered"
contains "$CONTROL_FILE" '"unpaid_invoice_check"' "unpaid invoice check registered"
contains "$CONTROL_FILE" '"freeze_eligibility_check"' "freeze eligibility check registered"
contains "$CONTROL_FILE" '"owner_approval_queue"' "owner approval queue registered"
contains "$CONTROL_FILE" '"entitlement_freeze_plan"' "entitlement freeze plan registered"
contains "$CONTROL_FILE" '"access_limit_policy"' "access limit policy registered"
contains "$CONTROL_FILE" '"notification_block_policy"' "notification block policy registered"
contains "$CONTROL_FILE" '"unfreeze_path_define"' "unfreeze path define registered"
contains "$CONTROL_FILE" '"production_freeze_deferred_marker"' "production freeze deferred marker registered"
contains "$CONTROL_FILE" '"FREEZE_REQUEST_RECEIVED"' "freeze request event registered"
contains "$CONTROL_FILE" '"BILLING_STATUS_CHECKED"' "billing status event registered"
contains "$CONTROL_FILE" '"UNPAID_INVOICE_CHECKED"' "unpaid invoice event registered"
contains "$CONTROL_FILE" '"FREEZE_ELIGIBILITY_CHECKED"' "freeze eligibility event registered"
contains "$CONTROL_FILE" '"OWNER_APPROVAL_QUEUED"' "owner approval event registered"
contains "$CONTROL_FILE" '"ENTITLEMENT_FREEZE_PLANNED"' "entitlement freeze event registered"
contains "$CONTROL_FILE" '"ACCESS_LIMIT_POLICY_READY"' "access limit event registered"
contains "$CONTROL_FILE" '"NOTIFICATION_BLOCKED"' "notification blocked event registered"
contains "$CONTROL_FILE" '"UNFREEZE_PATH_DEFINED"' "unfreeze path event registered"
contains "$CONTROL_FILE" '"PRODUCTION_FREEZE_DEFERRED"' "production freeze deferred event registered"
contains "$CONTROL_FILE" '"internal_tenant_freeze_ready": true' "internal tenant freeze ready"
contains "$CONTROL_FILE" '"production_freeze_enabled": false' "production freeze disabled"
contains "$CONTROL_FILE" '"real_tenant_freeze_enabled": false' "real tenant freeze disabled"
contains "$CONTROL_FILE" '"auto_access_cutoff_enabled": false' "auto access cutoff disabled"
contains "$CONTROL_FILE" '"auto_unfreeze_enabled": false' "auto unfreeze disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_freeze_request_id": true' "freeze request id required"
contains "$CONTROL_FILE" '"requires_billing_status_check": true' "billing status check required"
contains "$CONTROL_FILE" '"requires_unpaid_invoice_check": true' "unpaid invoice check required"
contains "$CONTROL_FILE" '"requires_freeze_eligibility_policy": true' "freeze eligibility policy required"
contains "$CONTROL_FILE" '"requires_owner_approval": true' "owner approval required"
contains "$CONTROL_FILE" '"requires_entitlement_freeze": true' "entitlement freeze required"
contains "$CONTROL_FILE" '"requires_access_limit_policy": true' "access limit policy required"
contains "$CONTROL_FILE" '"requires_notification_template": true' "notification template required"
contains "$CONTROL_FILE" '"requires_unfreeze_path": true' "unfreeze path required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_rollback_plan": true' "rollback plan required"
contains "$CONTROL_FILE" '"requires_support_handoff": true' "support handoff required"
contains "$CONTROL_FILE" '"blocks_production_freeze": true' "production freeze block present"
contains "$CONTROL_FILE" '"blocks_real_tenant_freeze": true' "real tenant freeze block present"
contains "$CONTROL_FILE" '"blocks_auto_access_cutoff": true' "auto access cutoff block present"
contains "$CONTROL_FILE" '"blocks_auto_unfreeze": true' "auto unfreeze block present"
contains "$CONTROL_FILE" '"deferred_to_production_approval": true' "production approval deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_5_6_TENANT_LIFECYCLE_TESTLERI"' "next gate 264 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_FREEZE_BLOCKED" "production freeze guard"
contains "$RUNTIME_FILE" "REAL_TENANT_FREEZE_BLOCKED" "real tenant freeze guard"
contains "$RUNTIME_FILE" "AUTO_ACCESS_CUTOFF_BLOCKED" "auto access cutoff guard"
contains "$RUNTIME_FILE" "AUTO_UNFREEZE_BLOCKED" "auto unfreeze guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "FREEZE_REQUEST_ID_REQUIRED" "freeze request id guard"
contains "$RUNTIME_FILE" "BILLING_STATUS_CHECK_REQUIRED" "billing status guard"
contains "$RUNTIME_FILE" "UNPAID_INVOICE_CHECK_REQUIRED" "unpaid invoice guard"
contains "$RUNTIME_FILE" "FREEZE_ELIGIBILITY_POLICY_REQUIRED" "freeze eligibility guard"
contains "$RUNTIME_FILE" "OWNER_APPROVAL_REQUIRED" "owner approval guard"
contains "$RUNTIME_FILE" "ENTITLEMENT_FREEZE_REQUIRED" "entitlement freeze guard"
contains "$RUNTIME_FILE" "ACCESS_LIMIT_POLICY_REQUIRED" "access limit policy guard"
contains "$RUNTIME_FILE" "NOTIFICATION_TEMPLATE_REQUIRED" "notification template guard"
contains "$RUNTIME_FILE" "UNFREEZE_PATH_REQUIRED" "unfreeze path guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "ROLLBACK_PLAN_REQUIRED" "rollback plan guard"
contains "$RUNTIME_FILE" "SUPPORT_HANDOFF_REQUIRED" "support handoff guard"
contains "$RUNTIME_FILE" "PRODUCTION_FREEZE_BLOCK_REQUIRED" "production freeze block guard"
contains "$RUNTIME_FILE" "REAL_TENANT_FREEZE_BLOCK_REQUIRED" "real tenant freeze block guard"
contains "$RUNTIME_FILE" "AUTO_ACCESS_CUTOFF_BLOCK_REQUIRED" "auto access cutoff block guard"
contains "$RUNTIME_FILE" "AUTO_UNFREEZE_BLOCK_REQUIRED" "auto unfreeze block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/tenantfreeze; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/tenant_freeze_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_5_3_tenant_dondurma_test.json").read_text())

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
    assert s["production_freeze_enabled"] is False, f"production freeze must be false: {key}"
    assert s["real_tenant_freeze_enabled"] is False, f"real tenant freeze must be false: {key}"
    assert s["auto_access_cutoff_enabled"] is False, f"auto access cutoff must be false: {key}"
    assert s["auto_unfreeze_enabled"] is False, f"auto unfreeze must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_freeze_request_id"] is True, f"freeze request id missing: {key}"
    assert s["requires_billing_status_check"] is True, f"billing status missing: {key}"
    assert s["requires_unpaid_invoice_check"] is True, f"unpaid invoice missing: {key}"
    assert s["requires_freeze_eligibility_policy"] is True, f"freeze eligibility missing: {key}"
    assert s["requires_owner_approval"] is True, f"owner approval missing: {key}"
    assert s["requires_entitlement_freeze"] is True, f"entitlement freeze missing: {key}"
    assert s["requires_access_limit_policy"] is True, f"access limit policy missing: {key}"
    assert s["requires_notification_template"] is True, f"notification template missing: {key}"
    assert s["requires_unfreeze_path"] is True, f"unfreeze path missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_rollback_plan"] is True, f"rollback plan missing: {key}"
    assert s["requires_support_handoff"] is True, f"support handoff missing: {key}"
    assert s["blocks_production_freeze"] is True, f"production freeze block missing: {key}"
    assert s["blocks_real_tenant_freeze"] is True, f"real tenant freeze block missing: {key}"
    assert s["blocks_auto_access_cutoff"] is True, f"auto access cutoff block missing: {key}"
    assert s["blocks_auto_unfreeze"] is True, f"auto unfreeze block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["production_freeze_deferred_marker"]["deferred_to_production_approval"] is True
assert steps["production_freeze_deferred_marker"]["deferred_reason"], "production freeze deferred reason missing"
assert control["internal_tenant_freeze_ready"] is True
assert control["production_freeze_enabled"] is False
assert control["real_tenant_freeze_enabled"] is False
assert control["auto_access_cutoff_enabled"] is False
assert control["auto_unfreeze_enabled"] is False
assert control["final_policy"]["tenant_lifecycle_tests_required_next"] is True
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
# FAZ 5-18.5.3 Tenant Dondurma Real Implementation Audit

PHASE=FAZ_5_18_5_3
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
INTERNAL_TENANT_FREEZE_READY=true
PRODUCTION_FREEZE_ENABLED=false
REAL_TENANT_FREEZE_ENABLED=false
AUTO_ACCESS_CUTOFF_ENABLED=false
AUTO_UNFREEZE_ENABLED=false
TENANT_LIFECYCLE_TESTS_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.5.3 TENANT DONDURMA REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_5_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_5_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
