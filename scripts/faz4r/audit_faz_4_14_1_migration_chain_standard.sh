#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_14_1_MIGRATION_CHAIN_STANDARD.md"
CONFIG_FILE="configs/faz4r/faz_4_14_1_migration_chain_standard.v1.json"
CHAIN_SCRIPT="scripts/faz4r/validate_faz4_migration_chain.sh"
SQL_TEST_FILE="tests/faz4r/faz_4_14_1_migration_chain_standard.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"
MIGRATION_DIR="db/migrations/faz4"

mkdir -p "docs/faz4r/evidence"

record_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

record_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
}

record_warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "$1 OPTIONAL_WARN / WARN ⚠️"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_executable() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

run_chain_validator() {
  local out_file="/tmp/faz_4_14_1_chain_validator_$$.out"

  if MIGRATION_DIR="$MIGRATION_DIR" APPLY_DB_TEST=1 "$CHAIN_SCRIPT" > "$out_file" 2>&1; then
    record_pass "migration chain validator runtime execution"
  else
    record_fail "migration chain validator runtime execution"
    echo "----- migration chain validator output start -----"
    cat "$out_file" || true
    echo "----- migration chain validator output end -----"
    return 1
  fi

  if grep -Fq "migration directory exists IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator migration directory check"
  else
    record_fail "validator migration directory check"
  fi

  if grep -Fq "migration sql files exist IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator sql files check"
  else
    record_fail "validator sql files check"
  fi

  if grep -Fq "180 import staging migration exists in chain IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator 180 migration dependency check"
  else
    record_fail "validator 180 migration dependency check"
  fi

  if grep -Fq "migration filename pattern validation IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator filename pattern check"
  else
    record_fail "validator filename pattern check"
  fi

  if grep -Fq "migration duplicate timestamp guard IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator duplicate timestamp check"
  else
    record_fail "validator duplicate timestamp check"
  fi

  if grep -Fq "migration chain temporary schema apply IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator temporary schema apply check"
  else
    record_fail "validator temporary schema apply check"
  fi

  if grep -Fq "migration chain required table verification IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator required table check"
  else
    record_fail "validator required table check"
  fi

  if grep -Fq "migration chain rollback safety IMPLEMENTED_OR_PRESENT / OK" "$out_file"; then
    record_pass "validator rollback safety check"
  else
    record_fail "validator rollback safety check"
  fi

  if grep -Fq "FAZ4_MIGRATION_CHAIN_VALIDATION_STATUS=PASS" "$out_file"; then
    record_pass "validator final status pass"
  else
    record_fail "validator final status pass"
  fi

  return 0
}

{
  echo "===== 183 — FAZ 4-14.1 MIGRATION CHAIN STANDARD REAL IMPLEMENTATION AUDIT START ====="

  if [ -d "$MIGRATION_DIR" ]; then
    record_pass "migration directory exists"
  else
    record_fail "migration directory exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "chain validation script exists" "$CHAIN_SCRIPT"
  check_executable "chain validation script executable" "$CHAIN_SCRIPT"
  check_file "sql test artifact exists" "$SQL_TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-14.1 Migration Chain Standardı"
  check_contains "doc filename standard marker" "$DOC_FILE" "YYYYMMDD_HHMMSS_faz_x_y_z_description.sql"
  check_contains "doc temporary schema marker" "$DOC_FILE" "temporary schema"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 183"
  check_contains "config dependency 180 marker" "$CONFIG_FILE" "180_FAZ_4_14_3_IMPORT_STAGING_TABLES"
  check_contains "config dependency 181 marker" "$CONFIG_FILE" "181_FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS"
  check_contains "config dependency 182 marker" "$CONFIG_FILE" "182_FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "chain script migration dir marker" "$CHAIN_SCRIPT" "MIGRATION_DIR"
  check_contains "chain script duplicate timestamp marker" "$CHAIN_SCRIPT" "duplicate_timestamp_count"
  check_contains "chain script filename regex marker" "$CHAIN_SCRIPT" "^[0-9]{8}_[0-9]{6}_[a-z0-9_]+\\.sql$"
  check_contains "chain script db apply marker" "$CHAIN_SCRIPT" "APPLY_DB_TEST"
  check_contains "chain script final pass marker" "$CHAIN_SCRIPT" "FAZ4_MIGRATION_CHAIN_VALIDATION_STATUS=PASS"

  check_contains "sql test artifact marker" "$SQL_TEST_FILE" "MIGRATION_CHAIN_STANDARD_SQL_TEST_ARTIFACT_IMPLEMENTED"

  run_chain_validator

  echo "===== 183 — FAZ 4-14.1 MIGRATION CHAIN STANDARD COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_DOC_STATUS=READY"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_CONFIG_STATUS=READY"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_RUNTIME_STATUS=READY"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_DB_APPLY_STATUS=PASS"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_FINAL_STATUS=PASS"
    echo "FAZ_4_14_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_DB_APPLY_STATUS=FAIL"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_14_1_MIGRATION_CHAIN_STANDARD_FINAL_STATUS=FAIL"
    echo "FAZ_4_14_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
