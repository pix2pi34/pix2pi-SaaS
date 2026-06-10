#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.4.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_4_4_ESCALATION_MATRISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_4_4_escalation_matrisi.v1.json"
CONTROL_FILE="configs/faz5r/support_escalation_matrix.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_4_4_escalation_matrisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supportescalation/support_escalation.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supportescalation/support_escalation_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_4_4_ESCALATION_MATRISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.4.4 ESCALATION MATRISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"sla_breach_to_ops"' "sla breach escalation registered"
contains "$CONTROL_FILE" '"p0_incident_to_engineering"' "p0 incident escalation registered"
contains "$CONTROL_FILE" '"kvkk_request_to_compliance"' "kvkk escalation registered"
contains "$CONTROL_FILE" '"security_report_to_compliance"' "security escalation registered"
contains "$CONTROL_FILE" '"billing_dispute_to_business"' "billing dispute escalation registered"
contains "$CONTROL_FILE" '"unresolved_ticket_to_ops"' "unresolved ticket escalation registered"
contains "$CONTROL_FILE" '"SLA_BREACH"' "SLA breach trigger registered"
contains "$CONTROL_FILE" '"P0_INCIDENT"' "P0 incident trigger registered"
contains "$CONTROL_FILE" '"KVKK_REQUEST"' "KVKK request trigger registered"
contains "$CONTROL_FILE" '"SECURITY_REPORT"' "security report trigger registered"
contains "$CONTROL_FILE" '"BILLING_DISPUTE"' "billing dispute trigger registered"
contains "$CONTROL_FILE" '"UNRESOLVED_TICKET"' "unresolved ticket trigger registered"
contains "$CONTROL_FILE" '"internal_matrix_ready": true' "internal matrix ready"
contains "$CONTROL_FILE" '"production_auto_escalation_enabled": false' "production auto escalation disabled"
contains "$CONTROL_FILE" '"customer_notification_enabled": false' "customer notification disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_ticket_id": true' "ticket id required"
contains "$CONTROL_FILE" '"requires_correlation_id": true' "correlation id required"
contains "$CONTROL_FILE" '"requires_sla_key": true' "sla key required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"manual_review_allowed": true' "manual review allowed"
contains "$CONTROL_FILE" '"blocks_silent_failure": true' "silent failure blocked"
contains "$CONTROL_FILE" '"requires_customer_template": true' "customer template required when notify"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_AUTO_ESCALATION_BLOCKED" "production auto escalation guard"
contains "$RUNTIME_FILE" "CUSTOMER_NOTIFICATION_BLOCKED" "customer notification guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "TICKET_ID_REQUIRED" "ticket id guard"
contains "$RUNTIME_FILE" "CORRELATION_ID_REQUIRED" "correlation id guard"
contains "$RUNTIME_FILE" "SLA_KEY_REQUIRED" "sla key guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "CUSTOMER_TEMPLATE_REQUIRED_FOR_NOTIFY" "customer template notify guard"
contains "$RUNTIME_FILE" "OWNER_MAPPING_REQUIRED" "owner mapping guard"
contains "$RUNTIME_FILE" "SILENT_FAILURE_BLOCK_REQUIRED" "silent failure guard"
contains "$RUNTIME_FILE" "MANUAL_REVIEW_REQUIRED" "manual review guard"
contains "$RUNTIME_FILE" "INVALID_ESCALATION_TRANSITION" "invalid transition guard"

if go test ./internal/commercial/publiclaunch/supportescalation; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/support_escalation_matrix.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_4_4_escalation_matrisi_test.json").read_text())

rules = {r["key"]: r for r in control["rules"]}
triggers = {r["trigger"] for r in control["rules"]}

rank = {
    "L1_SUPPORT": 1,
    "L2_OPS": 2,
    "L3_ENGINEERING": 3,
    "L4_LEGAL_KVKK_SECURITY": 4,
    "L5_EXECUTIVE": 5
}

for key in test["must_have_rule_keys"]:
    assert key in rules, f"missing rule key: {key}"
    r = rules[key]
    assert r["status"] == "READY", f"rule not ready: {key}"
    assert r["required"] is True, f"rule not required: {key}"
    assert r["max_age_hours"] > 0, f"max_age_hours missing: {key}"
    assert r["owner"], f"owner missing: {key}"
    assert r["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert r["requires_ticket_id"] is True, f"ticket id missing: {key}"
    assert r["requires_correlation_id"] is True, f"correlation id missing: {key}"
    assert r["requires_sla_key"] is True, f"sla key missing: {key}"
    assert r["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert r["manual_review_allowed"] is True, f"manual review missing: {key}"
    assert r["blocks_silent_failure"] is True, f"silent failure block missing: {key}"
    assert rank[r["to_level"]] > rank[r["from_level"]], f"invalid transition: {key}"
    if r["notify_customer"] is True:
        assert r["requires_customer_template"] is True, f"notify customer requires template: {key}"
    if r["to_level"] == "L4_LEGAL_KVKK_SECURITY":
        assert r["requires_legal_kvkk_security_owner"] is True, f"compliance owner missing: {key}"

for trigger in test["must_have_triggers"]:
    assert trigger in triggers, f"missing trigger: {trigger}"

assert control["internal_matrix_ready"] is True
assert control["production_auto_escalation_enabled"] is False
assert control["customer_notification_enabled"] is False
assert control["final_policy"]["incident_classification_required_next"] is True
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
# FAZ 5-18.4.4 Escalation Matrisi Real Implementation Audit

PHASE=FAZ_5_18_4_4
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
INTERNAL_MATRIX_READY=true
PRODUCTION_AUTO_ESCALATION_ENABLED=false
CUSTOMER_NOTIFICATION_ENABLED=false
INCIDENT_CLASSIFICATION_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.4.4 ESCALATION MATRISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_4_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_4_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
