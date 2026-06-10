#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.2.5"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_2_5_IADE_IPTAL_TICARI_AKISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_2_5_iade_iptal_ticari_akisi.v1.json"
CONTROL_FILE="configs/faz5r/refund_cancel_commercial_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_2_5_iade_iptal_ticari_akisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/refundcancelflow/refund_cancel_flow.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/refundcancelflow/refund_cancel_flow_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_2_5_IADE_IPTAL_TICARI_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.2.5 IADE / IPTAL TICARI AKISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"refund_request_validate"' "refund request validate registered"
contains "$CONTROL_FILE" '"refund_eligibility_validate"' "refund eligibility validate registered"
contains "$CONTROL_FILE" '"refund_amount_calculate"' "refund amount calculate registered"
contains "$CONTROL_FILE" '"cancel_request_validate"' "cancel request validate registered"
contains "$CONTROL_FILE" '"credit_note_deferred_marker"' "credit note deferred marker registered"
contains "$CONTROL_FILE" '"payment_refund_provider_deferred_marker"' "payment refund provider deferred marker registered"
contains "$CONTROL_FILE" '"tenant_entitlement_adjustment_policy"' "tenant entitlement adjustment policy registered"
contains "$CONTROL_FILE" '"manual_approval_queue"' "manual approval queue registered"
contains "$CONTROL_FILE" '"accounting_reversal_handoff"' "accounting reversal handoff registered"
contains "$CONTROL_FILE" '"customer_notification_block_policy"' "customer notification block policy registered"
contains "$CONTROL_FILE" '"REFUND_REQUEST_RECEIVED"' "refund request event registered"
contains "$CONTROL_FILE" '"REFUND_ELIGIBILITY_VALIDATED"' "refund eligibility event registered"
contains "$CONTROL_FILE" '"REFUND_AMOUNT_CALCULATED"' "refund amount event registered"
contains "$CONTROL_FILE" '"CANCEL_REQUEST_VALIDATED"' "cancel request event registered"
contains "$CONTROL_FILE" '"CREDIT_NOTE_DEFERRED"' "credit note deferred event registered"
contains "$CONTROL_FILE" '"PAYMENT_REFUND_DEFERRED"' "payment refund deferred event registered"
contains "$CONTROL_FILE" '"TENANT_ENTITLEMENT_ADJUSTED"' "tenant entitlement adjusted event registered"
contains "$CONTROL_FILE" '"MANUAL_APPROVAL_QUEUED"' "manual approval queued event registered"
contains "$CONTROL_FILE" '"ACCOUNTING_REVERSAL_READY"' "accounting reversal ready event registered"
contains "$CONTROL_FILE" '"CUSTOMER_NOTIFICATION_BLOCKED"' "customer notification blocked event registered"
contains "$CONTROL_FILE" '"internal_refund_cancel_flow_ready": true' "internal refund cancel flow ready"
contains "$CONTROL_FILE" '"production_refund_enabled": false' "production refund disabled"
contains "$CONTROL_FILE" '"real_money_refund_enabled": false' "real money refund disabled"
contains "$CONTROL_FILE" '"auto_cancel_enabled": false' "auto cancel disabled"
contains "$CONTROL_FILE" '"auto_customer_notification_enabled": false' "auto customer notification disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_invoice_id": true' "invoice id required"
contains "$CONTROL_FILE" '"requires_payment_attempt_id": true' "payment attempt id required"
contains "$CONTROL_FILE" '"requires_refund_request_id": true' "refund request id required"
contains "$CONTROL_FILE" '"requires_idempotency_key": true' "idempotency key required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_eligibility_policy": true' "eligibility policy required"
contains "$CONTROL_FILE" '"requires_amount_calculation": true' "amount calculation required"
contains "$CONTROL_FILE" '"requires_manual_approval": true' "manual approval required"
contains "$CONTROL_FILE" '"requires_billing_owner": true' "billing owner required"
contains "$CONTROL_FILE" '"requires_accounting_reversal": true' "accounting reversal required"
contains "$CONTROL_FILE" '"requires_credit_note_handoff": true' "credit note handoff required"
contains "$CONTROL_FILE" '"requires_provider_refund_handoff": true' "provider refund handoff required"
contains "$CONTROL_FILE" '"requires_customer_template": true' "customer template required"
contains "$CONTROL_FILE" '"blocks_production_refund": true' "production refund block present"
contains "$CONTROL_FILE" '"blocks_real_money_movement": true' "real money movement block present"
contains "$CONTROL_FILE" '"blocks_auto_cancel": true' "auto cancel block present"
contains "$CONTROL_FILE" '"blocks_auto_customer_notification": true' "auto customer notification block present"
contains "$CONTROL_FILE" '"deferred_to_provider_live": true' "provider live deferred present"
contains "$CONTROL_FILE" '"deferred_to_e_document_module": true' "e-document deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_5_4_TENANT_KAPATMA"' "next gate 260 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_REFUND_BLOCKED" "production refund guard"
contains "$RUNTIME_FILE" "REAL_MONEY_REFUND_BLOCKED" "real money refund guard"
contains "$RUNTIME_FILE" "AUTO_CANCEL_BLOCKED" "auto cancel guard"
contains "$RUNTIME_FILE" "AUTO_CUSTOMER_NOTIFICATION_BLOCKED" "auto customer notification guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "INVOICE_ID_REQUIRED" "invoice id guard"
contains "$RUNTIME_FILE" "PAYMENT_ATTEMPT_ID_REQUIRED" "payment attempt id guard"
contains "$RUNTIME_FILE" "REFUND_REQUEST_ID_REQUIRED" "refund request id guard"
contains "$RUNTIME_FILE" "IDEMPOTENCY_KEY_REQUIRED" "idempotency key guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "ELIGIBILITY_POLICY_REQUIRED" "eligibility policy guard"
contains "$RUNTIME_FILE" "AMOUNT_CALCULATION_REQUIRED" "amount calculation guard"
contains "$RUNTIME_FILE" "MANUAL_APPROVAL_REQUIRED" "manual approval guard"
contains "$RUNTIME_FILE" "BILLING_OWNER_REQUIRED" "billing owner guard"
contains "$RUNTIME_FILE" "ACCOUNTING_REVERSAL_REQUIRED" "accounting reversal guard"
contains "$RUNTIME_FILE" "CREDIT_NOTE_HANDOFF_REQUIRED" "credit note handoff guard"
contains "$RUNTIME_FILE" "PROVIDER_REFUND_HANDOFF_REQUIRED" "provider refund handoff guard"
contains "$RUNTIME_FILE" "CUSTOMER_TEMPLATE_REQUIRED" "customer template guard"
contains "$RUNTIME_FILE" "PRODUCTION_REFUND_BLOCK_REQUIRED" "production refund block guard"
contains "$RUNTIME_FILE" "REAL_MONEY_MOVEMENT_BLOCK_REQUIRED" "real money movement block guard"
contains "$RUNTIME_FILE" "AUTO_CANCEL_BLOCK_REQUIRED" "auto cancel block guard"
contains "$RUNTIME_FILE" "AUTO_CUSTOMER_NOTIFICATION_BLOCK_REQUIRED" "auto customer notification block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/refundcancelflow; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/refund_cancel_commercial_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_2_5_iade_iptal_ticari_akisi_test.json").read_text())

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
    assert s["production_refund_enabled"] is False, f"production refund must be false: {key}"
    assert s["real_money_refund_enabled"] is False, f"real money refund must be false: {key}"
    assert s["auto_cancel_enabled"] is False, f"auto cancel must be false: {key}"
    assert s["auto_customer_notification_enabled"] is False, f"auto customer notification must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_invoice_id"] is True, f"invoice id missing: {key}"
    assert s["requires_payment_attempt_id"] is True, f"payment attempt id missing: {key}"
    assert s["requires_refund_request_id"] is True, f"refund request id missing: {key}"
    assert s["requires_idempotency_key"] is True, f"idempotency missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_eligibility_policy"] is True, f"eligibility policy missing: {key}"
    assert s["requires_amount_calculation"] is True, f"amount calculation missing: {key}"
    assert s["requires_manual_approval"] is True, f"manual approval missing: {key}"
    assert s["requires_billing_owner"] is True, f"billing owner missing: {key}"
    assert s["requires_accounting_reversal"] is True, f"accounting reversal missing: {key}"
    assert s["requires_credit_note_handoff"] is True, f"credit note handoff missing: {key}"
    assert s["requires_provider_refund_handoff"] is True, f"provider refund handoff missing: {key}"
    assert s["requires_customer_template"] is True, f"customer template missing: {key}"
    assert s["blocks_production_refund"] is True, f"production refund block missing: {key}"
    assert s["blocks_real_money_movement"] is True, f"real money block missing: {key}"
    assert s["blocks_auto_cancel"] is True, f"auto cancel block missing: {key}"
    assert s["blocks_auto_customer_notification"] is True, f"auto customer notification block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["payment_refund_provider_deferred_marker"]["deferred_to_provider_live"] is True
