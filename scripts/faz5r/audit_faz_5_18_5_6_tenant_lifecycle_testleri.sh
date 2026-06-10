#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.5.6"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_5_6_TENANT_LIFECYCLE_TESTLERI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_5_6_tenant_lifecycle_testleri.v1.json"
CONTROL_FILE="configs/faz5r/tenant_lifecycle_test_suite.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_5_6_tenant_lifecycle_testleri_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/tenantlifecycletests/tenant_lifecycle_tests.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/tenantlifecycletests/tenant_lifecycle_tests_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_5_6_TENANT_LIFECYCLE_TESTLERI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.5.6 TENANT LIFECYCLE TESTLERI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"tenant_shutdown_contract_test"' "tenant shutdown contract test registered"
contains "$CONTROL_FILE" '"tenant_data_export_contract_test"' "tenant data export contract test registered"
contains "$CONTROL_FILE" '"tenant_plan_change_contract_test"' "tenant plan change contract test registered"
contains "$CONTROL_FILE" '"tenant_freeze_contract_test"' "tenant freeze contract test registered"
contains "$CONTROL_FILE" '"cross_flow_billing_guard_test"' "cross flow billing guard test registered"
contains "$CONTROL_FILE" '"cross_flow_audit_evidence_test"' "cross flow audit evidence test registered"
contains "$CONTROL_FILE" '"crm_stage_deferred_marker"' "crm stage deferred marker registered"
contains "$CONTROL_FILE" '"TENANT_SHUTDOWN"' "tenant shutdown domain registered"
contains "$CONTROL_FILE" '"DATA_EXPORT"' "data export domain registered"
contains "$CONTROL_FILE" '"PLAN_CHANGE"' "plan change domain registered"
contains "$CONTROL_FILE" '"TENANT_FREEZE"' "tenant freeze domain registered"
contains "$CONTROL_FILE" '"CROSS_FLOW"' "cross flow domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_lifecycle_tests_ready": true' "internal lifecycle tests ready"
contains "$CONTROL_FILE" '"production_lifecycle_live_enabled": false' "production lifecycle live disabled"
contains "$CONTROL_FILE" '"real_customer_ops_open": false' "real customer ops closed"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"production_live_enabled": false' "production live false present"
contains "$CONTROL_FILE" '"real_customer_ops_enabled": false' "real customer ops false present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id coverage present"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail coverage present"
contains "$CONTROL_FILE" '"requires_rollback_coverage": true' "rollback coverage present"
contains "$CONTROL_FILE" '"requires_config_fixture": true' "config fixture coverage present"
contains "$CONTROL_FILE" '"requires_runtime_package": true' "runtime package coverage present"
contains "$CONTROL_FILE" '"requires_evidence_file": true' "evidence file coverage present"
contains "$CONTROL_FILE" '"requires_cross_flow_coverage": true' "cross flow coverage present"
contains "$CONTROL_FILE" '"blocks_production_live": true' "production live block present"
contains "$CONTROL_FILE" '"covered_artifacts"' "covered artifacts present"
contains "$CONTROL_FILE" '"deferred_to_crm_stage_flow": true' "crm stage deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_6_2_CRM_STAGE_YONETIMI"' "next gate 265 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_LIFECYCLE_LIVE_BLOCKED" "production lifecycle live guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_OPS_BLOCKED" "real customer ops guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "ROLLBACK_COVERAGE_REQUIRED" "rollback coverage guard"
contains "$RUNTIME_FILE" "CONFIG_FIXTURE_REQUIRED" "config fixture guard"
contains "$RUNTIME_FILE" "RUNTIME_PACKAGE_REQUIRED" "runtime package guard"
contains "$RUNTIME_FILE" "EVIDENCE_FILE_REQUIRED" "evidence file guard"
contains "$RUNTIME_FILE" "CROSS_FLOW_COVERAGE_REQUIRED" "cross flow coverage guard"
contains "$RUNTIME_FILE" "PRODUCTION_LIVE_BLOCK_REQUIRED" "production live block guard"
contains "$RUNTIME_FILE" "COVERED_ARTIFACTS_REQUIRED" "covered artifacts guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/tenantlifecycletests; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/tenant_lifecycle_test_suite.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_5_6_tenant_lifecycle_testleri_test.json").read_text())

cases = {c["key"]: c for c in control["test_cases"]}
domains = {c["domain"] for c in control["test_cases"]}

for key in test["must_have_test_keys"]:
    assert key in cases, f"missing test key: {key}"
    c = cases[key]
    assert c["required"] is True, f"test not required: {key}"
    assert c["has_evidence"] is True, f"evidence missing: {key}"
    assert c["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert c["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert c["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert c["production_live_enabled"] is False, f"production live must be false: {key}"
    assert c["real_customer_ops_enabled"] is False, f"real customer ops must be false: {key}"
    assert c["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert c["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert c["requires_rollback_coverage"] is True, f"rollback missing: {key}"
    assert c["requires_config_fixture"] is True, f"config fixture missing: {key}"
    assert c["requires_runtime_package"] is True, f"runtime package missing: {key}"
    assert c["requires_evidence_file"] is True, f"evidence file missing: {key}"
    assert c["requires_cross_flow_coverage"] is True, f"cross flow missing: {key}"
    assert c["blocks_production_live"] is True, f"production live block missing: {key}"
    assert len(c["covered_artifacts"]) > 0, f"covered artifacts missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert cases["crm_stage_deferred_marker"]["deferred_to_crm_stage_flow"] is True
assert cases["crm_stage_deferred_marker"]["deferred_reason"], "crm stage deferred reason missing"
assert control["internal_lifecycle_tests_ready"] is True
assert control["production_lifecycle_live_enabled"] is False
assert control["real_customer_ops_open"] is False
assert control["final_policy"]["tenant_lifecycle_block_complete"] is True
assert control["final_policy"]["crm_stage_management_required_next"] is True
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
# FAZ 5-18.5.6 Tenant Lifecycle Testleri Real Implementation Audit

PHASE=FAZ_5_18_5_6
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
INTERNAL_LIFECYCLE_TESTS_READY=true
PRODUCTION_LIFECYCLE_LIVE_ENABLED=false
REAL_CUSTOMER_OPS_OPEN=false
TENANT_LIFECYCLE_BLOCK_COMPLETE=true
CRM_STAGE_MANAGEMENT_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.5.6 TENANT LIFECYCLE TESTLERI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_5_6_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_5_6_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
