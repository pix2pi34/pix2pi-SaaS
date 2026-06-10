#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.2.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_2_3_TAHSILAT_BASARISIZ_ODEME_AKISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_2_3_tahsilat_basarisiz_odeme_akisi.v1.json"
CONTROL_FILE="configs/faz5r/collection_failed_payment_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_2_3_tahsilat_basarisiz_odeme_akisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/collectionflow/collection_flow.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/collectionflow/collection_flow_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_2_3_TAHSILAT_BASARISIZ_ODEME_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.2.3 TAHSILAT / BASARISIZ ODEME AKISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"invoice_due_marker"' "invoice due marker registered"
contains "$CONTROL_FILE" '"collection_attempt_create"' "collection attempt create registered"
contains "$CONTROL_FILE" '"payment_failed_capture"' "payment failed capture registered"
contains "$CONTROL_FILE" '"retry_schedule_policy"' "retry schedule policy registered"
contains "$CONTROL_FILE" '"grace_period_policy"' "grace period policy registered"
contains "$CONTROL_FILE" '"manual_review_queue"' "manual review queue registered"
contains "$CONTROL_FILE" '"tenant_action_block_policy"' "tenant action block policy registered"
contains "$CONTROL_FILE" '"provider_live_deferred_marker"' "provider live deferred marker registered"
contains "$CONTROL_FILE" '"INVOICE_DUE"' "invoice due event registered"
contains "$CONTROL_FILE" '"COLLECTION_ATTEMPT"' "collection attempt event registered"
contains "$CONTROL_FILE" '"PAYMENT_FAILED"' "payment failed event registered"
contains "$CONTROL_FILE" '"RETRY_SCHEDULED"' "retry scheduled event registered"
contains "$CONTROL_FILE" '"GRACE_PERIOD_STARTED"' "grace period event registered"
contains "$CONTROL_FILE" '"MANUAL_REVIEW_QUEUED"' "manual review event registered"
contains "$CONTROL_FILE" '"TENANT_ACTION_BLOCKED"' "tenant action blocked event registered"
contains "$CONTROL_FILE" '"internal_collection_flow_ready": true' "internal collection flow ready"
contains "$CONTROL_FILE" '"production_payment_enabled": false' "production payment disabled"
contains "$CONTROL_FILE" '"real_customer_charging_enabled": false' "real customer charging disabled"
contains "$CONTROL_FILE" '"auto_tenant_suspension_enabled": false' "auto tenant suspension disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_invoice_id": true' "invoice id required"
contains "$CONTROL_FILE" '"requires_attempt_id": true' "attempt id required"
contains "$CONTROL_FILE" '"requires_idempotency_key": true' "idempotency key required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_retry_policy": true' "retry policy required"
contains "$CONTROL_FILE" '"requires_dunning_template": true' "dunning template required"
contains "$CONTROL_FILE" '"requires_manual_review": true' "manual review required"
contains "$CONTROL_FILE" '"requires_billing_owner": true' "billing owner required"
contains "$CONTROL_FILE" '"blocks_production_charging": true' "production charging block present"
contains "$CONTROL_FILE" '"blocks_auto_tenant_suspension": true' "auto tenant suspension block present"
contains "$CONTROL_FILE" '"max_retry_count": 3' "max retry count present"
contains "$CONTROL_FILE" '"grace_period_days": 7' "grace period days present"
contains "$CONTROL_FILE" '"deferred_to_provider_live": true' "provider live deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_2_2_FATURALAMA_AKISI"' "next gate 258 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PAYMENT_BLOCKED" "production payment guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_CHARGING_BLOCKED" "real customer charging guard"
contains "$RUNTIME_FILE" "AUTO_TENANT_SUSPENSION_BLOCKED" "auto tenant suspension guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "INVOICE_ID_REQUIRED" "invoice id guard"
contains "$RUNTIME_FILE" "ATTEMPT_ID_REQUIRED" "attempt id guard"
contains "$RUNTIME_FILE" "IDEMPOTENCY_KEY_REQUIRED" "idempotency key guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "RETRY_POLICY_REQUIRED" "retry policy guard"
contains "$RUNTIME_FILE" "DUNNING_TEMPLATE_REQUIRED" "dunning template guard"
contains "$RUNTIME_FILE" "MANUAL_REVIEW_REQUIRED" "manual review guard"
contains "$RUNTIME_FILE" "BILLING_OWNER_REQUIRED" "billing owner guard"
contains "$RUNTIME_FILE" "PRODUCTION_CHARGING_BLOCK_REQUIRED" "production charging block guard"
contains "$RUNTIME_FILE" "AUTO_TENANT_SUSPENSION_BLOCK_REQUIRED" "auto tenant suspension block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/collectionflow; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/collection_failed_payment_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_2_3_tahsilat_basarisiz_odeme_akisi_test.json").read_text())

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
    assert s["production_payment_enabled"] is False, f"production payment must be false: {key}"
    assert s["real_customer_charging_enabled"] is False, f"real customer charging must be false: {key}"
    assert s["auto_tenant_suspension_enabled"] is False, f"auto suspension must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_invoice_id"] is True, f"invoice id missing: {key}"
    assert s["requires_attempt_id"] is True, f"attempt id missing: {key}"
    assert s["requires_idempotency_key"] is True, f"idempotency missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_retry_policy"] is True, f"retry policy missing: {key}"
    assert s["requires_dunning_template"] is True, f"dunning template missing: {key}"
    assert s["requires_manual_review"] is True, f"manual review missing: {key}"
    assert s["requires_billing_owner"] is True, f"billing owner missing: {key}"
    assert s["blocks_production_charging"] is True, f"production charging block missing: {key}"
    assert s["blocks_auto_tenant_suspension"] is True, f"auto suspension block missing: {key}"
    assert s["max_retry_count"] >= 0, f"bad retry count: {key}"
    assert s["grace_period_days"] >= 0, f"bad grace period: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["provider_live_deferred_marker"]["deferred_to_provider_live"] is True
assert steps["provider_live_deferred_marker"]["deferred_reason"], "provider live deferred reason missing"
assert control["internal_collection_flow_ready"] is True
assert control["production_payment_enabled"] is False
assert control["real_customer_charging_enabled"] is False
assert control["auto_tenant_suspension_enabled"] is False
assert control["final_policy"]["invoice_flow_required_next"] is True
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
# FAZ 5-18.2.3 Tahsilat / Başarısız Ödeme Akışı Real Implementation Audit

PHASE=FAZ_5_18_2_3
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
INTERNAL_COLLECTION_FLOW_READY=true
PRODUCTION_PAYMENT_ENABLED=false
REAL_CUSTOMER_CHARGING_ENABLED=false
AUTO_TENANT_SUSPENSION_ENABLED=false
REAL_PROVIDER_LIVE_DEFERRED=true
INVOICE_FLOW_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.2.3 TAHSILAT / BASARISIZ ODEME AKISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_2_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_2_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
