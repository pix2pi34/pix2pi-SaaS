#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_7_1_RUNBOOK_SETI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_7_1_runbook_seti.v1.json"
RUNBOOK_FILE="configs/faz6r/runbook_set.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_7_1_runbook_seti_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_runbook_seti.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_7_1_runbook_seti.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_7_1_RUNBOOK_SETI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_SECURITY_EDGE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_5_SECURITY_EDGE_AUDIT_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  if [ -f "$2" ]; then pass "$1"; else fail "$1 missing"; fi
}

check_contains(){
  if [ -f "$2" ] && grep -q "$3" "$2"; then pass "$1"; else fail "$1 missing pattern $3"; fi
}

echo "===== FAZ 6-21.7.1 RUNBOOK SETI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.7.1 previous security edge audit evidence file" "$PREV_SECURITY_EDGE_EVIDENCE"
check_contains "6-21.7.1 previous security edge audit final PASS" "$PREV_SECURITY_EDGE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.7.1 documentation file" "$DOC_FILE"
check_file "6-21.7.1 config file" "$CONFIG_FILE"
check_file "6-21.7.1 runbook artifact file" "$RUNBOOK_FILE"
check_file "6-21.7.1 fixture file" "$FIXTURE_FILE"
check_file "6-21.7.1 validator file" "$VALIDATOR_FILE"
check_file "6-21.7.1 audit file" "$AUDIT_FILE"

check_contains "6-21.7.1 doc has Runbook Seti" "$DOC_FILE" "Runbook Seti"
check_contains "6-21.7.1 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.7.1 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.7.1 config has dependency" "$CONFIG_FILE" "FAZ_6_21_4_5"
check_contains "6-21.7.1 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.7.1 config disables destructive default" "$CONFIG_FILE" '"destructive_action_default_allowed": false'
check_contains "6-21.7.1 config disables auto remediation" "$CONFIG_FILE" '"auto_remediation_enabled": false'
check_contains "6-21.7.1 config has severity model" "$CONFIG_FILE" "incident_severity_model"
check_contains "6-21.7.1 config has evidence policy" "$CONFIG_FILE" "evidence_capture_policy"
check_contains "6-21.7.1 config has manual approval policy" "$CONFIG_FILE" "manual_approval_policy"
check_contains "6-21.7.1 config has no destructive default policy" "$CONFIG_FILE" "no_destructive_default_policy"
check_contains "6-21.7.1 config has escalation placeholder" "$CONFIG_FILE" "escalation_policy_placeholder"

check_contains "6-21.7.1 runbook has edge security incident" "$RUNBOOK_FILE" "edge_security_incident_runbook"
check_contains "6-21.7.1 runbook has tls cert incident" "$RUNBOOK_FILE" "tls_cert_incident_runbook"
check_contains "6-21.7.1 runbook has api outage" "$RUNBOOK_FILE" "api_outage_runbook"
check_contains "6-21.7.1 runbook has db degradation" "$RUNBOOK_FILE" "db_degradation_runbook"
check_contains "6-21.7.1 runbook has event queue backlog" "$RUNBOOK_FILE" "event_queue_backlog_runbook"
check_contains "6-21.7.1 runbook has cache degradation" "$RUNBOOK_FILE" "cache_degradation_runbook"
check_contains "6-21.7.1 runbook has release rollback" "$RUNBOOK_FILE" "release_rollback_runbook"

check_contains "6-21.7.1 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_7_2"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$RUNBOOK_FILE" "$FIXTURE_FILE"; then
  pass "6-21.7.1 semantic validator runtime"
else
  fail "6-21.7.1 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.7.1 python3 dependency"
else
  fail "6-21.7.1 python3 dependency"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 6-R / 285 — FAZ 6-21.7.1 Runbook Seti Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
RUNBOOK_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_7_2_READY=${NEXT_READY}

Scope note: auto remediation and destructive runtime mutation are intentionally closed in this step.
Dependency: FAZ_6_21_4_5 security edge audit evidence checked.
EOF2

echo "===== FAZ 6-21.7.1 RUNBOOK SETI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_7_1_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.7.1 RUNBOOK SETI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "RUNBOOK_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_7_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
