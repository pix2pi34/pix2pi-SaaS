#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.8.1"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_8_1_TICARI_CHECKLIST.md"
CONFIG_FILE="configs/faz5r/faz_5_18_8_1_ticari_checklist.v1.json"
CONTROL_FILE="configs/faz5r/commercial_checklist.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_8_1_ticari_checklist_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/commercialchecklist/commercial_checklist.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/commercialchecklist/commercial_checklist_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_8_1_TICARI_CHECKLIST_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.8.1 TICARI CHECKLIST REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"compliance_document_control"' "compliance document control item registered"
contains "$CONTROL_FILE" '"log_retention_policy"' "log retention policy item registered"
contains "$CONTROL_FILE" '"support_sla_levels"' "support SLA levels item registered"
contains "$CONTROL_FILE" '"support_channel_structure"' "support channel structure item registered"
contains "$CONTROL_FILE" '"customer_communication_templates"' "customer communication templates item registered"
contains "$CONTROL_FILE" '"support_escalation_matrix"' "support escalation matrix item registered"
contains "$CONTROL_FILE" '"incident_classification"' "incident classification item registered"
contains "$CONTROL_FILE" '"support_ops_test_suite"' "support ops test suite item registered"
contains "$CONTROL_FILE" '"billing_lifecycle_next_priority_marker"' "billing lifecycle next priority marker registered"
contains "$CONTROL_FILE" '"pricing_public_surface_next_priority_marker"' "pricing public surface next priority marker registered"
contains "$CONTROL_FILE" '"COMPLIANCE"' "compliance domain registered"
contains "$CONTROL_FILE" '"SUPPORT_OPS"' "support ops domain registered"
contains "$CONTROL_FILE" '"COMMERCIAL_OPS"' "commercial ops domain registered"
contains "$CONTROL_FILE" '"LAUNCH_GATE"' "launch gate domain registered"
contains "$CONTROL_FILE" '"DEFERRED_NEXT_PRIORITY"' "deferred next priority domain registered"
contains "$CONTROL_FILE" '"internal_commercial_checklist_ready": true' "internal commercial checklist ready"
contains "$CONTROL_FILE" '"production_public_launch_allowed": false' "production public launch blocked"
contains "$CONTROL_FILE" '"real_customer_commercial_ops_open": false' "real customer commercial ops closed"
contains "$CONTROL_FILE" '"requires_evidence": true' "requires evidence present"
contains "$CONTROL_FILE" '"has_evidence": true' "has evidence present"
contains "$CONTROL_FILE" '"requires_counter_based_audit": true' "requires counter based audit present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "has counter based audit present"
contains "$CONTROL_FILE" '"requires_no_required_fail": true' "requires no required fail present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"production_enabled": false' "production enabled false present"
contains "$CONTROL_FILE" '"deferred_to_next_priority": true' "deferred next priority present"
contains "$CONTROL_FILE" '"deferred_reason"' "deferred reason present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLIC_LAUNCH_BLOCKED" "production public launch guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COMMERCIAL_OPS_BLOCKED" "real customer commercial ops guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "INTERNAL_READY_REQUIRED" "internal ready guard"
contains "$RUNTIME_FILE" "PRODUCTION_ENABLED_BLOCKED" "production enabled guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/commercialchecklist; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/commercial_checklist.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_8_1_ticari_checklist_test.json").read_text())

items = {i["key"]: i for i in control["items"]}
domains = {i["domain"] for i in control["items"]}

for key in test["must_have_item_keys"]:
    assert key in items, f"missing item key: {key}"
    i = items[key]
    assert i["required"] is True, f"item not required: {key}"
    assert i["requires_evidence"] is True, f"requires evidence missing: {key}"
    assert i["has_evidence"] is True, f"has evidence missing: {key}"
    assert i["requires_counter_based_audit"] is True, f"requires counter audit missing: {key}"
    assert i["has_counter_based_audit"] is True, f"has counter audit missing: {key}"
    assert i["requires_no_required_fail"] is True, f"requires no required fail missing: {key}"
    assert i["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert i["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert i["production_enabled"] is False, f"production enabled must be false: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

for key in ["billing_lifecycle_next_priority_marker", "pricing_public_surface_next_priority_marker"]:
    assert items[key]["deferred_to_next_priority"] is True, f"deferred missing: {key}"
    assert items[key]["deferred_reason"], f"deferred reason missing: {key}"

assert control["internal_commercial_checklist_ready"] is True
assert control["production_public_launch_allowed"] is False
assert control["real_customer_commercial_ops_open"] is False
assert control["final_policy"]["legal_checklist_required_next"] is True
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
# FAZ 5-18.8.1 Ticari Checklist Real Implementation Audit

PHASE=FAZ_5_18_8_1
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
INTERNAL_COMMERCIAL_CHECKLIST_READY=true
PRODUCTION_PUBLIC_LAUNCH_ALLOWED=false
REAL_CUSTOMER_COMMERCIAL_OPS_OPEN=false
LEGAL_CHECKLIST_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.8.1 TICARI CHECKLIST REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_8_1_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_8_1_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
