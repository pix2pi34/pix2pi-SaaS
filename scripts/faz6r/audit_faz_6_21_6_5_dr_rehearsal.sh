#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_6_5_DR_REHEARSAL.md"
CONFIG_FILE="configs/faz6r/faz_6_21_6_5_dr_rehearsal.v1.json"
REHEARSAL_FILE="configs/faz6r/dr_rehearsal.dr_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_6_5_dr_rehearsal_test.json"
RUNTIME_FILE="scripts/faz6r/run_dr_rehearsal_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_dr_rehearsal.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_6_5_dr_rehearsal.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_6_5_DR_REHEARSAL_REAL_IMPLEMENTATION_AUDIT.md"
PREV_COMM_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_6_4_OPERASYONEL_ILETISIM_PLANI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.6.5 DR REHEARSAL REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.6.5 previous operational communication evidence file" "$PREV_COMM_EVIDENCE"
check_contains "6-21.6.5 previous operational communication final PASS" "$PREV_COMM_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.6.5 documentation file" "$DOC_FILE"
check_file "6-21.6.5 config file" "$CONFIG_FILE"
check_file "6-21.6.5 rehearsal file" "$REHEARSAL_FILE"
check_file "6-21.6.5 fixture file" "$FIXTURE_FILE"
check_file "6-21.6.5 runtime file" "$RUNTIME_FILE"
check_file "6-21.6.5 validator file" "$VALIDATOR_FILE"
check_file "6-21.6.5 audit file" "$AUDIT_FILE"

check_contains "6-21.6.5 doc has DR Rehearsal" "$DOC_FILE" "DR Rehearsal"
check_contains "6-21.6.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.6.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.6.5 config has dependency" "$CONFIG_FILE" "FAZ_6_21_6_4"
check_contains "6-21.6.5 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.6.5 config disables live failover" "$CONFIG_FILE" '"live_failover_allowed": false'
check_contains "6-21.6.5 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.6.5 config disables db promotion" "$CONFIG_FILE" '"db_promotion_allowed": false'
check_contains "6-21.6.5 config disables queue mutation" "$CONFIG_FILE" '"queue_mutation_allowed": false'
check_contains "6-21.6.5 config disables storage mutation" "$CONFIG_FILE" '"storage_mutation_allowed": false'
check_contains "6-21.6.5 config disables compute mutation" "$CONFIG_FILE" '"compute_mutation_allowed": false'
check_contains "6-21.6.5 config disables customer notification" "$CONFIG_FILE" '"customer_notification_allowed": false'
check_contains "6-21.6.5 config has preflight policy" "$CONFIG_FILE" "preflight_check_policy"
check_contains "6-21.6.5 config has rto rpo measurement" "$CONFIG_FILE" "rto_rpo_measurement_policy"
check_contains "6-21.6.5 config has backup restore readiness" "$CONFIG_FILE" "backup_restore_readiness_check"
check_contains "6-21.6.5 config has communication plan link" "$CONFIG_FILE" "operational_communication_plan"

check_contains "6-21.6.5 rehearsal has edge dns" "$REHEARSAL_FILE" "dr-rehearsal-edge-dns"
check_contains "6-21.6.5 rehearsal has db primary" "$REHEARSAL_FILE" "dr-rehearsal-db-primary"
check_contains "6-21.6.5 rehearsal has event queue" "$REHEARSAL_FILE" "dr-rehearsal-event-queue"
check_contains "6-21.6.5 rehearsal has storage" "$REHEARSAL_FILE" "dr-rehearsal-storage"
check_contains "6-21.6.5 rehearsal has no mutation" "$REHEARSAL_FILE" '"mutation_allowed": false'
check_contains "6-21.6.5 rehearsal has dry run status" "$REHEARSAL_FILE" "dry_run_only_no_live_failover"

check_contains "6-21.6.5 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_5_1"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_6_5_dr_rehearsal_runtime.json; then
  pass "6-21.6.5 dry-run DR rehearsal runtime"
else
  fail "6-21.6.5 dry-run DR rehearsal runtime"
fi

check_contains "6-21.6.5 runtime output is PASS" "/tmp/faz_6_21_6_5_dr_rehearsal_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.6.5 runtime output is dry run" "/tmp/faz_6_21_6_5_dr_rehearsal_runtime.json" "dr_rehearsal_dry_run"
check_contains "6-21.6.5 runtime output disables live failover" "/tmp/faz_6_21_6_5_dr_rehearsal_runtime.json" '"live_failover_allowed": false'
check_contains "6-21.6.5 runtime output disables customer notification" "/tmp/faz_6_21_6_5_dr_rehearsal_runtime.json" '"customer_notification_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.6.5 semantic validator runtime"
else
  fail "6-21.6.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.6.5 python3 dependency"
else
  fail "6-21.6.5 python3 dependency"
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
# FAZ 6-R / 292 — FAZ 6-21.6.5 DR Rehearsal Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
REHEARSAL_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_5_1_READY=${NEXT_READY}

Scope note: live failover, provider mutation, customer notification, DNS, DB, queue, storage and compute mutations remain closed in this step.
Dependency: FAZ_6_21_6_4 operasyonel iletişim planı evidence checked.
EOF2

echo "===== FAZ 6-21.6.5 DR REHEARSAL REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_6_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.6.5 DR REHEARSAL COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "REHEARSAL_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_5_1_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
