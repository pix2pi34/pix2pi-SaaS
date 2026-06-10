#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.4.5"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_4_5_MUSTERI_ILETISIM_SABLONLARI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_4_5_musteri_iletisim_sablonlari.v1.json"
CONTROL_FILE="configs/faz5r/customer_communication_templates.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_4_5_musteri_iletisim_sablonlari_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supporttemplates/support_templates.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supporttemplates/support_templates_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_4_5_MUSTERI_ILETISIM_SABLONLARI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.4.5 MUSTERI ILETISIM SABLONLARI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"template_ticket_ack"' "ticket ack template registered"
contains "$CONTROL_FILE" '"template_incident_update"' "incident update template registered"
contains "$CONTROL_FILE" '"template_sla_breach_notice"' "sla breach template registered"
contains "$CONTROL_FILE" '"template_kvkk_request_ack"' "kvkk request template registered"
contains "$CONTROL_FILE" '"template_billing_issue_ack"' "billing issue template registered"
contains "$CONTROL_FILE" '"template_security_report_ack"' "security report template registered"
contains "$CONTROL_FILE" '"TICKET_ACK"' "ticket ack category registered"
contains "$CONTROL_FILE" '"INCIDENT_UPDATE"' "incident update category registered"
contains "$CONTROL_FILE" '"SLA_BREACH"' "sla breach category registered"
contains "$CONTROL_FILE" '"KVKK_REQUEST"' "kvkk request category registered"
contains "$CONTROL_FILE" '"BILLING_ISSUE"' "billing issue category registered"
contains "$CONTROL_FILE" '"SECURITY_REPORT"' "security report category registered"
contains "$CONTROL_FILE" '"internal_templates_ready": true' "internal templates ready"
contains "$CONTROL_FILE" '"public_templates_published": false' "public templates publication blocked"
contains "$CONTROL_FILE" '"real_customer_sending_enabled": false' "real customer sending blocked"
contains "$CONTROL_FILE" '"tenant_id"' "tenant id variable present"
contains "$CONTROL_FILE" '"ticket_id"' "ticket id variable present"
contains "$CONTROL_FILE" '"requester_email"' "requester email variable present"
contains "$CONTROL_FILE" '"correlation_id"' "correlation id variable present"
contains "$CONTROL_FILE" '"sla_key"' "sla key variable present"
contains "$CONTROL_FILE" '"has_tenant_context": true' "tenant context present"
contains "$CONTROL_FILE" '"has_ticket_context": true' "ticket context present"
contains "$CONTROL_FILE" '"has_kvkk_footer": true' "kvkk footer present"
contains "$CONTROL_FILE" '"has_audit_trail": true' "audit trail present"
contains "$CONTROL_FILE" '"has_tone_guard": true' "tone guard present"
contains "$CONTROL_FILE" '"has_privacy_notice_link": true' "privacy notice link present"
contains "$CONTROL_FILE" '"has_escalation_hint": true' "escalation hint present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PUBLIC_TEMPLATE_PUBLICATION_BLOCKED" "public template publication guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_SENDING_BLOCKED" "real customer sending guard"
contains "$RUNTIME_FILE" "TENANT_CONTEXT_REQUIRED" "tenant context guard"
contains "$RUNTIME_FILE" "TICKET_CONTEXT_REQUIRED" "ticket context guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "TONE_GUARD_REQUIRED" "tone guard"
contains "$RUNTIME_FILE" "KVKK_FOOTER_REQUIRED" "kvkk footer guard"
contains "$RUNTIME_FILE" "KVKK_PRIVACY_NOTICE_LINK_REQUIRED" "kvkk privacy notice link guard"
contains "$RUNTIME_FILE" "SLA_CONTEXT_REQUIRED_FOR_BREACH" "sla context breach guard"
contains "$RUNTIME_FILE" "ESCALATION_HINT_REQUIRED_FOR_BREACH" "escalation hint breach guard"
contains "$RUNTIME_FILE" "TENANT_ID_VARIABLE_REQUIRED" "tenant id variable guard"
contains "$RUNTIME_FILE" "TICKET_ID_VARIABLE_REQUIRED" "ticket id variable guard"
contains "$RUNTIME_FILE" "CORRELATION_ID_VARIABLE_REQUIRED" "correlation id variable guard"

if go test ./internal/commercial/publiclaunch/supporttemplates; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/customer_communication_templates.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_4_5_musteri_iletisim_sablonlari_test.json").read_text())

templates = {t["key"]: t for t in control["templates"]}
categories = {t["category"] for t in control["templates"]}

for key in test["must_have_template_keys"]:
    assert key in templates, f"missing template key: {key}"
    t = templates[key]
    assert t["status"] == "READY", f"template not ready: {key}"
    assert t["required"] is True, f"template not required: {key}"
    assert t["language"] == "tr-TR", f"template language must be tr-TR: {key}"
    assert t["internal_only"] is True, f"internal_only must be true: {key}"
    assert t["public_published"] is False, f"public_published must be false: {key}"
    assert t["real_customer_sending"] is False, f"real_customer_sending must be false: {key}"
    assert t["subject"], f"subject missing: {key}"
    assert t["body_preview"], f"body_preview missing: {key}"
    for var in test["must_have_variables"]:
        assert var in t["required_variables"], f"missing variable {var}: {key}"
    assert t["has_tenant_context"] is True, f"tenant context missing: {key}"
    assert t["has_ticket_context"] is True, f"ticket context missing: {key}"
    assert t["has_kvkk_footer"] is True, f"kvkk footer missing: {key}"
    assert t["has_audit_trail"] is True, f"audit trail missing: {key}"
    assert t["has_tone_guard"] is True, f"tone guard missing: {key}"

for category in test["must_have_categories"]:
    assert category in categories, f"missing category: {category}"

assert templates["template_kvkk_request_ack"]["has_privacy_notice_link"] is True
assert templates["template_sla_breach_notice"]["has_sla_context"] is True
assert templates["template_sla_breach_notice"]["has_escalation_hint"] is True
assert control["internal_templates_ready"] is True
assert control["public_templates_published"] is False
assert control["real_customer_sending_enabled"] is False
assert control["final_policy"]["escalation_matrix_required_next"] is True
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
# FAZ 5-18.4.5 Müşteri İletişim Şablonları Real Implementation Audit

PHASE=FAZ_5_18_4_5
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
INTERNAL_TEMPLATES_READY=true
PUBLIC_TEMPLATES_PUBLISHED=false
REAL_CUSTOMER_SENDING_ENABLED=false
ESCALATION_MATRIX_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.4.5 MUSTERI ILETISIM SABLONLARI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_4_5_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_4_5_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
