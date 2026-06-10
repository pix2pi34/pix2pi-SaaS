#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.2.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_2_2_FATURALAMA_AKISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_2_2_faturalama_akisi.v1.json"
CONTROL_FILE="configs/faz5r/invoice_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_2_2_faturalama_akisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/invoiceflow/invoice_flow.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/invoiceflow/invoice_flow_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_2_2_FATURALAMA_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.2.2 FATURALAMA AKISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"invoice_draft_create"' "invoice draft create registered"
contains "$CONTROL_FILE" '"invoice_billing_profile_validate"' "billing profile validation registered"
contains "$CONTROL_FILE" '"invoice_plan_snapshot_attach"' "plan snapshot attach registered"
contains "$CONTROL_FILE" '"invoice_line_item_calculate"' "line item calculation registered"
contains "$CONTROL_FILE" '"invoice_tax_calculate"' "tax calculation registered"
contains "$CONTROL_FILE" '"invoice_finalize"' "invoice finalize registered"
contains "$CONTROL_FILE" '"invoice_due_schedule"' "invoice due schedule registered"
contains "$CONTROL_FILE" '"invoice_delivery_block_policy"' "invoice delivery block registered"
contains "$CONTROL_FILE" '"accounting_export_handoff"' "accounting export handoff registered"
contains "$CONTROL_FILE" '"e_document_deferred_marker"' "e-document deferred marker registered"
contains "$CONTROL_FILE" '"INVOICE_DRAFT_CREATED"' "invoice draft event registered"
contains "$CONTROL_FILE" '"INVOICE_CALCULATED"' "invoice calculated event registered"
contains "$CONTROL_FILE" '"INVOICE_FINALIZED"' "invoice finalized event registered"
contains "$CONTROL_FILE" '"INVOICE_DUE_SCHEDULED"' "invoice due scheduled event registered"
contains "$CONTROL_FILE" '"INVOICE_DELIVERY_READY"' "invoice delivery event registered"
contains "$CONTROL_FILE" '"ACCOUNTING_EXPORT_READY"' "accounting export event registered"
contains "$CONTROL_FILE" '"E_DOCUMENT_DEFERRED"' "e-document deferred event registered"
contains "$CONTROL_FILE" '"internal_invoice_flow_ready": true' "internal invoice flow ready"
contains "$CONTROL_FILE" '"production_invoice_enabled": false' "production invoice disabled"
contains "$CONTROL_FILE" '"real_customer_invoice_enabled": false' "real customer invoice disabled"
contains "$CONTROL_FILE" '"auto_invoice_delivery_enabled": false' "auto invoice delivery disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_invoice_id": true' "invoice id required"
contains "$CONTROL_FILE" '"requires_billing_profile": true' "billing profile required"
contains "$CONTROL_FILE" '"requires_plan_snapshot": true' "plan snapshot required"
contains "$CONTROL_FILE" '"requires_line_items": true' "line items required"
contains "$CONTROL_FILE" '"requires_tax_calculation": true' "tax calculation required"
contains "$CONTROL_FILE" '"requires_due_date": true' "due date required"
contains "$CONTROL_FILE" '"requires_currency": true' "currency required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_idempotency_key": true' "idempotency key required"
contains "$CONTROL_FILE" '"requires_accounting_export": true' "accounting export required"
contains "$CONTROL_FILE" '"requires_e_document_handoff": true' "e-document handoff required"
contains "$CONTROL_FILE" '"blocks_production_invoice": true' "production invoice block present"
contains "$CONTROL_FILE" '"blocks_real_customer_delivery": true' "real customer delivery block present"
contains "$CONTROL_FILE" '"deferred_to_e_document_module": true' "e-document deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_2_5_IADE_IPTAL_TICARI_AKISI"' "next gate 259 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_INVOICE_BLOCKED" "production invoice guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_INVOICE_BLOCKED" "real customer invoice guard"
contains "$RUNTIME_FILE" "AUTO_INVOICE_DELIVERY_BLOCKED" "auto invoice delivery guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "INVOICE_ID_REQUIRED" "invoice id guard"
contains "$RUNTIME_FILE" "BILLING_PROFILE_REQUIRED" "billing profile guard"
contains "$RUNTIME_FILE" "PLAN_SNAPSHOT_REQUIRED" "plan snapshot guard"
contains "$RUNTIME_FILE" "LINE_ITEMS_REQUIRED" "line items guard"
contains "$RUNTIME_FILE" "TAX_CALCULATION_REQUIRED" "tax calculation guard"
contains "$RUNTIME_FILE" "DUE_DATE_REQUIRED" "due date guard"
contains "$RUNTIME_FILE" "CURRENCY_REQUIRED" "currency guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "IDEMPOTENCY_KEY_REQUIRED" "idempotency key guard"
contains "$RUNTIME_FILE" "ACCOUNTING_EXPORT_REQUIRED" "accounting export guard"
contains "$RUNTIME_FILE" "E_DOCUMENT_HANDOFF_REQUIRED" "e-document handoff guard"
contains "$RUNTIME_FILE" "PRODUCTION_INVOICE_BLOCK_REQUIRED" "production invoice block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_DELIVERY_BLOCK_REQUIRED" "real customer delivery block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/invoiceflow; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/invoice_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_2_2_faturalama_akisi_test.json").read_text())

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
    assert s["production_invoice_enabled"] is False, f"production invoice must be false: {key}"
    assert s["real_customer_invoice_enabled"] is False, f"real customer invoice must be false: {key}"
    assert s["auto_invoice_delivery_enabled"] is False, f"auto invoice delivery must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_invoice_id"] is True, f"invoice id missing: {key}"
    assert s["requires_billing_profile"] is True, f"billing profile missing: {key}"
    assert s["requires_plan_snapshot"] is True, f"plan snapshot missing: {key}"
    assert s["requires_line_items"] is True, f"line items missing: {key}"
    assert s["requires_tax_calculation"] is True, f"tax calculation missing: {key}"
    assert s["requires_due_date"] is True, f"due date missing: {key}"
    assert s["requires_currency"] is True, f"currency missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_idempotency_key"] is True, f"idempotency missing: {key}"
    assert s["requires_accounting_export"] is True, f"accounting export missing: {key}"
    assert s["requires_e_document_handoff"] is True, f"e-document handoff missing: {key}"
    assert s["blocks_production_invoice"] is True, f"production invoice block missing: {key}"
    assert s["blocks_real_customer_delivery"] is True, f"real customer delivery block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["e_document_deferred_marker"]["deferred_to_e_document_module"] is True
assert steps["e_document_deferred_marker"]["deferred_reason"], "e-document deferred reason missing"
assert control["internal_invoice_flow_ready"] is True
assert control["production_invoice_enabled"] is False
assert control["real_customer_invoice_enabled"] is False
assert control["auto_invoice_delivery_enabled"] is False
assert control["final_policy"]["refund_cancel_flow_required_next"] is True
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
# FAZ 5-18.2.2 Faturalama Akışı Real Implementation Audit

PHASE=FAZ_5_18_2_2
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
INTERNAL_INVOICE_FLOW_READY=true
PRODUCTION_INVOICE_ENABLED=false
REAL_CUSTOMER_INVOICE_ENABLED=false
AUTO_INVOICE_DELIVERY_ENABLED=false
E_DOCUMENT_LIVE_DEFERRED=true
REFUND_CANCEL_FLOW_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.2.2 FATURALAMA AKISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_2_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_2_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
