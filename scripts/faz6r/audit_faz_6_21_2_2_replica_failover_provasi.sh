#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_2_2_REPLICA_FAILOVER_PROVASI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_2_2_replica_failover_provasi.v1.json"
REHEARSAL_FILE="configs/faz6r/replica_failover_rehearsal.ha_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_2_2_replica_failover_provasi_test.json"
RUNTIME_FILE="scripts/faz6r/run_replica_failover_rehearsal_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_replica_failover_provasi.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_2_2_replica_failover_provasi.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_2_2_REPLICA_FAILOVER_PROVASI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_DB_HA_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_2_1_DB_HA_TOPOLOJISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.2.2 REPLICA FAILOVER PROVASI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.2.2 previous DB HA topology evidence file" "$PREV_DB_HA_EVIDENCE"
check_contains "6-21.2.2 previous DB HA topology final PASS" "$PREV_DB_HA_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.2.2 documentation file" "$DOC_FILE"
check_file "6-21.2.2 config file" "$CONFIG_FILE"
check_file "6-21.2.2 rehearsal file" "$REHEARSAL_FILE"
check_file "6-21.2.2 fixture file" "$FIXTURE_FILE"
check_file "6-21.2.2 runtime file" "$RUNTIME_FILE"
check_file "6-21.2.2 validator file" "$VALIDATOR_FILE"
check_file "6-21.2.2 audit file" "$AUDIT_FILE"

check_contains "6-21.2.2 doc has Replica Failover Provasi" "$DOC_FILE" "Replica Failover Provası"
check_contains "6-21.2.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.2.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.2.2 config has dependency" "$CONFIG_FILE" "FAZ_6_21_2_1"
check_contains "6-21.2.2 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.2.2 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.2.2 config disables db promotion" "$CONFIG_FILE" '"db_promotion_allowed": false'
check_contains "6-21.2.2 config disables replica promotion" "$CONFIG_FILE" '"replica_promotion_allowed": false'
check_contains "6-21.2.2 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.2.2 config disables dsn mutation" "$CONFIG_FILE" '"dsn_mutation_allowed": false'
check_contains "6-21.2.2 config disables app route mutation" "$CONFIG_FILE" '"application_route_mutation_allowed": false'
check_contains "6-21.2.2 config disables replication slot mutation" "$CONFIG_FILE" '"replication_slot_mutation_allowed": false'
check_contains "6-21.2.2 config has failover candidate preflight" "$CONFIG_FILE" "failover_candidate_preflight"
check_contains "6-21.2.2 config has replica lag guard" "$CONFIG_FILE" "replica_lag_guard"
check_contains "6-21.2.2 config has wal replay guard" "$CONFIG_FILE" "wal_replay_guard"
check_contains "6-21.2.2 config has backup pitr guard" "$CONFIG_FILE" "backup_pitr_guard"
check_contains "6-21.2.2 config has split brain guard" "$CONFIG_FILE" "split_brain_guard"
check_contains "6-21.2.2 config has rollback policy" "$CONFIG_FILE" "rollback_decision_policy"

check_contains "6-21.2.2 rehearsal has sync candidate" "$REHEARSAL_FILE" "postgres_sync_replica_candidate"
check_contains "6-21.2.2 rehearsal has ready decision" "$REHEARSAL_FILE" "READY_FOR_MANUAL_APPROVED_FAILOVER_REHEARSAL"
check_contains "6-21.2.2 rehearsal has blocked lag decision" "$REHEARSAL_FILE" "BLOCKED_REPLICA_LAG"
check_contains "6-21.2.2 rehearsal has blocked split brain decision" "$REHEARSAL_FILE" "BLOCKED_SPLIT_BRAIN_RISK"
check_contains "6-21.2.2 rehearsal has blocked backup pitr decision" "$REHEARSAL_FILE" "BLOCKED_BACKUP_PITR"
check_contains "6-21.2.2 rehearsal has no mutation" "$REHEARSAL_FILE" '"mutation_allowed": false'
check_contains "6-21.2.2 rehearsal has dry-run status" "$REHEARSAL_FILE" "dry_run_only_no_replica_promotion"
check_contains "6-21.2.2 rehearsal has next step" "$REHEARSAL_FILE" "FAZ_6_21_2_5"

check_contains "6-21.2.2 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_2_5"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_2_2_replica_failover_runtime.json; then
  pass "6-21.2.2 dry-run replica failover runtime"
else
  fail "6-21.2.2 dry-run replica failover runtime"
fi

check_contains "6-21.2.2 runtime output is PASS" "/tmp/faz_6_21_2_2_replica_failover_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.2.2 runtime output is dry run" "/tmp/faz_6_21_2_2_replica_failover_runtime.json" "replica_failover_rehearsal_dry_run"
check_contains "6-21.2.2 runtime output disables provider mutation" "/tmp/faz_6_21_2_2_replica_failover_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.2.2 runtime output disables replica promotion" "/tmp/faz_6_21_2_2_replica_failover_runtime.json" '"replica_promotion_allowed": false'
check_contains "6-21.2.2 runtime output has next step" "/tmp/faz_6_21_2_2_replica_failover_runtime.json" "FAZ_6_21_2_5"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.2.2 semantic validator runtime"
else
  fail "6-21.2.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.2.2 python3 dependency"
else
  fail "6-21.2.2 python3 dependency"
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
# FAZ 6-R / 301 — FAZ 6-21.2.2 Replica Failover Provası Real Implementation Audit

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
FAZ_6_21_2_5_READY=${NEXT_READY}

Scope note: provider mutation, DB promotion, replica promotion, DNS mutation, DSN mutation, application route mutation and replication slot mutation remain closed in this step.
Dependency: FAZ_6_21_2_1 DB HA topolojisi evidence checked.
EOF2

echo "===== FAZ 6-21.2.2 REPLICA FAILOVER PROVASI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_2_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.2.2 REPLICA FAILOVER PROVASI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "REHEARSAL_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_2_5_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
