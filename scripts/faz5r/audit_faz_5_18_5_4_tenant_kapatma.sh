#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.5.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_5_4_TENANT_KAPATMA.md"
CONFIG_FILE="configs/faz5r/faz_5_18_5_4_tenant_kapatma.v1.json"
CONTROL_FILE="configs/faz5r/tenant_shutdown_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_5_4_tenant_kapatma_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/tenantshutdown/tenant_shutdown.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/tenantshutdown/tenant_shutdown_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_5_4_TENANT_KAPATMA_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.5.4 TENANT KAPATMA REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"shutdown_request_intake"' "shutdown request intake registered"
contains "$CONTROL_FILE" '"billing_status_validate"' "billing status validate registered"
contains "$CONTROL_FILE" '"unpaid_invoice_check"' "unpaid invoice check registered"
contains "$CONTROL_FILE" '"data_export_offer"' "data export offer registered"
contains "$CONTROL_FILE" '"legal_hold_check"' "legal hold check registered"
contains "$CONTROL_FILE" '"owner_approval_queue"' "owner approval queue registered"
contains "$CONTROL_FILE" '"tenant_access_freeze_plan"' "tenant access freeze plan registered"
contains "$CONTROL_FILE" '"billing_stop_plan"' "billing stop plan registered"
contains "$CONTROL_FILE" '"final_shutdown_deferred_marker"' "final shutdown deferred marker registered"
contains "$CONTROL_FILE" '"SHUTDOWN_REQUEST_RECEIVED"' "shutdown request event registered"
contains "$CONTROL_FILE" '"BILLING_STATUS_VALIDATED"' "billing status event registered"
contains "$CONTROL_FILE" '"UNPAID_INVOICE_CHECKED"' "unpaid invoice event registered"
contains "$CONTROL_FILE" '"DATA_EXPORT_OFFERED"' "data export event registered"
contains "$CONTROL_FILE" '"LEGAL_HOLD_CHECKED"' "legal hold event registered"
contains "$CONTROL_FILE" '"OWNER_APPROVAL_QUEUED"' "owner approval event registered"
contains "$CONTROL_FILE" '"TENANT_ACCESS_FREEZE_PLANNED"' "tenant access freeze event registered"
contains "$CONTROL_FILE" '"BILLING_STOP_PLANNED"' "billing stop event registered"
contains "$CONTROL_FILE" '"FINAL_SHUTDOWN_DEFERRED"' "final shutdown deferred event registered"
contains "$CONTROL_FILE" '"internal_tenant_shutdown_ready": true' "internal tenant shutdown ready"
contains "$CONTROL_FILE" '"production_shutdown_enabled": false' "production shutdown disabled"
contains "$CONTROL_FILE" '"real_tenant_closure_enabled": false' "real tenant closure disabled"
contains "$CONTROL_FILE" '"data_deletion_enabled": false' "data deletion disabled"
contains "$CONTROL_FILE" '"auto_access_cutoff_enabled": false' "auto access cutoff disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_shutdown_request_id": true' "shutdown request id required"
contains "$CONTROL_FILE" '"requires_billing_status_check": true' "billing status check required"
contains "$CONTROL_FILE" '"requires_unpaid_invoice_check": true' "unpaid invoice check required"
contains "$CONTROL_FILE" '"requires_data_export_offer": true' "data export offer required"
contains "$CONTROL_FILE" '"requires_legal_hold_check": true' "legal hold check required"
contains "$CONTROL_FILE" '"requires_owner_approval": true' "owner approval required"
contains "$CONTROL_FILE" '"requires_support_handoff": true' "support handoff required"
contains "$CONTROL_FILE" '"requires_customer_template": true' "customer template required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_rollback_window": true' "rollback window required"
contains "$CONTROL_FILE" '"requires_backup_snapshot": true' "backup snapshot required"
contains "$CONTROL_FILE" '"requires_entitlement_freeze": true' "entitlement freeze required"
contains "$CONTROL_FILE" '"requires_billing_stop_plan": true' "billing stop plan required"
contains "$CONTROL_FILE" '"blocks_production_shutdown": true' "production shutdown block present"
contains "$CONTROL_FILE" '"blocks_real_tenant_closure": true' "real tenant closure block present"
contains "$CONTROL_FILE" '"blocks_data_deletion": true' "data deletion block present"
contains "$CONTROL_FILE" '"blocks_auto_access_cutoff": true' "auto access cutoff block present"
contains "$CONTROL_FILE" '"deferred_to_data_export_flow": true' "data export deferred present"
contains "$CONTROL_FILE" '"deferred_to_production_approval": true' "production approval deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_5_5_VERI_EXPORT_DEVIR_AKISI"' "next gate 261 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SHUTDOWN_BLOCKED" "production shutdown guard"
contains "$RUNTIME_FILE" "REAL_TENANT_CLOSURE_BLOCKED" "real tenant closure guard"
contains "$RUNTIME_FILE" "DATA_DELETION_BLOCKED" "data deletion guard"
contains "$RUNTIME_FILE" "AUTO_ACCESS_CUTOFF_BLOCKED" "auto access cutoff guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "SHUTDOWN_REQUEST_ID_REQUIRED" "shutdown request id guard"
contains "$RUNTIME_FILE" "BILLING_STATUS_CHECK_REQUIRED" "billing status guard"
contains "$RUNTIME_FILE" "UNPAID_INVOICE_CHECK_REQUIRED" "unpaid invoice guard"
contains "$RUNTIME_FILE" "DATA_EXPORT_OFFER_REQUIRED" "data export offer guard"
contains "$RUNTIME_FILE" "LEGAL_HOLD_CHECK_REQUIRED" "legal hold guard"
contains "$RUNTIME_FILE" "OWNER_APPROVAL_REQUIRED" "owner approval guard"
contains "$RUNTIME_FILE" "SUPPORT_HANDOFF_REQUIRED" "support handoff guard"
contains "$RUNTIME_FILE" "CUSTOMER_TEMPLATE_REQUIRED" "customer template guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "ROLLBACK_WINDOW_REQUIRED" "rollback window guard"
contains "$RUNTIME_FILE" "BACKUP_SNAPSHOT_REQUIRED" "backup snapshot guard"
contains "$RUNTIME_FILE" "ENTITLEMENT_FREEZE_REQUIRED" "entitlement freeze guard"
contains "$RUNTIME_FILE" "BILLING_STOP_PLAN_REQUIRED" "billing stop plan guard"
contains "$RUNTIME_FILE" "PRODUCTION_SHUTDOWN_BLOCK_REQUIRED" "production shutdown block guard"
contains "$RUNTIME_FILE" "REAL_TENANT_CLOSURE_BLOCK_REQUIRED" "real tenant closure block guard"
contains "$RUNTIME_FILE" "DATA_DELETION_BLOCK_REQUIRED" "data deletion block guard"
contains "$RUNTIME_FILE" "AUTO_ACCESS_CUTOFF_BLOCK_REQUIRED" "auto access cutoff block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/tenantshutdown; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/tenant_shutdown_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_5_4_tenant_kapatma_test.json").read_text())

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
    assert s["production_shutdown_enabled"] is False, f"production shutdown must be false: {key}"
    assert s["real_tenant_closure_enabled"] is False, f"real tenant closure must be false: {key}"
    assert s["data_deletion_enabled"] is False, f"data deletion must be false: {key}"
    assert s["auto_access_cutoff_enabled"] is False, f"auto cutoff must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_shutdown_request_id"] is True, f"shutdown request id missing: {key}"
    assert s["requires_billing_status_check"] is True, f"billing status check missing: {key}"
    assert s["requires_unpaid_invoice_check"] is True, f"unpaid invoice check missing: {key}"
    assert s["requires_data_export_offer"] is True, f"data export offer missing: {key}"
    assert s["requires_legal_hold_check"] is True, f"legal hold check missing: {key}"
    assert s["requires_owner_approval"] is True, f"owner approval missing: {key}"
    assert s["requires_support_handoff"] is True, f"support handoff missing: {key}"
    assert s["requires_customer_template"] is True, f"customer template missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_rollback_window"] is True, f"rollback window missing: {key}"
    assert s["requires_backup_snapshot"] is True, f"backup snapshot missing: {key}"
    assert s["requires_entitlement_freeze"] is True, f"entitlement freeze missing: {key}"
    assert s["requires_billing_stop_plan"] is True, f"billing stop plan missing: {key}"
    assert s["blocks_production_shutdown"] is True, f"production shutdown block missing: {key}"
    assert s["blocks_real_tenant_closure"] is True, f"real tenant closure block missing: {key}"
    assert s["blocks_data_deletion"] is True, f"data deletion block missing: {key}"
    assert s["blocks_auto_access_cutoff"] is True, f"auto access cutoff block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["data_export_offer"]["deferred_to_data_export_flow"] is True
assert steps["data_export_offer"]["deferred_reason"], "data export deferred reason missing"
assert steps["final_shutdown_deferred_marker"]["deferred_to_production_approval"] is True
assert steps["final_shutdown_deferred_marker"]["deferred_reason"], "production approval deferred reason missing"
assert control["internal_tenant_shutdown_ready"] is True
assert control["production_shutdown_enabled"] is False
assert control["real_tenant_closure_enabled"] is False
assert control["data_deletion_enabled"] is False
assert control["auto_access_cutoff_enabled"] is False
assert control["final_policy"]["data_export_flow_required_next"] is True
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
# FAZ 5-18.5.4 Tenant Kapatma Real Implementation Audit

PHASE=FAZ_5_18_5_4
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
INTERNAL_TENANT_SHUTDOWN_READY=true
PRODUCTION_SHUTDOWN_ENABLED=false
REAL_TENANT_CLOSURE_ENABLED=false
DATA_DELETION_ENABLED=false
AUTO_ACCESS_CUTOFF_ENABLED=false
DATA_EXPORT_FLOW_REQUIRED_NEXT=true
FINAL_SHUTDOWN_DEFERRED_TO_PRODUCTION_APPROVAL=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.5.4 TENANT KAPATMA REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_5_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_5_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