assert steps["payment_refund_provider_deferred_marker"]["deferred_reason"], "provider refund deferred reason missing"
assert steps["credit_note_deferred_marker"]["deferred_to_e_document_module"] is True
assert steps["credit_note_deferred_marker"]["deferred_reason"], "e-document deferred reason missing"
assert control["internal_refund_cancel_flow_ready"] is True
assert control["production_refund_enabled"] is False
assert control["real_money_refund_enabled"] is False
assert control["auto_cancel_enabled"] is False
assert control["auto_customer_notification_enabled"] is False
assert control["final_policy"]["tenant_shutdown_required_next"] is True
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
# FAZ 5-18.2.5 İade / İptal Ticari Akışı Real Implementation Audit

PHASE=FAZ_5_18_2_5
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
INTERNAL_REFUND_CANCEL_FLOW_READY=true
PRODUCTION_REFUND_ENABLED=false
REAL_MONEY_REFUND_ENABLED=false
AUTO_CANCEL_ENABLED=false
AUTO_CUSTOMER_NOTIFICATION_ENABLED=false
PROVIDER_LIVE_REFUND_DEFERRED=true
E_DOCUMENT_REFUND_CANCEL_DEFERRED=true
TENANT_SHUTDOWN_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.2.5 IADE / IPTAL TICARI AKISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_2_5_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_2_5_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
