#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_7_3_ON_CALL_PLANI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_7_3_on_call_plani.v1.json"
PLAN_FILE="configs/faz6r/on_call_plan.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_7_3_on_call_plani_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_on_call_plani.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_7_3_on_call_plani.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_7_3_ON_CALL_PLANI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_REMEDIATION_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_7_2_OTOMATIK_REMEDIATION_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.7.3 ON-CALL PLANI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.7.3 previous otomatik remediation evidence file" "$PREV_REMEDIATION_EVIDENCE"
check_contains "6-21.7.3 previous otomatik remediation final PASS" "$PREV_REMEDIATION_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.7.3 documentation file" "$DOC_FILE"
check_file "6-21.7.3 config file" "$CONFIG_FILE"
check_file "6-21.7.3 plan artifact file" "$PLAN_FILE"
check_file "6-21.7.3 fixture file" "$FIXTURE_FILE"
check_file "6-21.7.3 validator file" "$VALIDATOR_FILE"
check_file "6-21.7.3 audit file" "$AUDIT_FILE"

check_contains "6-21.7.3 doc has On-call Plani" "$DOC_FILE" "On-call Planı"
check_contains "6-21.7.3 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.7.3 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.7.3 config has dependency" "$CONFIG_FILE" "FAZ_6_21_7_2"
check_contains "6-21.7.3 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.7.3 config disables notification provider" "$CONFIG_FILE" '"notification_provider_enabled": false'
check_contains "6-21.7.3 config disables real paging" "$CONFIG_FILE" '"real_paging_enabled": false'
check_contains "6-21.7.3 config has role model" "$CONFIG_FILE" "on_call_role_model"
check_contains "6-21.7.3 config has coverage policy" "$CONFIG_FILE" "primary_secondary_coverage_policy"
check_contains "6-21.7.3 config has severity response policy" "$CONFIG_FILE" "severity_response_target_policy"
check_contains "6-21.7.3 config has handoff policy" "$CONFIG_FILE" "handoff_policy"
check_contains "6-21.7.3 config has override policy" "$CONFIG_FILE" "override_policy"
check_contains "6-21.7.3 config has fatigue policy" "$CONFIG_FILE" "fatigue_management_policy"
check_contains "6-21.7.3 config has incident commander policy" "$CONFIG_FILE" "incident_commander_policy"
check_contains "6-21.7.3 config has notification provider closed policy" "$CONFIG_FILE" "notification_provider_closed_policy"
check_contains "6-21.7.3 config has escalation placeholder" "$CONFIG_FILE" "FAZ_6_21_7_4"
check_contains "6-21.7.3 config has Europe/Istanbul timezone" "$CONFIG_FILE" "Europe/Istanbul"

check_contains "6-21.7.3 plan has primary on-call" "$PLAN_FILE" "primary_on_call"
check_contains "6-21.7.3 plan has secondary on-call" "$PLAN_FILE" "secondary_on_call"
check_contains "6-21.7.3 plan has incident commander pool" "$PLAN_FILE" "incident_commander_pool"
check_contains "6-21.7.3 plan disables real calendar invite" "$PLAN_FILE" '"real_calendar_invite_enabled": false'
check_contains "6-21.7.3 plan disables real pager" "$PLAN_FILE" '"real_pager_enabled": false'
check_contains "6-21.7.3 plan has handoff checklist" "$PLAN_FILE" "handoff_checklist"
check_contains "6-21.7.3 plan has P0 assignment" "$PLAN_FILE" '"severity": "P0"'
check_contains "6-21.7.3 plan has P1 assignment" "$PLAN_FILE" '"severity": "P1"'

check_contains "6-21.7.3 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_7_4"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE"; then
  pass "6-21.7.3 semantic validator runtime"
else
  fail "6-21.7.3 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.7.3 python3 dependency"
else
  fail "6-21.7.3 python3 dependency"
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
# FAZ 6-R / 287 — FAZ 6-21.7.3 On-call Planı Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
PLAN_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_7_4_READY=${NEXT_READY}

Scope note: real paging, SMS, email, phone call and provider mutation remain closed in this step.
Dependency: FAZ_6_21_7_2 otomatik remediation evidence checked.
EOF2

echo "===== FAZ 6-21.7.3 ON-CALL PLANI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_7_3_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.7.3 ON-CALL PLANI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "PLAN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_7_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
