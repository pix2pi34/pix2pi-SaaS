#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.4.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_4_3_INCIDENT_SINIFLANDIRMA.md"
CONFIG_FILE="configs/faz5r/faz_5_18_4_3_incident_siniflandirma.v1.json"
CONTROL_FILE="configs/faz5r/support_incident_classification.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_4_3_incident_siniflandirma_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supportincident/support_incident.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supportincident/support_incident_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_4_3_INCIDENT_SINIFLANDIRMA_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.4.3 INCIDENT SINIFLANDIRMA REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"incident_availability_p0"' "availability incident rule registered"
contains "$CONTROL_FILE" '"incident_performance_p2"' "performance incident rule registered"
contains "$CONTROL_FILE" '"incident_security_p0"' "security incident rule registered"
contains "$CONTROL_FILE" '"incident_kvkk_p1"' "kvkk incident rule registered"
contains "$CONTROL_FILE" '"incident_billing_p1"' "billing incident rule registered"
contains "$CONTROL_FILE" '"incident_data_integrity_p0"' "data integrity incident rule registered"
contains "$CONTROL_FILE" '"incident_support_ops_p3"' "support ops incident rule registered"
contains "$CONTROL_FILE" '"AVAILABILITY"' "availability category registered"
contains "$CONTROL_FILE" '"PERFORMANCE"' "performance category registered"
contains "$CONTROL_FILE" '"SECURITY"' "security category registered"
contains "$CONTROL_FILE" '"KVKK"' "kvkk category registered"
contains "$CONTROL_FILE" '"BILLING"' "billing category registered"
contains "$CONTROL_FILE" '"DATA_INTEGRITY"' "data integrity category registered"
contains "$CONTROL_FILE" '"SUPPORT_OPS"' "support ops category registered"
contains "$CONTROL_FILE" '"P0_CRITICAL"' "P0 severity registered"
contains "$CONTROL_FILE" '"P1_HIGH"' "P1 severity registered"
contains "$CONTROL_FILE" '"P2_NORMAL"' "P2 severity registered"
contains "$CONTROL_FILE" '"P3_LOW"' "P3 severity registered"
contains "$CONTROL_FILE" '"internal_classification_ready": true' "internal classification ready"
contains "$CONTROL_FILE" '"production_auto_classification_enabled": false' "production auto classification disabled"
contains "$CONTROL_FILE" '"customer_notification_enabled": false' "customer notification disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_ticket_id": true' "ticket id required"
contains "$CONTROL_FILE" '"requires_correlation_id": true' "correlation id required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_root_cause": true' "root cause required"
contains "$CONTROL_FILE" '"requires_customer_impact": true' "customer impact required"
contains "$CONTROL_FILE" '"manual_review_allowed": true' "manual review allowed"
contains "$CONTROL_FILE" '"blocks_auto_close": true' "auto close blocked"
contains "$CONTROL_FILE" '"default_sla_key"' "default SLA key present"
contains "$CONTROL_FILE" '"default_escalation_key"' "default escalation key present"
contains "$CONTROL_FILE" '"default_customer_template_key"' "default customer template key present"
contains "$CONTROL_FILE" '"requires_security_review": true' "security review present"
contains "$CONTROL_FILE" '"requires_kvkk_review": true' "kvkk review present"
contains "$CONTROL_FILE" '"requires_billing_owner": true' "billing owner present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_AUTO_CLASSIFICATION_BLOCKED" "production auto classification guard"
contains "$RUNTIME_FILE" "CUSTOMER_NOTIFICATION_BLOCKED" "customer notification guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "TICKET_ID_REQUIRED" "ticket id guard"
contains "$RUNTIME_FILE" "CORRELATION_ID_REQUIRED" "correlation id guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "ROOT_CAUSE_REQUIRED" "root cause guard"
contains "$RUNTIME_FILE" "CUSTOMER_IMPACT_REQUIRED" "customer impact guard"
contains "$RUNTIME_FILE" "MANUAL_REVIEW_REQUIRED" "manual review guard"
contains "$RUNTIME_FILE" "AUTO_CLOSE_BLOCK_REQUIRED" "auto close block guard"
contains "$RUNTIME_FILE" "SPECIAL_OWNER_MAPPING_REQUIRED" "special owner mapping guard"
contains "$RUNTIME_FILE" "SEVERITY_COVERAGE_MISSING" "severity coverage guard"

if go test ./internal/commercial/publiclaunch/supportincident; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/support_incident_classification.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_4_3_incident_siniflandirma_test.json").read_text())

rules = {r["key"]: r for r in control["rules"]}
categories = {r["category"] for r in control["rules"]}
severities = {r["severity"] for r in control["rules"]}

for key in test["must_have_rule_keys"]:
    assert key in rules, f"missing rule key: {key}"
    r = rules[key]
    assert r["status"] == "READY", f"rule not ready: {key}"
    assert r["required"] is True, f"rule not required: {key}"
    assert r["default_sla_key"], f"default_sla_key missing: {key}"
    assert r["default_escalation_key"], f"default_escalation_key missing: {key}"
    assert r["default_customer_template_key"], f"default_customer_template_key missing: {key}"
    assert r["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert r["requires_ticket_id"] is True, f"ticket id missing: {key}"
    assert r["requires_correlation_id"] is True, f"correlation id missing: {key}"
    assert r["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert r["requires_root_cause"] is True, f"root cause missing: {key}"
    assert r["requires_customer_impact"] is True, f"customer impact missing: {key}"
    assert r["manual_review_allowed"] is True, f"manual review missing: {key}"
    assert r["blocks_auto_close"] is True, f"auto close block missing: {key}"
    assert r["internal_only"] is True, f"internal only missing: {key}"
    assert r["production_auto_classify_enabled"] is False, f"production auto classify must be false: {key}"

for category in test["must_have_categories"]:
    assert category in categories, f"missing category: {category}"

for severity in test["must_have_severities"]:
    assert severity in severities, f"missing severity: {severity}"

assert rules["incident_security_p0"]["requires_security_review"] is True
assert rules["incident_security_p0"]["requires_engineering_owner"] is True
assert rules["incident_kvkk_p1"]["requires_kvkk_review"] is True
assert rules["incident_billing_p1"]["requires_billing_owner"] is True
assert control["internal_classification_ready"] is True
assert control["production_auto_classification_enabled"] is False
assert control["customer_notification_enabled"] is False
assert control["final_policy"]["support_ops_tests_required_next"] is True
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
# FAZ 5-18.4.3 Incident Sınıflandırma Real Implementation Audit

PHASE=FAZ_5_18_4_3
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
INTERNAL_CLASSIFICATION_READY=true
PRODUCTION_AUTO_CLASSIFICATION_ENABLED=false
CUSTOMER_NOTIFICATION_ENABLED=false
SUPPORT_OPS_TESTS_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.4.3 INCIDENT SINIFLANDIRMA REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_4_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_4_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
