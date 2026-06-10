#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_8_migration_reconciliation_final_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
EVIDENCE_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$EVIDENCE_FILE"' EXIT

detail() {
  echo "$1" >> "$DETAILS_FILE"
}

evidence() {
  echo "$1" >> "$EVIDENCE_FILE"
}

warn() {
  echo "WARN ⚠️ $1" >> "$ISSUES_FILE"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "FAIL ❌ $1" >> "$ISSUES_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

get_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    echo ""
    return 0
  fi

  grep -E "^${key}=" "$file" | tail -n 1 | cut -d= -f2- || true
}

require_file() {
  local label="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    fail "required report missing: $label -> ${file#$ROOT_DIR/}"
  else
    evidence "REPORT_OK ✅ $label -> ${file#$ROOT_DIR/}"
  fi
}

require_value() {
  local label="$1"
  local actual="$2"
  local expected="$3"

  if [ "$actual" = "$expected" ]; then
    evidence "VALUE_OK ✅ $label=$actual"
  else
    fail "$label expected=$expected actual=${actual:-EMPTY}"
  fi
}

require_zero() {
  local label="$1"
  local actual="$2"

  if [ "${actual:-}" = "0" ]; then
    evidence "VALUE_OK ✅ $label=0"
  else
    fail "$label expected=0 actual=${actual:-EMPTY}"
  fi
}

detail "ROOT_DIR=$ROOT_DIR"
detail "MUTATION=NO"
detail "MIGRATION_APPLY=NO"
detail "INDEX_APPLY=NO"

R_CHAIN="$REPORT_DIR/14_1_1_migration_chain_validation.md"
R_GATE="$REPORT_DIR/14_1_2_migration_apply_gate_report.md"
R_DSN="$REPORT_DIR/14_1_4B_primary_write_dsn_guard_report.md"
R_STATUS="$REPORT_DIR/14_1_5_migration_status_evidence_report.md"
R_NORM="$REPORT_DIR/14_1_5A_migration_version_normalization_report.md"
R_TIME="$REPORT_DIR/14_1_5B_migration_timestamp_order_guard_report.md"
R_DRIFT="$REPORT_DIR/14_1_6_migration_drift_evidence_report.md"
R_CLASS="$REPORT_DIR/14_1_6B_drift_classification_report.md"
R_INDEX="$REPORT_DIR/14_1_7_index_reconciliation_report.md"

require_file "14.1.1 migration chain validation" "$R_CHAIN"
require_file "14.1.2 migration apply gate" "$R_GATE"
require_file "14.1.4B primary write DSN guard" "$R_DSN"
require_file "14.1.5 migration status evidence" "$R_STATUS"
require_file "14.1.5A version normalization" "$R_NORM"
require_file "14.1.5B timestamp order guard" "$R_TIME"
require_file "14.1.6 drift evidence" "$R_DRIFT"
require_file "14.1.6B drift classification" "$R_CLASS"
require_file "14.1.7 index reconciliation plan" "$R_INDEX"

CHAIN_PASS="$(get_value "$R_CHAIN" "MIGRATION_CHAIN_VALIDATION")"
GATE_PASS="$(get_value "$R_GATE" "MIGRATION_APPLY_GATE")"
PRIMARY_GUARD="$(get_value "$R_DSN" "PRIMARY_WRITE_DSN_GUARD")"
STATUS_PASS="$(get_value "$R_STATUS" "MIGRATION_STATUS_EVIDENCE")"
NORM_PASS="$(get_value "$R_NORM" "MIGRATION_VERSION_NORMALIZATION")"
TIME_PASS="$(get_value "$R_TIME" "MIGRATION_TIMESTAMP_ORDER_GUARD")"
DRIFT_PASS="$(get_value "$R_DRIFT" "MIGRATION_DRIFT_EVIDENCE")"
CLASS_PASS="$(get_value "$R_CLASS" "DRIFT_CLASSIFICATION")"
INDEX_PASS="$(get_value "$R_INDEX" "INDEX_RECONCILIATION_PLAN")"

DB_ROLE="$(get_value "$R_STATUS" "DB_ROLE")"
DB_DIRTY="$(get_value "$R_STATUS" "SCHEMA_MIGRATIONS_DIRTY_STATE")"
DB_CONN="$(get_value "$R_STATUS" "DB_CONNECTION_CHECK")"

DB_CURRENT_VERSION="$(get_value "$R_STATUS" "DB_CURRENT_VERSION")"
DB_VERSION_MATCH_LOCAL="$(get_value "$R_NORM" "DB_VERSION_MATCH_LOCAL")"
DB_VERSION_EQUALS_LOCAL_LATEST="$(get_value "$R_NORM" "DB_VERSION_EQUALS_LOCAL_LATEST")"
DB_LOCAL_CHAIN_MISMATCH="$(get_value "$R_NORM" "DB_LOCAL_CHAIN_MISMATCH")"

TIMESTAMP_ANOMALY_COUNT="$(get_value "$R_TIME" "TIMESTAMP_ANOMALY_COUNT")"
SAFE_LATEST_FILE="$(get_value "$R_TIME" "SAFE_LATEST_FILE")"
NAIVE_LATEST_FILE="$(get_value "$R_TIME" "NAIVE_LATEST_FILE")"
LATEST_ORDER_MISMATCH="$(get_value "$R_TIME" "LATEST_ORDER_MISMATCH")"

MISSING_SCHEMA_COUNT="$(get_value "$R_CLASS" "MISSING_SCHEMA_COUNT")"
MISSING_TABLE_COUNT="$(get_value "$R_CLASS" "MISSING_TABLE_COUNT")"
MISSING_INDEX_COUNT="$(get_value "$R_CLASS" "MISSING_INDEX_COUNT")"
DRIFT_RISK_LEVEL="$(get_value "$R_CLASS" "DRIFT_RISK_LEVEL")"

SAFE_INDEX_CANDIDATE_COUNT="$(get_value "$R_INDEX" "SAFE_INDEX_CANDIDATE_COUNT")"
SKIPPED_TABLE_MISSING_COUNT="$(get_value "$R_INDEX" "SKIPPED_TABLE_MISSING_COUNT")"
ALREADY_EXISTS_INDEX_COUNT="$(get_value "$R_INDEX" "ALREADY_EXISTS_INDEX_COUNT")"
PARSE_NOT_FOUND_COUNT="$(get_value "$R_INDEX" "PARSE_NOT_FOUND_COUNT")"
UNKNOWN_CHECK_COUNT="$(get_value "$R_INDEX" "UNKNOWN_CHECK_COUNT")"

detail "MIGRATION_CHAIN_VALIDATION=$CHAIN_PASS"
detail "MIGRATION_APPLY_GATE=$GATE_PASS"
detail "PRIMARY_WRITE_DSN_GUARD=$PRIMARY_GUARD"
detail "MIGRATION_STATUS_EVIDENCE=$STATUS_PASS"
detail "MIGRATION_VERSION_NORMALIZATION=$NORM_PASS"
detail "MIGRATION_TIMESTAMP_ORDER_GUARD=$TIME_PASS"
detail "MIGRATION_DRIFT_EVIDENCE=$DRIFT_PASS"
detail "DRIFT_CLASSIFICATION=$CLASS_PASS"
detail "INDEX_RECONCILIATION_PLAN=$INDEX_PASS"

detail "DB_CONNECTION_CHECK=$DB_CONN"
detail "DB_ROLE=$DB_ROLE"
detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DB_DIRTY"
detail "DB_CURRENT_VERSION=$DB_CURRENT_VERSION"

detail "DB_VERSION_MATCH_LOCAL=$DB_VERSION_MATCH_LOCAL"
detail "DB_VERSION_EQUALS_LOCAL_LATEST=$DB_VERSION_EQUALS_LOCAL_LATEST"
detail "DB_LOCAL_CHAIN_MISMATCH=$DB_LOCAL_CHAIN_MISMATCH"

detail "TIMESTAMP_ANOMALY_COUNT=$TIMESTAMP_ANOMALY_COUNT"
detail "SAFE_LATEST_FILE=$SAFE_LATEST_FILE"
detail "NAIVE_LATEST_FILE=$NAIVE_LATEST_FILE"
detail "LATEST_ORDER_MISMATCH=$LATEST_ORDER_MISMATCH"

detail "MISSING_SCHEMA_COUNT=$MISSING_SCHEMA_COUNT"
detail "MISSING_TABLE_COUNT=$MISSING_TABLE_COUNT"
detail "MISSING_INDEX_COUNT=$MISSING_INDEX_COUNT"
detail "DRIFT_RISK_LEVEL=$DRIFT_RISK_LEVEL"

detail "SAFE_INDEX_CANDIDATE_COUNT=$SAFE_INDEX_CANDIDATE_COUNT"
detail "SKIPPED_TABLE_MISSING_COUNT=$SKIPPED_TABLE_MISSING_COUNT"
detail "ALREADY_EXISTS_INDEX_COUNT=$ALREADY_EXISTS_INDEX_COUNT"
detail "PARSE_NOT_FOUND_COUNT=$PARSE_NOT_FOUND_COUNT"
detail "UNKNOWN_CHECK_COUNT=$UNKNOWN_CHECK_COUNT"

require_value "MIGRATION_CHAIN_VALIDATION" "$CHAIN_PASS" "PASS"
require_value "MIGRATION_APPLY_GATE" "$GATE_PASS" "PASS"
require_value "PRIMARY_WRITE_DSN_GUARD" "$PRIMARY_GUARD" "PASS"
require_value "MIGRATION_STATUS_EVIDENCE" "$STATUS_PASS" "PASS"
require_value "MIGRATION_VERSION_NORMALIZATION" "$NORM_PASS" "PASS"
require_value "MIGRATION_TIMESTAMP_ORDER_GUARD" "$TIME_PASS" "PASS"
require_value "MIGRATION_DRIFT_EVIDENCE" "$DRIFT_PASS" "PASS"
require_value "DRIFT_CLASSIFICATION" "$CLASS_PASS" "PASS"
require_value "INDEX_RECONCILIATION_PLAN" "$INDEX_PASS" "PASS"

require_value "DB_CONNECTION_CHECK" "$DB_CONN" "PASS"
require_value "DB_ROLE" "$DB_ROLE" "PRIMARY_WRITE"
require_value "SCHEMA_MIGRATIONS_DIRTY_STATE" "$DB_DIRTY" "f"

require_zero "MISSING_SCHEMA_COUNT" "$MISSING_SCHEMA_COUNT"
require_zero "MISSING_TABLE_COUNT" "$MISSING_TABLE_COUNT"
require_zero "SAFE_INDEX_CANDIDATE_COUNT" "$SAFE_INDEX_CANDIDATE_COUNT"
require_zero "SKIPPED_TABLE_MISSING_COUNT" "$SKIPPED_TABLE_MISSING_COUNT"
require_zero "PARSE_NOT_FOUND_COUNT" "$PARSE_NOT_FOUND_COUNT"
require_zero "UNKNOWN_CHECK_COUNT" "$UNKNOWN_CHECK_COUNT"

if [ "$DB_LOCAL_CHAIN_MISMATCH" = "YES" ]; then
  warn "DB schema_migrations version local latest ile ayni degil; fakat table/schema eksigi ve index candidate yok"
fi

if [ "${TIMESTAMP_ANOMALY_COUNT:-0}" != "0" ]; then
  warn "timestamp anomaly var; safe latest guard devrede"
fi

if [ "${MISSING_INDEX_COUNT:-0}" != "0" ] && [ "${SAFE_INDEX_CANDIDATE_COUNT:-0}" = "0" ]; then
  warn "classification missing index gosteriyor ama reconciliation plan indexlerin zaten var oldugunu kanitladi"
fi

FINAL_DECISION="UNDECIDED"
APPLY_ACTION="NO"
INDEX_APPLY_ACTION="NO"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_DECISION="NO_OP_APPLY_NOT_REQUIRED"
else
  FINAL_DECISION="BLOCKED_REVIEW_REQUIRED"
fi

detail "FINAL_DECISION=$FINAL_DECISION"
detail "APPLY_ACTION=$APPLY_ACTION"
detail "INDEX_APPLY_ACTION=$INDEX_APPLY_ACTION"

{
  echo "# FAZ 4 / 14.1.8 - Migration Final Reconciliation Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_RECONCILIATION_FINAL=PASS"
  else
    echo "MIGRATION_RECONCILIATION_FINAL=FAIL"
  fi

  echo
  echo "## Evidence"
  if [ -s "$EVIDENCE_FILE" ]; then
    cat "$EVIDENCE_FILE"
  else
    echo "evidence yok"
  fi

  echo
  echo "## Final Decision"
  echo "FINAL_DECISION=$FINAL_DECISION"
  echo "APPLY_ACTION=$APPLY_ACTION"
  echo "INDEX_APPLY_ACTION=$INDEX_APPLY_ACTION"
  echo "MIGRATION_APPLY_EXECUTED=NO"
  echo "INDEX_APPLY_EXECUTED=NO"
  echo "DB_MUTATION=NO"

  echo
  echo "## Issues / Warnings"
  if [ -s "$ISSUES_FILE" ]; then
    cat "$ISSUES_FILE"
  else
    echo "OK ✅ issue yok"
  fi

  echo
  echo "## Secret Safety"
  echo "RAW_DSN_PRINTED=NO"
  echo "PASSWORD_MASKING=ENABLED"
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FINAL_DECISION=$FINAL_DECISION"
echo "APPLY_ACTION=$APPLY_ACTION"
echo "INDEX_APPLY_ACTION=$INDEX_APPLY_ACTION"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "MIGRATION_RECONCILIATION_FINAL=FAIL ❌"
  exit 1
fi

echo "MIGRATION_RECONCILIATION_FINAL=PASS ✅"
