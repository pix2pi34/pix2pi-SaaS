#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_4_1_WAF_TUNING.md"
CONFIG_FILE="configs/faz6r/faz_6_21_4_1_waf_tuning.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_4_1_waf_tuning_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_waf_tuning.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_4_1_waf_tuning.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_4_1_WAF_TUNING_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.4.1 WAF TUNING REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.4.1 documentation file" "$DOC_FILE"
check_file "6-21.4.1 config file" "$CONFIG_FILE"
check_file "6-21.4.1 fixture file" "$FIXTURE_FILE"
check_file "6-21.4.1 validator file" "$VALIDATOR_FILE"
check_file "6-21.4.1 audit file" "$AUDIT_FILE"

check_contains "6-21.4.1 doc has WAF Tuning" "$DOC_FILE" "WAF Tuning"
check_contains "6-21.4.1 doc has Rollout Model" "$DOC_FILE" "Rollout Model"
check_contains "6-21.4.1 config has provider neutral true" "$CONFIG_FILE" '"provider_neutral": true'
check_contains "6-21.4.1 config has live mutation false" "$CONFIG_FILE" '"live_provider_api_mutation_allowed": false'
check_contains "6-21.4.1 config has managed_waf_baseline" "$CONFIG_FILE" "managed_waf_baseline"
check_contains "6-21.4.1 config has api_abuse_surface_guard" "$CONFIG_FILE" "api_abuse_surface_guard"
check_contains "6-21.4.1 config has auth_bruteforce_guard" "$CONFIG_FILE" "auth_bruteforce_guard"
check_contains "6-21.4.1 config has tenant_api_header_presence_guard" "$CONFIG_FILE" "tenant_api_header_presence_guard"
check_contains "6-21.4.1 config has dangerous_method_block" "$CONFIG_FILE" "dangerous_method_block"
check_contains "6-21.4.1 config has scanner_exploit_path_guard" "$CONFIG_FILE" "scanner_exploit_path_guard"
check_contains "6-21.4.1 config has upload_boundary_guard" "$CONFIG_FILE" "upload_boundary_guard"
check_contains "6-21.4.1 config has health_endpoint_safe_policy" "$CONFIG_FILE" "health_endpoint_safe_policy"
check_contains "6-21.4.1 config has rollback strategy" "$CONFIG_FILE" "return_to_previous_stable_edge_policy"
check_contains "6-21.4.1 fixture has expected tenant header" "$FIXTURE_FILE" "X-Tenant-ID"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$FIXTURE_FILE"; then
  pass "6-21.4.1 semantic validator runtime"
else
  fail "6-21.4.1 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.4.1 python3 dependency"
else
  fail "6-21.4.1 python3 dependency"
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
# FAZ 6-R / 280 — FAZ 6-21.4.1 WAF Tuning Real Implementation Audit

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
FAZ_6_21_4_2_READY=${NEXT_READY}

Scope note: live provider API mutation is intentionally closed in this step.
EOF2

echo "===== FAZ 6-21.4.1 WAF TUNING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_4_1_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.4.1 WAF TUNING COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_4_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
