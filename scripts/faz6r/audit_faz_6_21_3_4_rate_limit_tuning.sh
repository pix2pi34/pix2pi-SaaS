#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_3_4_RATE_LIMIT_TUNING.md"
CONFIG_FILE="configs/faz6r/faz_6_21_3_4_rate_limit_tuning.v1.json"
TUNING_FILE="configs/faz6r/rate_limit_tuning.performance_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_3_4_rate_limit_tuning_test.json"
RUNTIME_FILE="scripts/faz6r/run_rate_limit_tuning_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_rate_limit_tuning.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_3_4_rate_limit_tuning.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_3_4_RATE_LIMIT_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_CACHE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_3_3_CACHE_HIT_MISS_TUNING_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail(){
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
}

check_file(){
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label missing"
  fi
}

check_contains(){
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label missing pattern $pattern"
  fi
}

echo "===== FAZ 6-21.3.4 RATE LIMIT TUNING REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.3.4 previous cache hit/miss evidence file" "$PREV_CACHE_EVIDENCE"
check_contains "6-21.3.4 previous cache hit/miss final PASS" "$PREV_CACHE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.3.4 documentation file" "$DOC_FILE"
check_file "6-21.3.4 config file" "$CONFIG_FILE"
check_file "6-21.3.4 tuning file" "$TUNING_FILE"
check_file "6-21.3.4 fixture file" "$FIXTURE_FILE"
check_file "6-21.3.4 runtime file" "$RUNTIME_FILE"
check_file "6-21.3.4 validator file" "$VALIDATOR_FILE"
check_file "6-21.3.4 audit file" "$AUDIT_FILE"

check_contains "6-21.3.4 doc has Rate Limit Tuning" "$DOC_FILE" "Rate Limit Tuning"
check_contains "6-21.3.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.3.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.3.4 config has dependency" "$CONFIG_FILE" "FAZ_6_21_3_3"
check_contains "6-21.3.4 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.3.4 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.3.4 config disables gateway mutation" "$CONFIG_FILE" '"gateway_rate_limit_mutation_allowed": false'
check_contains "6-21.3.4 config disables redis mutation" "$CONFIG_FILE" '"redis_rate_limit_mutation_allowed": false'
check_contains "6-21.3.4 config disables edge waf mutation" "$CONFIG_FILE" '"edge_waf_mutation_allowed": false'
check_contains "6-21.3.4 config disables nginx mutation" "$CONFIG_FILE" '"nginx_mutation_allowed": false'
check_contains "6-21.3.4 config has tenant model" "$CONFIG_FILE" "tenant_rate_limit_model"
check_contains "6-21.3.4 config has route model" "$CONFIG_FILE" "route_rate_limit_model"
check_contains "6-21.3.4 config has auth brute force guard" "$CONFIG_FILE" "auth_bruteforce_guard"
check_contains "6-21.3.4 config has api abuse guard" "$CONFIG_FILE" "api_abuse_guard"
check_contains "6-21.3.4 config has webhook guard" "$CONFIG_FILE" "webhook_rate_limit_guard"
check_contains "6-21.3.4 config has false positive guard" "$CONFIG_FILE" "false_positive_guard"
check_contains "6-21.3.4 config has redis namespace guard" "$CONFIG_FILE" "redis_namespace_guard"
check_contains "6-21.3.4 config has edge waf alignment guard" "$CONFIG_FILE" "edge_waf_alignment_guard"

check_contains "6-21.3.4 tuning has api gateway recommendation" "$TUNING_FILE" "rate-limit-api-gateway-route-review"
check_contains "6-21.3.4 tuning has auth recommendation" "$TUNING_FILE" "rate-limit-auth-bruteforce-review"
check_contains "6-21.3.4 tuning has pos recommendation" "$TUNING_FILE" "rate-limit-pos-burst-review"
check_contains "6-21.3.4 tuning has webhook recommendation" "$TUNING_FILE" "rate-limit-webhook-retry-review"
check_contains "6-21.3.4 tuning has public web recommendation" "$TUNING_FILE" "rate-limit-public-web-false-positive-review"
check_contains "6-21.3.4 tuning has no mutation" "$TUNING_FILE" '"mutation_allowed": false'
check_contains "6-21.3.4 tuning has dry-run status" "$TUNING_FILE" "dry_run_only_no_rate_limit_mutation"

check_contains "6-21.3.4 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_2_1"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_3_4_rate_limit_runtime.json; then
  pass "6-21.3.4 dry-run rate limit tuning runtime"
else
  fail "6-21.3.4 dry-run rate limit tuning runtime"
fi

check_contains "6-21.3.4 runtime output is PASS" "/tmp/faz_6_21_3_4_rate_limit_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.3.4 runtime output is dry run" "/tmp/faz_6_21_3_4_rate_limit_runtime.json" "rate_limit_tuning_dry_run"
check_contains "6-21.3.4 runtime output disables provider mutation" "/tmp/faz_6_21_3_4_rate_limit_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.3.4 runtime output disables gateway mutation" "/tmp/faz_6_21_3_4_rate_limit_runtime.json" '"gateway_rate_limit_mutation_allowed": false'
check_contains "6-21.3.4 runtime output disables redis mutation" "/tmp/faz_6_21_3_4_rate_limit_runtime.json" '"redis_rate_limit_mutation_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.3.4 semantic validator runtime"
else
  fail "6-21.3.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.3.4 python3 dependency"
else
  fail "6-21.3.4 python3 dependency"
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
# FAZ 6-R / 299 — FAZ 6-21.3.4 Rate Limit Tuning Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
TUNING_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_2_1_READY=${NEXT_READY}

Scope note: provider mutation, gateway rate limit mutation, Redis rate limit mutation, edge WAF mutation and Nginx mutation remain closed in this step.
Dependency: FAZ_6_21_3_3 cache hit/miss tuning evidence checked.
EOF2

echo "===== FAZ 6-21.3.4 RATE LIMIT TUNING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_3_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.3.4 RATE LIMIT TUNING COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "TUNING_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_2_1_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
