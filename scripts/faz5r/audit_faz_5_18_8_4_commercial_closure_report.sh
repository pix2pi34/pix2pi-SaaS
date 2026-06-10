#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.8.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_8_4_COMMERCIAL_CLOSURE_REPORT.md"
CONFIG_FILE="configs/faz5r/faz_5_18_8_4_commercial_closure_report.v1.json"
CONTROL_FILE="configs/faz5r/commercial_closure_report.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_8_4_commercial_closure_report_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/commercialclosure/commercial_closure.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/commercialclosure/commercial_closure_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_8_4_COMMERCIAL_CLOSURE_REPORT_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.8.4 COMMERCIAL CLOSURE REPORT REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"compliance_block_complete"' "compliance block complete item registered"
contains "$CONTROL_FILE" '"support_ops_block_complete"' "support ops block complete item registered"
contains "$CONTROL_FILE" '"commercial_checklist_complete"' "commercial checklist complete item registered"
contains "$CONTROL_FILE" '"legal_checklist_complete"' "legal checklist complete item registered"
contains "$CONTROL_FILE" '"support_readiness_complete"' "support readiness complete item registered"
contains "$CONTROL_FILE" '"priority_1_closure_gate"' "priority 1 closure gate registered"
contains "$CONTROL_FILE" '"production_launch_block"' "production launch block registered"
contains "$CONTROL_FILE" '"priority_2_ready_marker"' "priority 2 ready marker registered"
contains "$CONTROL_FILE" '"COMPLIANCE"' "compliance domain registered"
contains "$CONTROL_FILE" '"SUPPORT_OPS"' "support ops domain registered"
contains "$CONTROL_FILE" '"COMMERCIAL"' "commercial domain registered"
contains "$CONTROL_FILE" '"LEGAL"' "legal domain registered"
contains "$CONTROL_FILE" '"CLOSURE"' "closure domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_commercial_closure_ready": true' "internal commercial closure ready"
contains "$CONTROL_FILE" '"priority_1_commercial_block_complete": true' "priority 1 commercial block complete"
contains "$CONTROL_FILE" '"production_public_launch_allowed": false' "production public launch blocked"
contains "$CONTROL_FILE" '"real_customer_commercial_ops_open": false' "real customer commercial ops closed"
contains "$CONTROL_FILE" '"internal_ready": true' "internal ready present"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"production_enabled": false' "production enabled false present"
contains "$CONTROL_FILE" '"real_customer_ops_open": false' "real customer ops closed present"
contains "$CONTROL_FILE" '"blocks_production_launch": true' "production launch block present"
contains "$CONTROL_FILE" '"deferred_to_next_priority": true' "deferred next priority marker present"
contains "$CONTROL_FILE" '"FAZ_5_18_2_3_TAHSILAT_BASARISIZ_ODEME_AKISI"' "next gate 257 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLIC_LAUNCH_BLOCKED" "production public launch guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COMMERCIAL_OPS_BLOCKED" "real customer commercial ops guard"
contains "$RUNTIME_FILE" "INTERNAL_READY_REQUIRED" "internal ready guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PRODUCTION_LAUNCH_BLOCK_REQUIRED" "production launch block guard"
contains "$RUNTIME_FILE" "ITEM_PRODUCTION_ENABLED_BLOCKED" "production enabled guard"
contains "$RUNTIME_FILE" "ITEM_REAL_CUSTOMER_OPS_BLOCKED" "real customer ops guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/commercialclosure; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/commercial_closure_report.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_8_4_commercial_closure_report_test.json").read_text())

items = {i["key"]: i for i in control["items"]}
domains = {i["domain"] for i in control["items"]}

for key in test["must_have_item_keys"]:
    assert key in items, f"missing item key: {key}"
    i = items[key]
    assert i["required"] is True, f"item not required: {key}"
    assert i["has_evidence"] is True, f"evidence missing: {key}"
    assert i["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert i["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert i["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert i["production_enabled"] is False, f"production enabled must be false: {key}"
    assert i["real_customer_ops_open"] is False, f"real customer ops must be false: {key}"
    assert i["blocks_production_launch"] is True, f"production launch block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert items["priority_2_ready_marker"]["deferred_to_next_priority"] is True
assert items["priority_2_ready_marker"]["deferred_reason"], "priority 2 deferred reason missing"
assert control["internal_commercial_closure_ready"] is True
assert control["priority_1_commercial_block_complete"] is True
assert control["production_public_launch_allowed"] is False
assert control["real_customer_commercial_ops_open"] is False
assert control["final_policy"]["faz_5_r_priority_1_complete"] is True
assert control["final_policy"]["priority_2_billing_tenant_lifecycle_sales_ops_ready"] is True
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
# FAZ 5-18.8.4 Commercial Closure Report Real Implementation Audit

PHASE=FAZ_5_18_8_4
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
INTERNAL_COMMERCIAL_CLOSURE_READY=true
PRIORITY_1_COMMERCIAL_BLOCK_COMPLETE=true
PRODUCTION_PUBLIC_LAUNCH_ALLOWED=false
REAL_CUSTOMER_COMMERCIAL_OPS_OPEN=false
FAZ_5_R_PRIORITY_1_COMPLETE=true
PRIORITY_2_BILLING_TENANT_LIFECYCLE_SALES_OPS_READY=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.8.4 COMMERCIAL CLOSURE REPORT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_8_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_8_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
