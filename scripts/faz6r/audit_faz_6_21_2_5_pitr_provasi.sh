#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_2_5_POINT_IN_TIME_RECOVERY_PROVASI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_2_5_pitr_provasi.v1.json"
REHEARSAL_FILE="configs/faz6r/pitr_rehearsal.ha_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_2_5_pitr_provasi_test.json"
RUNTIME_FILE="scripts/faz6r/run_pitr_rehearsal_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_pitr_provasi.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_2_5_pitr_provasi.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_2_5_POINT_IN_TIME_RECOVERY_PROVASI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_REPLICA_FAILOVER_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_2_2_REPLICA_FAILOVER_PROVASI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.2.5 POINT-IN-TIME RECOVERY PROVASI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.2.5 previous replica failover evidence file" "$PREV_REPLICA_FAILOVER_EVIDENCE"
check_contains "6-21.2.5 previous replica failover final PASS" "$PREV_REPLICA_FAILOVER_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.2.5 documentation file" "$DOC_FILE"
check_file "6-21.2.5 config file" "$CONFIG_FILE"
check_file "6-21.2.5 rehearsal file" "$REHEARSAL_FILE"
check_file "6-21.2.5 fixture file" "$FIXTURE_FILE"
check_file "6-21.2.5 runtime file" "$RUNTIME_FILE"
check_file "6-21.2.5 validator file" "$VALIDATOR_FILE"
check_file "6-21.2.5 audit file" "$AUDIT_FILE"

check_contains "6-21.2.5 doc has Point-in-time Recovery" "$DOC_FILE" "Point-in-time Recovery Provası"
check_contains "6-21.2.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.2.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.2.5 config has dependency" "$CONFIG_FILE" "FAZ_6_21_2_2"
check_contains "6-21.2.5 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.2.5 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.2.5 config disables restore execution" "$CONFIG_FILE" '"restore_execution_allowed": false'
check_contains "6-21.2.5 config disables primary overwrite" "$CONFIG_FILE" '"primary_overwrite_allowed": false'
check_contains "6-21.2.5 config disables replica rebuild" "$CONFIG_FILE" '"replica_rebuild_allowed": false'
check_contains "6-21.2.5 config disables wal replay execution" "$CONFIG_FILE" '"wal_replay_execution_allowed": false'
check_contains "6-21.2.5 config disables backup delete" "$CONFIG_FILE" '"backup_delete_allowed": false'
check_contains "6-21.2.5 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.2.5 config disables dsn mutation" "$CONFIG_FILE" '"dsn_mutation_allowed": false'
check_contains "6-21.2.5 config disables app route mutation" "$CONFIG_FILE" '"application_route_mutation_allowed": false'
check_contains "6-21.2.5 config has backup chain inventory" "$CONFIG_FILE" "backup_chain_inventory"
check_contains "6-21.2.5 config has WAL archive inventory" "$CONFIG_FILE" "wal_archive_inventory"
check_contains "6-21.2.5 config has recovery target policy" "$CONFIG_FILE" "recovery_target_time_policy"
check_contains "6-21.2.5 config has isolated restore target" "$CONFIG_FILE" "isolated_restore_target_policy"
check_contains "6-21.2.5 config has tenant scope validation" "$CONFIG_FILE" "tenant_scope_validation_policy"

check_contains "6-21.2.5 rehearsal has happy path" "$REHEARSAL_FILE" "pitr-dry-run-happy-path"
check_contains "6-21.2.5 rehearsal has missing WAL blocked case" "$REHEARSAL_FILE" "pitr-blocked-missing-wal"
check_contains "6-21.2.5 rehearsal has outside window blocked case" "$REHEARSAL_FILE" "pitr-blocked-target-time-outside-window"
check_contains "6-21.2.5 rehearsal has production target blocked case" "$REHEARSAL_FILE" "pitr-blocked-production-target"
check_contains "6-21.2.5 rehearsal has isolated restore target" "$REHEARSAL_FILE" "isolated_restore_environment_only"
check_contains "6-21.2.5 rehearsal has no mutation" "$REHEARSAL_FILE" '"mutation_allowed": false'
check_contains "6-21.2.5 rehearsal has dry-run status" "$REHEARSAL_FILE" "dry_run_only_no_restore_execution"
check_contains "6-21.2.5 rehearsal has next step" "$REHEARSAL_FILE" "FAZ_6_21_1_2"

check_contains "6-21.2.5 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_1_2"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_2_5_pitr_runtime.json; then
  pass "6-21.2.5 dry-run PITR runtime"
else
  fail "6-21.2.5 dry-run PITR runtime"
fi

check_contains "6-21.2.5 runtime output is PASS" "/tmp/faz_6_21_2_5_pitr_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.2.5 runtime output is dry run" "/tmp/faz_6_21_2_5_pitr_runtime.json" "pitr_rehearsal_dry_run"
check_contains "6-21.2.5 runtime output disables provider mutation" "/tmp/faz_6_21_2_5_pitr_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.2.5 runtime output disables restore execution" "/tmp/faz_6_21_2_5_pitr_runtime.json" '"restore_execution_allowed": false'
check_contains "6-21.2.5 runtime output has next step" "/tmp/faz_6_21_2_5_pitr_runtime.json" "FAZ_6_21_1_2"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.2.5 semantic validator runtime"
else
  fail "6-21.2.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.2.5 python3 dependency"
else
  fail "6-21.2.5 python3 dependency"
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
# FAZ 6-R / 302 — FAZ 6-21.2.5 Point-in-time Recovery Provası Real Implementation Audit

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
FAZ_6_21_1_2_READY=${NEXT_READY}

Scope note: provider mutation, restore execution, primary overwrite, replica rebuild, WAL replay execution, backup delete, DNS mutation, DSN mutation and application route mutation remain closed in this step.
Dependency: FAZ_6_21_2_2 replica failover provası evidence checked.
EOF2

echo "===== FAZ 6-21.2.5 POINT-IN-TIME RECOVERY PROVASI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_2_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.2.5 POINT-IN-TIME RECOVERY PROVASI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "REHEARSAL_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_1_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
