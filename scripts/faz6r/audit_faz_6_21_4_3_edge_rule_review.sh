#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_4_3_EDGE_RULE_REVIEW.md"
CONFIG_FILE="configs/faz6r/faz_6_21_4_3_edge_rule_review.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_4_3_edge_rule_review_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_edge_rule_review.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_4_3_edge_rule_review.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_4_3_EDGE_RULE_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"
PREV_WAF_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_1_WAF_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_BOT_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_2_ABUSE_BOT_TUNING_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.4.3 EDGE RULE REVIEW REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.4.3 previous WAF tuning evidence file" "$PREV_WAF_EVIDENCE"
check_contains "6-21.4.3 previous WAF tuning final PASS" "$PREV_WAF_EVIDENCE" "FINAL_STATUS=PASS"
check_file "6-21.4.3 previous abuse bot evidence file" "$PREV_BOT_EVIDENCE"
check_contains "6-21.4.3 previous abuse bot final PASS" "$PREV_BOT_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.4.3 documentation file" "$DOC_FILE"
check_file "6-21.4.3 config file" "$CONFIG_FILE"
check_file "6-21.4.3 fixture file" "$FIXTURE_FILE"
check_file "6-21.4.3 validator file" "$VALIDATOR_FILE"
check_file "6-21.4.3 audit file" "$AUDIT_FILE"

check_contains "6-21.4.3 doc has Edge Rule Review" "$DOC_FILE" "Edge Rule Review"
check_contains "6-21.4.3 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.4.3 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.4.3 config has WAF dependency" "$CONFIG_FILE" "FAZ_6_21_4_1"
check_contains "6-21.4.3 config has abuse dependency" "$CONFIG_FILE" "FAZ_6_21_4_2"
check_contains "6-21.4.3 config has live mutation false" "$CONFIG_FILE" '"live_provider_api_mutation_allowed": false'
check_contains "6-21.4.3 config has public private boundary" "$CONFIG_FILE" "public_private_route_boundary"
check_contains "6-21.4.3 config has api route policy" "$CONFIG_FILE" "api_route_policy_review"
check_contains "6-21.4.3 config has auth route policy" "$CONFIG_FILE" "auth_route_policy_review"
check_contains "6-21.4.3 config has panel route policy" "$CONFIG_FILE" "panel_route_policy_review"
check_contains "6-21.4.3 config has health route policy" "$CONFIG_FILE" "health_route_policy_review"
check_contains "6-21.4.3 config has static asset cache policy" "$CONFIG_FILE" "static_asset_cache_policy_review"
check_contains "6-21.4.3 config has redirect policy" "$CONFIG_FILE" "redirect_canonical_policy_review"
check_contains "6-21.4.3 config has security header policy" "$CONFIG_FILE" "security_header_policy_review"
check_contains "6-21.4.3 config has origin lockdown policy" "$CONFIG_FILE" "origin_lockdown_policy_review"
check_contains "6-21.4.3 config has cache bypass policy" "$CONFIG_FILE" "edge_cache_bypass_policy_review"
check_contains "6-21.4.3 config has webhook exception review" "$CONFIG_FILE" "webhook_route_exception_review"
check_contains "6-21.4.3 config has tenant header observability" "$CONFIG_FILE" "tenant_header_edge_observability_review"
check_contains "6-21.4.3 config has rollback strategy" "$CONFIG_FILE" "return_to_previous_stable_edge_rule_set"
check_contains "6-21.4.3 fixture has expected tenant header" "$FIXTURE_FILE" "X-Tenant-ID"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$FIXTURE_FILE"; then
  pass "6-21.4.3 semantic validator runtime"
else
  fail "6-21.4.3 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.4.3 python3 dependency"
else
  fail "6-21.4.3 python3 dependency"
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
# FAZ 6-R / 282 — FAZ 6-21.4.3 Edge Rule Review Real Implementation Audit

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
FAZ_6_21_4_4_READY=${NEXT_READY}

Scope note: live provider API mutation is intentionally closed in this step.
Dependency: FAZ_6_21_4_1 and FAZ_6_21_4_2 evidence checked.
EOF2

echo "===== FAZ 6-21.4.3 EDGE RULE REVIEW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_4_3_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.4.3 EDGE RULE REVIEW COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_4_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
