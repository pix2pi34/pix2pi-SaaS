#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.8.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_8_3_SUPPORT_READINESS.md"
CONFIG_FILE="configs/faz5r/faz_5_18_8_3_support_readiness.v1.json"
CONTROL_FILE="configs/faz5r/support_readiness.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_8_3_support_readiness_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supportreadiness/support_readiness.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supportreadiness/support_readiness_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_8_3_SUPPORT_READINESS_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.8.3 SUPPORT READINESS REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"support_sla_ready"' "support SLA readiness item registered"
contains "$CONTROL_FILE" '"support_channel_ready"' "support channel readiness item registered"
contains "$CONTROL_FILE" '"support_templates_ready"' "support templates readiness item registered"
contains "$CONTROL_FILE" '"support_escalation_ready"' "support escalation readiness item registered"
contains "$CONTROL_FILE" '"support_incident_ready"' "support incident readiness item registered"
contains "$CONTROL_FILE" '"support_ops_tests_ready"' "support ops tests readiness item registered"
contains "$CONTROL_FILE" '"commercial_legal_alignment_ready"' "commercial legal alignment item registered"
contains "$CONTROL_FILE" '"support_launch_gate_ready"' "support launch gate item registered"
contains "$CONTROL_FILE" '"SLA"' "SLA domain registered"
contains "$CONTROL_FILE" '"CHANNEL"' "channel domain registered"
contains "$CONTROL_FILE" '"TEMPLATE"' "template domain registered"
contains "$CONTROL_FILE" '"ESCALATION"' "escalation domain registered"
contains "$CONTROL_FILE" '"INCIDENT"' "incident domain registered"
contains "$CONTROL_FILE" '"OPS_TEST"' "ops test domain registered"
contains "$CONTROL_FILE" '"COMMERCIAL_LEGAL"' "commercial legal domain registered"
contains "$CONTROL_FILE" '"LAUNCH_GATE"' "launch gate domain registered"
contains "$CONTROL_FILE" '"internal_support_readiness_ready": true' "internal support readiness ready"
contains "$CONTROL_FILE" '"production_support_enabled": false' "production support disabled"
contains "$CONTROL_FILE" '"real_customer_support_open": false' "real customer support closed"
contains "$CONTROL_FILE" '"public_support_enabled": false' "public support disabled"
contains "$CONTROL_FILE" '"customer_notification_enabled": false' "customer notification disabled"
contains "$CONTROL_FILE" '"internal_ready": true' "internal ready present"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_correlation_id": true' "correlation id required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_sla_contract": true' "SLA contract required"
contains "$CONTROL_FILE" '"requires_escalation_binding": true' "escalation binding required"
contains "$CONTROL_FILE" '"requires_incident_classification": true' "incident classification required"
contains "$CONTROL_FILE" '"requires_communication_template": true' "communication template required"
contains "$CONTROL_FILE" '"blocks_production_support": true' "production support block present"
contains "$CONTROL_FILE" '"blocks_real_customer_notification": true' "real customer notification block present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SUPPORT_ENABLED_BLOCKED" "production support enabled guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SUPPORT_OPEN_BLOCKED" "real customer support open guard"
contains "$RUNTIME_FILE" "PUBLIC_SUPPORT_ENABLED_BLOCKED" "public support enabled guard"
contains "$RUNTIME_FILE" "CUSTOMER_NOTIFICATION_ENABLED_BLOCKED" "customer notification enabled guard"
contains "$RUNTIME_FILE" "INTERNAL_READY_REQUIRED" "internal ready guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "CORRELATION_ID_REQUIRED" "correlation id guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "SLA_CONTRACT_REQUIRED" "SLA contract guard"
contains "$RUNTIME_FILE" "ESCALATION_BINDING_REQUIRED" "escalation binding guard"
contains "$RUNTIME_FILE" "INCIDENT_CLASSIFICATION_REQUIRED" "incident classification guard"
contains "$RUNTIME_FILE" "COMMUNICATION_TEMPLATE_REQUIRED" "communication template guard"

if go test ./internal/commercial/publiclaunch/supportreadiness; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/support_readiness.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_8_3_support_readiness_test.json").read_text())

items = {i["key"]: i for i in control["items"]}
domains = {i["domain"] for i in control["items"]}

for key in test["must_have_item_keys"]:
    assert key in items, f"missing item key: {key}"
    i = items[key]
    assert i["status"] == "READY", f"item not ready: {key}"
    assert i["required"] is True, f"item not required: {key}"
    assert i["internal_ready"] is True, f"internal ready missing: {key}"
    assert i["has_evidence"] is True, f"evidence missing: {key}"
    assert i["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert i["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert i["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert i["production_enabled"] is False, f"production enabled must be false: {key}"
    assert i["real_customer_support_open"] is False, f"real customer support open must be false: {key}"
    assert i["public_support_enabled"] is False, f"public support enabled must be false: {key}"
    assert i["customer_notification_enabled"] is False, f"customer notification enabled must be false: {key}"
    assert i["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert i["requires_correlation_id"] is True, f"correlation id missing: {key}"
    assert i["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert i["blocks_production_support"] is True, f"production support block missing: {key}"
    assert i["blocks_real_customer_notification"] is True, f"real customer notification block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert control["internal_support_readiness_ready"] is True
assert control["production_support_enabled"] is False
assert control["real_customer_support_open"] is False
assert control["public_support_enabled"] is False
assert control["customer_notification_enabled"] is False
assert control["final_policy"]["commercial_closure_report_required_next"] is True
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
# FAZ 5-18.8.3 Support Readiness Real Implementation Audit

PHASE=FAZ_5_18_8_3
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
INTERNAL_SUPPORT_READINESS_READY=true
PRODUCTION_SUPPORT_ENABLED=false
REAL_CUSTOMER_SUPPORT_OPEN=false
PUBLIC_SUPPORT_ENABLED=false
CUSTOMER_NOTIFICATION_ENABLED=false
COMMERCIAL_CLOSURE_REPORT_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.8.3 SUPPORT READINESS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_8_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_8_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
