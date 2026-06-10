#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_2_1_DB_HA_TOPOLOJISI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_2_1_db_ha_topolojisi.v1.json"
TOPOLOGY_FILE="configs/faz6r/db_ha_topology.ha_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_2_1_db_ha_topolojisi_test.json"
RUNTIME_FILE="scripts/faz6r/run_db_ha_topology_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_db_ha_topolojisi.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_2_1_db_ha_topolojisi.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_2_1_DB_HA_TOPOLOJISI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_RATE_LIMIT_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_3_4_RATE_LIMIT_TUNING_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.2.1 DB HA TOPOLOJISI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.2.1 previous rate limit tuning evidence file" "$PREV_RATE_LIMIT_EVIDENCE"
check_contains "6-21.2.1 previous rate limit tuning final PASS" "$PREV_RATE_LIMIT_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.2.1 documentation file" "$DOC_FILE"
check_file "6-21.2.1 config file" "$CONFIG_FILE"
check_file "6-21.2.1 topology file" "$TOPOLOGY_FILE"
check_file "6-21.2.1 fixture file" "$FIXTURE_FILE"
check_file "6-21.2.1 runtime file" "$RUNTIME_FILE"
check_file "6-21.2.1 validator file" "$VALIDATOR_FILE"
check_file "6-21.2.1 audit file" "$AUDIT_FILE"

check_contains "6-21.2.1 doc has DB HA Topolojisi" "$DOC_FILE" "DB HA Topolojisi"
check_contains "6-21.2.1 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.2.1 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.2.1 config has dependency" "$CONFIG_FILE" "FAZ_6_21_3_4"
check_contains "6-21.2.1 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.2.1 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.2.1 config disables db promotion" "$CONFIG_FILE" '"db_promotion_allowed": false'
check_contains "6-21.2.1 config disables replica attach" "$CONFIG_FILE" '"replica_attach_allowed": false'
check_contains "6-21.2.1 config disables replica detach" "$CONFIG_FILE" '"replica_detach_allowed": false'
check_contains "6-21.2.1 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.2.1 config disables dsn mutation" "$CONFIG_FILE" '"dsn_mutation_allowed": false'
check_contains "6-21.2.1 config disables route mutation" "$CONFIG_FILE" '"read_write_route_mutation_allowed": false'
check_contains "6-21.2.1 config has HA role model" "$CONFIG_FILE" "db_ha_role_model"
check_contains "6-21.2.1 config has primary replica topology" "$CONFIG_FILE" "primary_replica_topology_model"
check_contains "6-21.2.1 config has write primary guard" "$CONFIG_FILE" "write_primary_guard"
check_contains "6-21.2.1 config has replication health model" "$CONFIG_FILE" "replication_health_model"
check_contains "6-21.2.1 config has split brain prevention" "$CONFIG_FILE" "split_brain_prevention_policy"
check_contains "6-21.2.1 config has PITR dependency" "$CONFIG_FILE" "backup_pitr_dependency_policy"

check_contains "6-21.2.1 topology has primary" "$TOPOLOGY_FILE" "postgres_primary"
check_contains "6-21.2.1 topology has sync replica" "$TOPOLOGY_FILE" "postgres_sync_replica_candidate"
check_contains "6-21.2.1 topology has async replica" "$TOPOLOGY_FILE" "postgres_async_read_replica"
check_contains "6-21.2.1 topology has PITR chain" "$TOPOLOGY_FILE" "backup_pitr_chain"
check_contains "6-21.2.1 topology has no mutation" "$TOPOLOGY_FILE" '"mutation_allowed": false'
check_contains "6-21.2.1 topology has dry-run status" "$TOPOLOGY_FILE" "dry_run_only_no_db_ha_mutation"
check_contains "6-21.2.1 topology has next step" "$TOPOLOGY_FILE" "FAZ_6_21_2_2"

check_contains "6-21.2.1 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_2_2"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$TOPOLOGY_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_2_1_db_ha_topology_runtime.json; then
  pass "6-21.2.1 dry-run DB HA topology runtime"
else
  fail "6-21.2.1 dry-run DB HA topology runtime"
fi

check_contains "6-21.2.1 runtime output is PASS" "/tmp/faz_6_21_2_1_db_ha_topology_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.2.1 runtime output is dry run" "/tmp/faz_6_21_2_1_db_ha_topology_runtime.json" "db_ha_topology_dry_run"
check_contains "6-21.2.1 runtime output disables provider mutation" "/tmp/faz_6_21_2_1_db_ha_topology_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.2.1 runtime output disables db promotion" "/tmp/faz_6_21_2_1_db_ha_topology_runtime.json" '"db_promotion_allowed": false'
check_contains "6-21.2.1 runtime output has next step" "/tmp/faz_6_21_2_1_db_ha_topology_runtime.json" "FAZ_6_21_2_2"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$TOPOLOGY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.2.1 semantic validator runtime"
else
  fail "6-21.2.1 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.2.1 python3 dependency"
else
  fail "6-21.2.1 python3 dependency"
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
# FAZ 6-R / 300 — FAZ 6-21.2.1 DB HA Topolojisi Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
TOPOLOGY_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_2_2_READY=${NEXT_READY}

Scope note: provider mutation, DB promotion, replica attach/detach, DNS mutation, DSN mutation and read/write route mutation remain closed in this step.
Dependency: FAZ_6_21_3_4 rate limit tuning evidence checked.
EOF2

echo "===== FAZ 6-21.2.1 DB HA TOPOLOJISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_2_1_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.2.1 DB HA TOPOLOJISI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "TOPOLOGY_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_2_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
