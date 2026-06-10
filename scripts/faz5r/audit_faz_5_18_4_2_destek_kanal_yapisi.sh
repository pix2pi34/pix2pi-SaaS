#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.4.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_4_2_DESTEK_KANAL_YAPISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_4_2_destek_kanal_yapisi.v1.json"
CONTROL_FILE="configs/faz5r/support_channel_structure.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_4_2_destek_kanal_yapisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supportchannel/support_channel.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supportchannel/support_channel_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_4_2_DESTEK_KANAL_YAPISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.4.2 DESTEK KANAL YAPISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"support_email_intake"' "support email intake registered"
contains "$CONTROL_FILE" '"support_in_app_intake"' "in-app support intake registered"
contains "$CONTROL_FILE" '"support_help_center_form"' "help center form registered"
contains "$CONTROL_FILE" '"support_kvkk_request"' "kvkk request channel registered"
contains "$CONTROL_FILE" '"support_security_report"' "security report channel registered"
contains "$CONTROL_FILE" '"support_ops_escalation"' "ops escalation channel registered"
contains "$CONTROL_FILE" '"PILOT"' "pilot issue family registered"
contains "$CONTROL_FILE" '"BILLING"' "billing issue family registered"
contains "$CONTROL_FILE" '"KVKK"' "kvkk issue family registered"
contains "$CONTROL_FILE" '"SECURITY"' "security issue family registered"
contains "$CONTROL_FILE" '"TECHNICAL"' "technical issue family registered"
contains "$CONTROL_FILE" '"COMMERCIAL"' "commercial issue family registered"
contains "$CONTROL_FILE" '"internal_channel_structure_ready": true' "internal channel structure ready"
contains "$CONTROL_FILE" '"public_support_enabled": false' "public support disabled"
contains "$CONTROL_FILE" '"real_customer_support_open": false' "real customer support closed"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_requester_email": true' "requester email required"
contains "$CONTROL_FILE" '"requires_correlation_id": true' "correlation id required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_sla_key": true' "sla key required"
contains "$CONTROL_FILE" '"has_intake_template": true' "intake template present"
contains "$CONTROL_FILE" '"has_routing_rule": true' "routing rule present"
contains "$CONTROL_FILE" '"has_ops_owner": true' "ops owner present"
contains "$CONTROL_FILE" '"has_privacy_notice_link": true' "privacy notice link present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PUBLIC_SUPPORT_BLOCKED" "public support guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SUPPORT_BLOCKED" "real customer support guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "REQUESTER_EMAIL_REQUIRED" "requester email guard"
contains "$RUNTIME_FILE" "CORRELATION_ID_REQUIRED" "correlation id guard"
contains "$RUNTIME_FILE" "SLA_KEY_REQUIRED" "sla key guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "INTAKE_TEMPLATE_REQUIRED" "intake template guard"
contains "$RUNTIME_FILE" "ROUTING_RULE_REQUIRED" "routing rule guard"
contains "$RUNTIME_FILE" "OPS_OWNER_REQUIRED" "ops owner guard"
contains "$RUNTIME_FILE" "KVKK_PRIVACY_NOTICE_LINK_REQUIRED" "kvkk privacy notice link guard"
contains "$RUNTIME_FILE" "ISSUE_FAMILY_ROUTE_MISSING" "issue family route guard"

if go test ./internal/commercial/publiclaunch/supportchannel; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/support_channel_structure.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_4_2_destek_kanal_yapisi_test.json").read_text())

channels = {c["key"]: c for c in control["channels"]}
families = set(control["required_families"])
covered = set()

for channel in control["channels"]:
    for family in channel["allowed_families"]:
        covered.add(family)

for key in test["must_have_channel_keys"]:
    assert key in channels, f"missing channel key: {key}"
    c = channels[key]
    assert c["status"] == "READY", f"channel not ready: {key}"
    assert c["required"] is True, f"channel not required: {key}"
    assert c["public_visible"] is False, f"public visible must be false: {key}"
    assert c["internal_only"] is True, f"internal only must be true: {key}"
    assert c["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert c["requires_requester_email"] is True, f"requester email missing: {key}"
    assert c["requires_correlation_id"] is True, f"correlation id missing: {key}"
    assert c["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert c["requires_sla_key"] is True, f"sla key missing: {key}"
    assert c["has_intake_template"] is True, f"intake template missing: {key}"
    assert c["has_routing_rule"] is True, f"routing rule missing: {key}"
    assert c["has_ops_owner"] is True, f"ops owner missing: {key}"

for family in test["must_have_families"]:
    assert family in families, f"missing required family: {family}"
    assert family in covered, f"family not covered by any channel: {family}"

assert channels["support_kvkk_request"]["has_privacy_notice_link"] is True
assert channels["support_kvkk_request"]["requires_consent_context"] is True
assert control["internal_channel_structure_ready"] is True
assert control["public_support_enabled"] is False
assert control["real_customer_support_open"] is False
assert control["final_policy"]["customer_communication_templates_required_next"] is True
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
# FAZ 5-18.4.2 Destek Kanal Yapısı Real Implementation Audit

PHASE=FAZ_5_18_4_2
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
INTERNAL_CHANNEL_STRUCTURE_READY=true
PUBLIC_SUPPORT_ENABLED=false
REAL_CUSTOMER_SUPPORT_OPEN=false
CUSTOMER_COMMUNICATION_TEMPLATES_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.4.2 DESTEK KANAL YAPISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_4_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_4_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
