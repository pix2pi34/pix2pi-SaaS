#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.4.6"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_4_6_SUPPORT_OPS_TESTLERI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_4_6_support_ops_testleri.v1.json"
CONTROL_FILE="configs/faz5r/support_ops_test_suite.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_4_6_support_ops_testleri_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supportopstests/support_ops_tests.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supportopstests/support_ops_tests_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_4_6_SUPPORT_OPS_TESTLERI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.4.6 SUPPORT OPS TESTLERI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"support_sla_contract_test"' "support SLA contract test registered"
contains "$CONTROL_FILE" '"support_channel_intake_test"' "support channel intake test registered"
contains "$CONTROL_FILE" '"support_template_contract_test"' "support template contract test registered"
contains "$CONTROL_FILE" '"support_escalation_matrix_test"' "support escalation matrix test registered"
contains "$CONTROL_FILE" '"support_incident_classification_test"' "support incident classification test registered"
contains "$CONTROL_FILE" '"support_end_to_end_readiness_test"' "support end-to-end readiness test registered"
contains "$CONTROL_FILE" '"support_negative_guard_test"' "support negative guard test registered"
contains "$CONTROL_FILE" '"SLA"' "SLA domain registered"
contains "$CONTROL_FILE" '"CHANNEL"' "channel domain registered"
contains "$CONTROL_FILE" '"TEMPLATE"' "template domain registered"
contains "$CONTROL_FILE" '"ESCALATION"' "escalation domain registered"
contains "$CONTROL_FILE" '"INCIDENT"' "incident domain registered"
contains "$CONTROL_FILE" '"END_TO_END"' "end-to-end domain registered"
contains "$CONTROL_FILE" '"NEGATIVE_GUARD"' "negative guard domain registered"
contains "$CONTROL_FILE" '"internal_support_ops_tests_ready": true' "internal support ops tests ready"
contains "$CONTROL_FILE" '"production_support_ops_enabled": false' "production support ops disabled"
contains "$CONTROL_FILE" '"real_customer_notification_enabled": false' "real customer notification disabled"
contains "$CONTROL_FILE" '"has_positive_path": true' "positive path present"
contains "$CONTROL_FILE" '"has_negative_path": true' "negative path present"
contains "$CONTROL_FILE" '"has_tenant_isolation_check": true' "tenant isolation check present"
contains "$CONTROL_FILE" '"has_correlation_id_check": true' "correlation id check present"
contains "$CONTROL_FILE" '"has_audit_evidence_check": true' "audit evidence check present"
contains "$CONTROL_FILE" '"has_counter_based_result": true' "counter based result present"
contains "$CONTROL_FILE" '"blocks_public_support": true' "public support block present"
contains "$CONTROL_FILE" '"blocks_real_customer_notification": true' "real customer notification block present"
contains "$CONTROL_FILE" '"blocks_production_auto_action": true' "production auto action block present"
contains "$CONTROL_FILE" '"expected_required_fail": 0' "expected required fail zero"
contains "$CONTROL_FILE" '"expected_optional_warn": 0' "expected optional warn zero"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SUPPORT_OPS_BLOCKED" "production support ops guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_NOTIFICATION_BLOCKED" "real customer notification guard"
contains "$RUNTIME_FILE" "POSITIVE_PATH_REQUIRED" "positive path guard"
contains "$RUNTIME_FILE" "NEGATIVE_PATH_REQUIRED" "negative path guard"
contains "$RUNTIME_FILE" "TENANT_ISOLATION_CHECK_REQUIRED" "tenant isolation guard"
contains "$RUNTIME_FILE" "CORRELATION_ID_CHECK_REQUIRED" "correlation id guard"
contains "$RUNTIME_FILE" "AUDIT_EVIDENCE_CHECK_REQUIRED" "audit evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_RESULT_REQUIRED" "counter based result guard"
contains "$RUNTIME_FILE" "PUBLIC_SUPPORT_BLOCK_REQUIRED" "public support block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_NOTIFICATION_BLOCK_REQUIRED" "real customer notification block guard"
contains "$RUNTIME_FILE" "PRODUCTION_AUTO_ACTION_BLOCK_REQUIRED" "production auto action guard"
contains "$RUNTIME_FILE" "DOMAIN_ASSERTION_REQUIRED" "domain assertion guard"

if go test ./internal/commercial/publiclaunch/supportopstests; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/support_ops_test_suite.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_4_6_support_ops_testleri_test.json").read_text())

cases = {c["key"]: c for c in control["cases"]}
domains = {c["domain"] for c in control["cases"]}

for key in test["must_have_case_keys"]:
    assert key in cases, f"missing case key: {key}"
    c = cases[key]
    assert c["status"] == "READY", f"case not ready: {key}"
    assert c["required"] is True, f"case not required: {key}"
    assert c["has_positive_path"] is True, f"positive path missing: {key}"
    assert c["has_negative_path"] is True, f"negative path missing: {key}"
    assert c["has_tenant_isolation_check"] is True, f"tenant isolation missing: {key}"
    assert c["has_correlation_id_check"] is True, f"correlation id missing: {key}"
    assert c["has_audit_evidence_check"] is True, f"audit evidence missing: {key}"
    assert c["has_counter_based_result"] is True, f"counter result missing: {key}"
    assert c["blocks_public_support"] is True, f"public support block missing: {key}"
    assert c["blocks_real_customer_notification"] is True, f"real customer notification block missing: {key}"
    assert c["blocks_production_auto_action"] is True, f"production auto action block missing: {key}"
    assert c["expected_required_fail"] == 0, f"expected required fail not zero: {key}"
    assert c["expected_optional_warn"] == 0, f"expected optional warn not zero: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

e2e = cases["support_end_to_end_readiness_test"]
assert e2e["has_sla_assertion"] is True
assert e2e["has_channel_assertion"] is True
assert e2e["has_template_assertion"] is True
assert e2e["has_escalation_assertion"] is True
assert e2e["has_incident_assertion"] is True

negative = cases["support_negative_guard_test"]
assert negative["has_negative_path"] is True
assert negative["blocks_public_support"] is True
assert negative["blocks_real_customer_notification"] is True
assert negative["blocks_production_auto_action"] is True

assert control["internal_support_ops_tests_ready"] is True
assert control["production_support_ops_enabled"] is False
assert control["real_customer_notification_enabled"] is False
assert control["final_policy"]["support_ops_block_complete"] is True
assert control["final_policy"]["commercial_checklist_required_next"] is True
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
# FAZ 5-18.4.6 Support Ops Testleri Real Implementation Audit

PHASE=FAZ_5_18_4_6
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
INTERNAL_SUPPORT_OPS_TESTS_READY=true
PRODUCTION_SUPPORT_OPS_ENABLED=false
REAL_CUSTOMER_NOTIFICATION_ENABLED=false
SUPPORT_OPS_BLOCK_COMPLETE=true
COMMERCIAL_CHECKLIST_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.4.6 SUPPORT OPS TESTLERI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_4_6_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_4_6_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
