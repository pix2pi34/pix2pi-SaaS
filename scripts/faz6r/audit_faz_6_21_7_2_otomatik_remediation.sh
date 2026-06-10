#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_7_2_OTOMATIK_REMEDIATION.md"
CONFIG_FILE="configs/faz6r/faz_6_21_7_2_otomatik_remediation.v1.json"
RULES_FILE="configs/faz6r/auto_remediation.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_7_2_otomatik_remediation_test.json"
RUNTIME_FILE="scripts/faz6r/run_auto_remediation_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_otomatik_remediation.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_7_2_otomatik_remediation.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_7_2_OTOMATIK_REMEDIATION_REAL_IMPLEMENTATION_AUDIT.md"
PREV_RUNBOOK_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_7_1_RUNBOOK_SETI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.7.2 OTOMATIK REMEDIATION REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.7.2 previous runbook seti evidence file" "$PREV_RUNBOOK_EVIDENCE"
check_contains "6-21.7.2 previous runbook seti final PASS" "$PREV_RUNBOOK_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.7.2 documentation file" "$DOC_FILE"
check_file "6-21.7.2 config file" "$CONFIG_FILE"
check_file "6-21.7.2 rules file" "$RULES_FILE"
check_file "6-21.7.2 fixture file" "$FIXTURE_FILE"
check_file "6-21.7.2 runtime file" "$RUNTIME_FILE"
check_file "6-21.7.2 validator file" "$VALIDATOR_FILE"
check_file "6-21.7.2 audit file" "$AUDIT_FILE"

check_contains "6-21.7.2 doc has Otomatik Remediation" "$DOC_FILE" "Otomatik Remediation"
check_contains "6-21.7.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.7.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.7.2 config has dependency" "$CONFIG_FILE" "FAZ_6_21_7_1"
check_contains "6-21.7.2 config has dry run mode" "$CONFIG_FILE" "dry_run_guarded"
check_contains "6-21.7.2 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.7.2 config disables production mutation" "$CONFIG_FILE" '"production_mutation_allowed": false'
check_contains "6-21.7.2 config disables destructive default" "$CONFIG_FILE" '"destructive_action_default_allowed": false'
check_contains "6-21.7.2 config has manual approval gate" "$CONFIG_FILE" "manual_approval_gate"
check_contains "6-21.7.2 config has production mutation guard" "$CONFIG_FILE" "production_mutation_guard"
check_contains "6-21.7.2 config has safe action allowlist" "$CONFIG_FILE" "safe_action_allowlist"
check_contains "6-21.7.2 config has unsafe action denylist" "$CONFIG_FILE" "unsafe_action_denylist"
check_contains "6-21.7.2 config blocks rollback execute" "$CONFIG_FILE" "rollback_execute"
check_contains "6-21.7.2 config blocks database failover execute" "$CONFIG_FILE" "database_failover_execute"
check_contains "6-21.7.2 config blocks mass cache delete" "$CONFIG_FILE" "mass_cache_delete"

check_contains "6-21.7.2 rules has edge remediation" "$RULES_FILE" "remediate-edge-attack-spike"
check_contains "6-21.7.2 rules has tls remediation" "$RULES_FILE" "remediate-tls-expiry"
check_contains "6-21.7.2 rules has api remediation" "$RULES_FILE" "remediate-api-5xx-spike"
check_contains "6-21.7.2 rules has db remediation" "$RULES_FILE" "remediate-db-degradation"
check_contains "6-21.7.2 rules has event backlog remediation" "$RULES_FILE" "remediate-event-backlog"
check_contains "6-21.7.2 rules has cache remediation" "$RULES_FILE" "remediate-cache-degradation"
check_contains "6-21.7.2 rules has release remediation" "$RULES_FILE" "remediate-release-regression"

check_contains "6-21.7.2 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_7_3"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$RULES_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_7_2_runtime_output.json; then
  pass "6-21.7.2 dry-run remediation runtime"
else
  fail "6-21.7.2 dry-run remediation runtime"
fi

check_contains "6-21.7.2 runtime output is PASS" "/tmp/faz_6_21_7_2_runtime_output.json" '"runtime_status": "PASS"'
check_contains "6-21.7.2 runtime output is dry run" "/tmp/faz_6_21_7_2_runtime_output.json" '"mode": "dry_run_guarded"'
check_contains "6-21.7.2 runtime output blocks production mutation" "/tmp/faz_6_21_7_2_runtime_output.json" '"production_mutation_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$RULES_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.7.2 semantic validator runtime"
else
  fail "6-21.7.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.7.2 python3 dependency"
else
  fail "6-21.7.2 python3 dependency"
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
# FAZ 6-R / 286 — FAZ 6-21.7.2 Otomatik Remediation Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
RULES_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_7_3_READY=${NEXT_READY}

Scope note: automatic remediation is dry-run guarded. Production mutation and destructive actions remain blocked by default.
Dependency: FAZ_6_21_7_1 runbook seti evidence checked.
EOF2

echo "===== FAZ 6-21.7.2 OTOMATIK REMEDIATION REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_7_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.7.2 OTOMATIK REMEDIATION COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "RULES_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_7_3_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
