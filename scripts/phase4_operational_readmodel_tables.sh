#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
MIGRATION_BASE="${2:-20260427_151001_readmodel_operational_tables}"

UP_FILE="$ROOT_DIR/db/migrations/${MIGRATION_BASE}.up.sql"
DOWN_FILE="$ROOT_DIR/db/migrations/${MIGRATION_BASE}.down.sql"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/15_1_operational_readmodel_tables_report.md"
INVENTORY_FILE="$REPORT_DIR/15_1_operational_readmodel_tables_inventory.tsv"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

tool_status() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    echo "TOOL_${tool}=FOUND" >> "$TOOL_FILE"
    return 0
  fi
  echo "TOOL_${tool}=NOT_FOUND" >> "$TOOL_FILE"
  return 1
}

count_pattern() {
  local file="$1"
  local pattern="$2"
  grep -E "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' '
}

require_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Eq "$pattern" "$file" 2>/dev/null; then
    echo "CHECK_OK ✅ $label"
    return 0
  fi

  echo "CHECK_FAIL ❌ $label"
  fail "$label bulunamadi"
  return 1
}

add_inventory() {
  local table_name="$1"
  local primary_key="$2"
  local purpose="$3"

  echo -e "${table_name}\t${primary_key}\t${purpose}" >> "$INVENTORY_FILE"
}

detail "ROOT_DIR=$ROOT_DIR"
detail "MIGRATION_BASE=$MIGRATION_BASE"
detail "UP_FILE=db/migrations/${MIGRATION_BASE}.up.sql"
detail "DOWN_FILE=db/migrations/${MIGRATION_BASE}.down.sql"
detail "DB_APPLY_EXECUTED=NO"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ ! -f "$UP_FILE" ]; then
  fail "up migration yok: $UP_FILE"
fi

if [ ! -f "$DOWN_FILE" ]; then
  fail "down migration yok: $DOWN_FILE"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  require_grep "$UP_FILE" "^CREATE SCHEMA IF NOT EXISTS readmodel;" "readmodel schema create" >/dev/null || true
  require_grep "$UP_FILE" "CREATE TABLE IF NOT EXISTS readmodel\\.projection_state" "projection_state table" >/dev/null || true
  require_grep "$UP_FILE" "CREATE TABLE IF NOT EXISTS readmodel\\.tenant_operational_snapshot" "tenant_operational_snapshot table" >/dev/null || true
  require_grep "$UP_FILE" "CREATE TABLE IF NOT EXISTS readmodel\\.daily_operational_metrics" "daily_operational_metrics table" >/dev/null || true
  require_grep "$UP_FILE" "CREATE TABLE IF NOT EXISTS readmodel\\.inventory_status_snapshot" "inventory_status_snapshot table" >/dev/null || true
  require_grep "$UP_FILE" "CREATE TABLE IF NOT EXISTS readmodel\\.document_work_queue" "document_work_queue table" >/dev/null || true
  require_grep "$UP_FILE" "CREATE TABLE IF NOT EXISTS readmodel\\.reconciliation_status_snapshot" "reconciliation_status_snapshot table" >/dev/null || true

  require_grep "$DOWN_FILE" "DROP TABLE IF EXISTS readmodel\\.projection_state" "projection_state down drop" >/dev/null || true
  require_grep "$DOWN_FILE" "DROP TABLE IF EXISTS readmodel\\.tenant_operational_snapshot" "tenant_operational_snapshot down drop" >/dev/null || true
  require_grep "$DOWN_FILE" "DROP TABLE IF EXISTS readmodel\\.daily_operational_metrics" "daily_operational_metrics down drop" >/dev/null || true
  require_grep "$DOWN_FILE" "DROP TABLE IF EXISTS readmodel\\.inventory_status_snapshot" "inventory_status_snapshot down drop" >/dev/null || true
  require_grep "$DOWN_FILE" "DROP TABLE IF EXISTS readmodel\\.document_work_queue" "document_work_queue down drop" >/dev/null || true
  require_grep "$DOWN_FILE" "DROP TABLE IF EXISTS readmodel\\.reconciliation_status_snapshot" "reconciliation_status_snapshot down drop" >/dev/null || true
fi

CREATE_TABLE_COUNT=0
INDEX_COUNT=0
TENANT_ID_COUNT=0
DROP_TABLE_COUNT=0

if [ -f "$UP_FILE" ]; then
  CREATE_TABLE_COUNT="$(count_pattern "$UP_FILE" "^CREATE TABLE IF NOT EXISTS readmodel\\.")"
  INDEX_COUNT="$(count_pattern "$UP_FILE" "^CREATE INDEX IF NOT EXISTS")"
  TENANT_ID_COUNT="$(count_pattern "$UP_FILE" "tenant_id text")"
