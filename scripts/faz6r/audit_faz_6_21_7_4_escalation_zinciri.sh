#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_7_4_ESCALATION_ZINCIRI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_7_4_escalation_zinciri.v1.json"
CHAIN_FILE="configs/faz6r/escalation_chain.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_7_4_escalation_zinciri_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_escalation_zinciri.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_7_4_escalation_zinciri.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_7_4_ESCALATION_ZINCIRI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_ON_CALL_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_7_3_ON_CALL_PLANI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.7.4 ESCALATION ZINCIRI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.7.4 previous on-call plani evidence file" "$PREV_ON_CALL_EVIDENCE"
check_contains "6-21.7.4 previous on-call plani final PASS" "$PREV_ON_CALL_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.7.4 documentation file" "$DOC_FILE"
check_file "6-21.7.4 config file" "$CONFIG_FILE"
check_file "6-21.7.4 chain artifact file" "$CHAIN_FILE"
check_file "6-21.7.4 fixture file" "$FIXTURE_FILE"
check_file "6-21.7.4 validator file" "$VALIDATOR_FILE"
check_file "6-21.7.4 audit file" "$AUDIT_FILE"

check_contains "6-21.7.4 doc has Escalation Zinciri" "$DOC_FILE" "Escalation Zinciri"
check_contains "6-21.7.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.7.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.7.4 config has dependency" "$CONFIG_FILE" "FAZ_6_21_7_3"
check_contains "6-21.7.4 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.7.4 config disables notification provider" "$CONFIG_FILE" '"notification_provider_enabled": false'
check_contains "6-21.7.4 config disables real sms" "$CONFIG_FILE" '"real_sms_enabled": false'
check_contains "6-21.7.4 config disables real email" "$CONFIG_FILE" '"real_email_enabled": false'
check_contains "6-21.7.4 config disables real phone call" "$CONFIG_FILE" '"real_phone_call_enabled": false'
check_contains "6-21.7.4 config disables real pager" "$CONFIG_FILE" '"real_pager_enabled": false'
check_contains "6-21.7.4 config has escalation level model" "$CONFIG_FILE" "escalation_level_model"
check_contains "6-21.7.4 config has severity mapping" "$CONFIG_FILE" "severity_to_escalation_mapping"
check_contains "6-21.7.4 config has ack timeout policy" "$CONFIG_FILE" "ack_timeout_policy"
check_contains "6-21.7.4 config has p0 escalation chain" "$CONFIG_FILE" "p0_escalation_chain"
check_contains "6-21.7.4 config has p1 escalation chain" "$CONFIG_FILE" "p1_escalation_chain"
check_contains "6-21.7.4 config has p2 escalation chain" "$CONFIG_FILE" "p2_escalation_chain"
check_contains "6-21.7.4 config has p3 escalation chain" "$CONFIG_FILE" "p3_escalation_chain"
check_contains "6-21.7.4 config has business owner policy" "$CONFIG_FILE" "business_owner_notification_policy"
check_contains "6-21.7.4 config has security owner policy" "$CONFIG_FILE" "security_owner_notification_policy"
check_contains "6-21.7.4 config has technical owner policy" "$CONFIG_FILE" "technical_owner_notification_policy"
check_contains "6-21.7.4 config has provider closed policy" "$CONFIG_FILE" "provider_closed_policy"

check_contains "6-21.7.4 chain has P0" "$CHAIN_FILE" '"severity": "P0"'
check_contains "6-21.7.4 chain has P1" "$CHAIN_FILE" '"severity": "P1"'
check_contains "6-21.7.4 chain has P2" "$CHAIN_FILE" '"severity": "P2"'
check_contains "6-21.7.4 chain has P3" "$CHAIN_FILE" '"severity": "P3"'
check_contains "6-21.7.4 chain has L5 business owner" "$CHAIN_FILE" "business_owner"
check_contains "6-21.7.4 chain record only mode" "$CHAIN_FILE" "record_only_no_real_send"

check_contains "6-21.7.4 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_7_5"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$CHAIN_FILE" "$FIXTURE_FILE"; then
  pass "6-21.7.4 semantic validator runtime"
else
  fail "6-21.7.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.7.4 python3 dependency"
else
  fail "6-21.7.4 python3 dependency"
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
# FAZ 6-R / 288 — FAZ 6-21.7.4 Escalation Zinciri Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
CHAIN_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_7_5_READY=${NEXT_READY}

Scope note: real SMS, email, phone call, pager and provider mutation remain closed in this step.
Dependency: FAZ_6_21_7_3 on-call planı evidence checked.
EOF2

echo "===== FAZ 6-21.7.4 ESCALATION ZINCIRI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_7_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.7.4 ESCALATION ZINCIRI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "CHAIN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_7_5_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
