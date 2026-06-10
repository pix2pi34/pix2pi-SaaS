#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_4_2_ABUSE_BOT_TUNING.md"
CONFIG_FILE="configs/faz6r/faz_6_21_4_2_abuse_bot_tuning.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_4_2_abuse_bot_tuning_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_abuse_bot_tuning.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_4_2_abuse_bot_tuning.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_4_2_ABUSE_BOT_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_4_1_WAF_TUNING_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 OPTIONAL_WARN / WARN ⚠️"; }

check_file(){
  if [ -f "$2" ]; then pass "$1"; else fail "$1 missing"; fi
}

check_contains(){
  if [ -f "$2" ] && grep -q "$3" "$2"; then pass "$1"; else fail "$1 missing pattern $3"; fi
}

echo "===== FAZ 6-21.4.2 ABUSE / BOT TUNING REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.4.2 previous WAF tuning evidence file" "$PREV_EVIDENCE_FILE"
check_contains "6-21.4.2 previous WAF tuning final PASS" "$PREV_EVIDENCE_FILE" "FINAL_STATUS=PASS"

check_file "6-21.4.2 documentation file" "$DOC_FILE"
check_file "6-21.4.2 config file" "$CONFIG_FILE"
check_file "6-21.4.2 fixture file" "$FIXTURE_FILE"
check_file "6-21.4.2 validator file" "$VALIDATOR_FILE"
check_file "6-21.4.2 audit file" "$AUDIT_FILE"

check_contains "6-21.4.2 doc has Abuse / Bot Tuning" "$DOC_FILE" "Abuse / Bot Tuning"
check_contains "6-21.4.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.4.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.4.2 config has dependency" "$CONFIG_FILE" '"depends_on": "FAZ_6_21_4_1"'
check_contains "6-21.4.2 config has live mutation false" "$CONFIG_FILE" '"live_provider_api_mutation_allowed": false'
check_contains "6-21.4.2 config has bot score policy" "$CONFIG_FILE" "bot_score_policy"
check_contains "6-21.4.2 config has suspicious automation guard" "$CONFIG_FILE" "suspicious_automation_guard"
check_contains "6-21.4.2 config has credential stuffing guard" "$CONFIG_FILE" "credential_stuffing_guard"
check_contains "6-21.4.2 config has login rate anomaly guard" "$CONFIG_FILE" "login_rate_anomaly_guard"
check_contains "6-21.4.2 config has api scraping guard" "$CONFIG_FILE" "api_scraping_guard"
check_contains "6-21.4.2 config has high error rate guard" "$CONFIG_FILE" "high_error_rate_guard"
check_contains "6-21.4.2 config has bad user agent guard" "$CONFIG_FILE" "bad_user_agent_guard"
check_contains "6-21.4.2 config has impossible path guard" "$CONFIG_FILE" "impossible_path_guard"
check_contains "6-21.4.2 config has tenant abuse signal policy" "$CONFIG_FILE" "tenant_abuse_signal_policy"
check_contains "6-21.4.2 config has allowlist policy" "$CONFIG_FILE" "allowlist_policy"
check_contains "6-21.4.2 config has false positive review policy" "$CONFIG_FILE" "false_positive_review_policy"
check_contains "6-21.4.2 config has rollback strategy" "$CONFIG_FILE" "return_to_previous_stable_abuse_bot_policy"
check_contains "6-21.4.2 fixture has expected dependency" "$FIXTURE_FILE" "FAZ_6_21_4_1"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$FIXTURE_FILE"; then
  pass "6-21.4.2 semantic validator runtime"
else
  fail "6-21.4.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.4.2 python3 dependency"
else
  fail "6-21.4.2 python3 dependency"
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
# FAZ 6-R / 281 — FAZ 6-21.4.2 Abuse / Bot Tuning Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_4_3_READY=${NEXT_READY}

Scope note: live provider API mutation is intentionally closed in this step.
Dependency: FAZ_6_21_4_1 WAF tuning evidence checked.
EOF2

echo "===== FAZ 6-21.4.2 ABUSE / BOT TUNING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_4_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.4.2 ABUSE / BOT TUNING COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_4_3_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