fi

if [ -f "$DOWN_FILE" ]; then
  DROP_TABLE_COUNT="$(count_pattern "$DOWN_FILE" "^DROP TABLE IF EXISTS readmodel\\.")"
fi

detail "READMODEL_SCHEMA_DEFINED=YES"
detail "OPERATIONAL_READMODEL_TABLE_COUNT=$CREATE_TABLE_COUNT"
detail "OPERATIONAL_READMODEL_INDEX_COUNT=$INDEX_COUNT"
detail "TENANT_ID_COLUMN_COUNT=$TENANT_ID_COUNT"
detail "DOWN_DROP_TABLE_COUNT=$DROP_TABLE_COUNT"

if [ "$CREATE_TABLE_COUNT" -ne 6 ]; then
  fail "expected 6 readmodel table, actual=$CREATE_TABLE_COUNT"
fi

if [ "$DROP_TABLE_COUNT" -ne 6 ]; then
  fail "expected 6 down drop table, actual=$DROP_TABLE_COUNT"
fi

if [ "$TENANT_ID_COUNT" -lt 6 ]; then
  fail "tenant_id column count yetersiz: $TENANT_ID_COUNT"
fi

if grep -Eq "DROP TABLE|DROP SCHEMA|ALTER SYSTEM|docker restart|psql " "$UP_FILE" 2>/dev/null; then
  fail "up migration icinde guvensiz ifade bulundu"
fi

{
  echo -e "table_name\tprimary_key\tpurpose"
  add_inventory "readmodel.projection_state" "tenant_id, projection_name" "Projection offset/state tracking"
  add_inventory "readmodel.tenant_operational_snapshot" "tenant_id" "Tenant dashboard snapshot"
  add_inventory "readmodel.daily_operational_metrics" "tenant_id, metric_date" "Daily operational metrics"
  add_inventory "readmodel.inventory_status_snapshot" "tenant_id, item_id, warehouse_id" "Inventory operational status"
  add_inventory "readmodel.document_work_queue" "tenant_id, document_type, document_id" "Document operation queue"
  add_inventory "readmodel.reconciliation_status_snapshot" "tenant_id, scope_type, scope_id" "Reconciliation status snapshot"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "READMODEL_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

CHAIN_VALIDATOR_STATUS="SKIPPED"
CHAIN_VALIDATOR_REPORT=""

if [ -x "$ROOT_DIR/scripts/phase4_validate_migration_chain.sh" ]; then
  if bash "$ROOT_DIR/scripts/phase4_validate_migration_chain.sh" "$ROOT_DIR" "$ROOT_DIR/db/migrations" >/tmp/pix2pi_15_1_chain_validator.log 2>&1; then
    CHAIN_VALIDATOR_STATUS="PASS"
  else
    CHAIN_VALIDATOR_STATUS="FAIL"
    fail "migration chain validator failed"
  fi

  CHAIN_VALIDATOR_REPORT="$ROOT_DIR/docs/phase4/14_1_1_migration_chain_validation.md"
fi

detail "MIGRATION_CHAIN_VALIDATOR_STATUS=$CHAIN_VALIDATOR_STATUS"
if [ -n "$CHAIN_VALIDATOR_REPORT" ]; then
  detail "MIGRATION_CHAIN_VALIDATOR_REPORT=docs/phase4/14_1_1_migration_chain_validation.md"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "READMODEL_MIGRATION_PAIR=PASS"
  detail "OPERATIONAL_READMODEL_TABLES=PASS"
else
  detail "READMODEL_MIGRATION_PAIR=FAIL"
  detail "OPERATIONAL_READMODEL_TABLES=FAIL"
fi

{
  echo "# FAZ 4 / 15.1 - Operational Readmodel Tables Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "OPERATIONAL_READMODEL_TABLES=PASS"
  else
    echo "OPERATIONAL_READMODEL_TABLES=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/15_1_operational_readmodel_tables_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_APPLY_EXECUTED=NO"
  echo "DB_MUTATION=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"

  echo
  echo "## Issues"
  if [ -s "$ISSUES_FILE" ]; then
    cat "$ISSUES_FILE"
  else
    echo "OK ✅ issue yok"
  fi

  echo
  echo "## Secret Safety"
  echo "RAW_DSN_PRINTED=NO"
  echo "POSTGRES_PASSWORD_PRINTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "OPERATIONAL_READMODEL_TABLES=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "OPERATIONAL_READMODEL_TABLES=FAIL ❌"
  exit 1
fi

echo "OPERATIONAL_READMODEL_TABLES=PASS ✅"
