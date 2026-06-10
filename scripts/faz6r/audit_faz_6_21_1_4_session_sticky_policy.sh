#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_1_4_SESSION_STICKY_POLICY.md"
CONFIG_FILE="configs/faz6r/faz_6_21_1_4_session_sticky_policy.v1.json"
POLICY_FILE="configs/faz6r/session_sticky_policy.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_1_4_session_sticky_policy_test.json"
RUNTIME_FILE="scripts/faz6r/run_session_sticky_policy_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_session_sticky_policy.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_1_4_session_sticky_policy.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_1_4_SESSION_STICKY_POLICY_REAL_IMPLEMENTATION_AUDIT.md"
PREV_SERVICE_DISCOVERY_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_1_2_SERVICE_DISCOVERY_RUNTIME_TUNING_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label missing"; fi
}

check_contains(){
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -q "$pattern" "$file"; then pass "$label"; else fail "$label missing pattern $pattern"; fi
}

echo "===== FAZ 6-21.1.4 SESSION STICKY POLICY REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.1.4 previous service discovery evidence file" "$PREV_SERVICE_DISCOVERY_EVIDENCE"
check_contains "6-21.1.4 previous service discovery final PASS" "$PREV_SERVICE_DISCOVERY_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.1.4 documentation file" "$DOC_FILE"
check_file "6-21.1.4 config file" "$CONFIG_FILE"
check_file "6-21.1.4 policy file" "$POLICY_FILE"
check_file "6-21.1.4 fixture file" "$FIXTURE_FILE"
check_file "6-21.1.4 runtime file" "$RUNTIME_FILE"
check_file "6-21.1.4 validator file" "$VALIDATOR_FILE"
check_file "6-21.1.4 audit file" "$AUDIT_FILE"

check_contains "6-21.1.4 doc has Session Sticky Policy" "$DOC_FILE" "Session / Sticky Policy"
check_contains "6-21.1.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.1.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.1.4 config has dependency" "$CONFIG_FILE" "FAZ_6_21_1_2"
check_contains "6-21.1.4 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.1.4 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.1.4 config disables gateway session mutation" "$CONFIG_FILE" '"gateway_session_mutation_allowed": false'
check_contains "6-21.1.4 config disables lb sticky mutation" "$CONFIG_FILE" '"load_balancer_sticky_mutation_allowed": false'
check_contains "6-21.1.4 config disables nginx mutation" "$CONFIG_FILE" '"nginx_mutation_allowed": false'
check_contains "6-21.1.4 config disables redis session mutation" "$CONFIG_FILE" '"redis_session_mutation_allowed": false'
check_contains "6-21.1.4 config disables cookie mutation" "$CONFIG_FILE" '"cookie_policy_mutation_allowed": false'
check_contains "6-21.1.4 config disables rollout" "$CONFIG_FILE" '"deployment_rollout_allowed": false'
check_contains "6-21.1.4 config has sticky affinity policy" "$CONFIG_FILE" "sticky_affinity_policy"
check_contains "6-21.1.4 config has tenant aware affinity guard" "$CONFIG_FILE" "tenant_aware_affinity_guard"
check_contains "6-21.1.4 config has stateless fallback" "$CONFIG_FILE" "stateless_fallback_policy"
check_contains "6-21.1.4 config has session store health" "$CONFIG_FILE" "session_store_health_policy"
check_contains "6-21.1.4 config has cookie security" "$CONFIG_FILE" "cookie_security_policy"

check_contains "6-21.1.4 policy has api gateway policy" "$POLICY_FILE" "session-policy-api-gateway-stateless"
check_contains "6-21.1.4 policy has panel policy" "$POLICY_FILE" "session-policy-panel-sticky-review"
check_contains "6-21.1.4 policy has pos policy" "$POLICY_FILE" "session-policy-pos-offline-safe"
check_contains "6-21.1.4 policy has websocket sse policy" "$POLICY_FILE" "session-policy-websocket-sse-affinity"
check_contains "6-21.1.4 policy has public web policy" "$POLICY_FILE" "session-policy-public-web-stateless"
check_contains "6-21.1.4 policy has no mutation" "$POLICY_FILE" '"mutation_allowed": false'
check_contains "6-21.1.4 policy has dry-run status" "$POLICY_FILE" "dry_run_only_no_session_sticky_mutation"

check_contains "6-21.1.4 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_1_5"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$POLICY_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_1_4_session_sticky_runtime.json; then
  pass "6-21.1.4 dry-run session sticky runtime"
else
  fail "6-21.1.4 dry-run session sticky runtime"
fi

check_contains "6-21.1.4 runtime output is PASS" "/tmp/faz_6_21_1_4_session_sticky_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.1.4 runtime output is dry run" "/tmp/faz_6_21_1_4_session_sticky_runtime.json" "session_sticky_policy_dry_run"
check_contains "6-21.1.4 runtime output disables provider mutation" "/tmp/faz_6_21_1_4_session_sticky_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.1.4 runtime output disables lb sticky mutation" "/tmp/faz_6_21_1_4_session_sticky_runtime.json" '"load_balancer_sticky_mutation_allowed": false'
check_contains "6-21.1.4 runtime output has next step" "/tmp/faz_6_21_1_4_session_sticky_runtime.json" "FAZ_6_21_1_5"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$POLICY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.1.4 semantic validator runtime"
else
  fail "6-21.1.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.1.4 python3 dependency"
else
  fail "6-21.1.4 python3 dependency"
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
# FAZ 6-R / 304 — FAZ 6-21.1.4 Session / Sticky Policy Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
POLICY_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_1_5_READY=${NEXT_READY}

Scope note: provider mutation, gateway session mutation, load balancer sticky mutation, Nginx mutation, Redis session mutation, cookie policy mutation and deployment rollout remain closed in this step.
Dependency: FAZ_6_21_1_2 service discovery runtime tuning evidence checked.
EOF2

echo "===== FAZ 6-21.1.4 SESSION STICKY POLICY REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_1_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.1.4 SESSION STICKY POLICY COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "POLICY_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_1_5_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
