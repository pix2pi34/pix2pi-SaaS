#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_6_3_BOLGESEL_KESINTI_SENARYOSU.md"
CONFIG_FILE="configs/faz6r/faz_6_21_6_3_bolgesel_kesinti_senaryosu.v1.json"
SCENARIO_FILE="configs/faz6r/regional_outage_scenario.dr_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_6_3_bolgesel_kesinti_senaryosu_test.json"
RUNTIME_FILE="scripts/faz6r/run_regional_outage_scenario_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_bolgesel_kesinti_senaryosu.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_6_3_bolgesel_kesinti_senaryosu.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_6_3_BOLGESEL_KESINTI_SENARYOSU_REAL_IMPLEMENTATION_AUDIT.md"
PREV_SRE_METRIC_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_7_5_SRE_METRIC_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.6.3 BOLGESEL KESINTI SENARYOSU REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.6.3 previous SRE metric review evidence file" "$PREV_SRE_METRIC_EVIDENCE"
check_contains "6-21.6.3 previous SRE metric review final PASS" "$PREV_SRE_METRIC_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.6.3 documentation file" "$DOC_FILE"
check_file "6-21.6.3 config file" "$CONFIG_FILE"
check_file "6-21.6.3 scenario file" "$SCENARIO_FILE"
check_file "6-21.6.3 fixture file" "$FIXTURE_FILE"
check_file "6-21.6.3 runtime file" "$RUNTIME_FILE"
check_file "6-21.6.3 validator file" "$VALIDATOR_FILE"
check_file "6-21.6.3 audit file" "$AUDIT_FILE"

check_contains "6-21.6.3 doc has Bolgesel Kesinti Senaryosu" "$DOC_FILE" "Bölgesel Kesinti Senaryosu"
check_contains "6-21.6.3 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.6.3 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.6.3 config has dependency" "$CONFIG_FILE" "FAZ_6_21_7_5"
check_contains "6-21.6.3 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.6.3 config disables live failover" "$CONFIG_FILE" '"live_failover_allowed": false'
check_contains "6-21.6.3 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.6.3 config disables db failover" "$CONFIG_FILE" '"db_failover_allowed": false'
check_contains "6-21.6.3 config disables queue failover" "$CONFIG_FILE" '"queue_failover_allowed": false'
check_contains "6-21.6.3 config disables storage failover" "$CONFIG_FILE" '"storage_failover_allowed": false'
check_contains "6-21.6.3 config disables compute failover" "$CONFIG_FILE" '"compute_failover_allowed": false'
check_contains "6-21.6.3 config has rto rpo policy" "$CONFIG_FILE" "rto_rpo_policy"
check_contains "6-21.6.3 config has failover decision policy" "$CONFIG_FILE" "failover_decision_policy"
check_contains "6-21.6.3 config has read only degradation policy" "$CONFIG_FILE" "read_only_degradation_policy"
check_contains "6-21.6.3 config has communication handoff" "$CONFIG_FILE" "FAZ_6_21_6_4"

check_contains "6-21.6.3 scenario has edge dns outage" "$SCENARIO_FILE" "regional-outage-edge-dns"
check_contains "6-21.6.3 scenario has db primary outage" "$SCENARIO_FILE" "regional-outage-db-primary"
check_contains "6-21.6.3 scenario has event queue outage" "$SCENARIO_FILE" "regional-outage-event-queue"
check_contains "6-21.6.3 scenario has storage outage" "$SCENARIO_FILE" "regional-outage-storage"
check_contains "6-21.6.3 scenario has read only decision" "$SCENARIO_FILE" "degrade_to_read_only"
check_contains "6-21.6.3 scenario has no provider mutation" "$SCENARIO_FILE" '"provider_mutation_allowed": false'

check_contains "6-21.6.3 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_6_4"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$SCENARIO_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_6_3_regional_outage_runtime.json; then
  pass "6-21.6.3 dry-run regional outage runtime"
else
  fail "6-21.6.3 dry-run regional outage runtime"
fi

check_contains "6-21.6.3 runtime output is PASS" "/tmp/faz_6_21_6_3_regional_outage_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.6.3 runtime output is dry run" "/tmp/faz_6_21_6_3_regional_outage_runtime.json" "regional_outage_dry_run"
check_contains "6-21.6.3 runtime output disables live failover" "/tmp/faz_6_21_6_3_regional_outage_runtime.json" '"live_failover_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$SCENARIO_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.6.3 semantic validator runtime"
else
  fail "6-21.6.3 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.6.3 python3 dependency"
else
  fail "6-21.6.3 python3 dependency"
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
# FAZ 6-R / 290 — FAZ 6-21.6.3 Bölgesel Kesinti Senaryosu Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
SCENARIO_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_6_4_READY=${NEXT_READY}

Scope note: live DNS, DB, queue, storage, compute failover and provider mutation remain closed in this step.
Dependency: FAZ_6_21_7_5 SRE metric review evidence checked.
EOF2

echo "===== FAZ 6-21.6.3 BOLGESEL KESINTI SENARYOSU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_6_3_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.6.3 BOLGESEL KESINTI SENARYOSU COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "SCENARIO_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_6_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
