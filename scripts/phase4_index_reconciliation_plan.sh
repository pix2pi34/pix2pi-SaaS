#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"
DRIFT_REPORT="$ROOT_DIR/docs/phase4/14_1_6_migration_drift_evidence_report.md"
REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_7_index_reconciliation_report.md"
PLAN_FILE="$REPORT_DIR/14_1_7_index_reconciliation_plan.sql"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
MISSING_INDEX_FILE="$(mktemp)"
PARSED_INDEX_FILE="$(mktemp)"
CANDIDATE_FILE="$(mktemp)"
SKIPPED_FILE="$(mktemp)"
EXISTS_FILE="$(mktemp)"
UNKNOWN_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$MISSING_INDEX_FILE" "$PARSED_INDEX_FILE" "$CANDIDATE_FILE" "$SKIPPED_FILE" "$EXISTS_FILE" "$UNKNOWN_FILE"' EXIT

detail() {
  echo "$1" >> "$DETAILS_FILE"
}

warn() {
  echo "WARN ⚠️ $1" >> "$ISSUES_FILE"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "FAIL ❌ $1" >> "$ISSUES_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

strip_quotes() {
  local v="$1"
  v="${v%$'\r'}"

  case "$v" in
    \"*\")
      v="${v#\"}"
      v="${v%\"}"
      ;;
    \'*\')
      v="${v#\'}"
      v="${v%\'}"
      ;;
  esac

  echo "$v"
}

extract_env() {
  local file="$1"
  local key="$2"
  local line=""
  local value=""

  [ -r "$file" ] || return 1

  line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${key}=" "$file" 2>/dev/null | tail -n 1 || true)"
  [ -n "$line" ] || return 1

  value="${line#*=}"
  value="$(strip_quotes "$value")"
  [ -n "$value" ] || return 1

  printf '%s' "$value"
  return 0
}

mask_secret() {
  local v="$1"
  v="$(printf '%s' "$v" | sed -E 's#(://[^:/@]+:)[^@]+@#\1***@#g')"
  v="$(printf '%s' "$v" | sed -E 's#(password=)[^[:space:]]+#\1***#Ig')"
  echo "$v"
}

sql_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

split_schema_table() {
  local rel="$1"
  local schema=""
  local name=""

  rel="$(printf '%s' "$rel" | sed -E 's/^"//; s/"$//; s/"//g')"

  if [[ "$rel" == *"."* ]]; then
    schema="${rel%%.*}"
    name="${rel#*.}"
  else
    schema="public"
    name="$rel"
  fi

  printf '%s|%s' "$schema" "$name"
}

check_table_exists() {
  local table_rel="$1"
  local escaped=""
  escaped="$(sql_escape "$table_rel")"
  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('${escaped}') is not null;" 2>/tmp/pix2pi_14_1_7_table_check_err.log || echo "error"
}

check_index_exists() {
  local index_name="$1"
  local table_rel="$2"
  local split=""
  local table_schema=""
  local table_name=""
  local escaped_index=""
  local escaped_schema=""
  local escaped_table=""

  split="$(split_schema_table "$table_rel")"
  table_schema="${split%%|*}"
  table_name="${split#*|}"

  escaped_index="$(sql_escape "$index_name")"
  escaped_schema="$(sql_escape "$table_schema")"
  escaped_table="$(sql_escape "$table_name")"

  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from pg_indexes where schemaname='${escaped_schema}' and tablename='${escaped_table}' and indexname='${escaped_index}');" 2>/tmp/pix2pi_14_1_7_index_check_err.log || echo "error"
}

detail "ROOT_DIR=$ROOT_DIR"
detail "DRIFT_REPORT=docs/phase4/14_1_6_migration_drift_evidence_report.md"
detail "PLAN_FILE=docs/phase4/14_1_7_index_reconciliation_plan.sql"
detail "INDEX_PLAN_MUTATION=NO"
detail "APPLY=NO"

DB_DSN="${DB_DSN:-${DB_WRITE_DSN:-${DATABASE_URL:-}}}"

if [ -z "$DB_DSN" ]; then
  DB_DSN="$(extract_env "$ENV_FILE" "DB_WRITE_DSN" || true)"
fi

if [ -z "$DB_DSN" ]; then
  DB_DSN="$(extract_env "$ENV_FILE" "DB_DSN" || true)"
fi

if [ -z "$DB_DSN" ]; then
  fail "DB DSN bulunamadi"
else
  detail "DB_DSN_STATUS=CONFIGURED"
  detail "DB_DSN_MASKED=$(mask_secret "$DB_DSN")"
fi

if ! command -v psql >/dev/null 2>&1; then
  fail "psql bulunamadi"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 bulunamadi"
fi

if [ ! -f "$DRIFT_REPORT" ]; then
  fail "drift report bulunamadi: docs/phase4/14_1_6_migration_drift_evidence_report.md"
else
  grep '^MISSING|INDEX|' "$DRIFT_REPORT" | sort -u > "$MISSING_INDEX_FILE" || true
fi

MISSING_INDEX_COUNT="$(wc -l < "$MISSING_INDEX_FILE" | tr -d ' ')"
detail "MISSING_INDEX_INPUT_COUNT=$MISSING_INDEX_COUNT"

if [ "$MISSING_INDEX_COUNT" -eq 0 ]; then
  warn "missing index yok; plan bos uretilecek"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  python3 - "$ROOT_DIR" "$MISSING_INDEX_FILE" "$PARSED_INDEX_FILE" <<'PY'
import os
import re
import sys

root = sys.argv[1]
missing_file = sys.argv[2]
out_file = sys.argv[3]

def read_file(path):
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()

def strip_comments(sql):
    lines = []
    for line in sql.splitlines():
        line = re.sub(r"--.*$", "", line)
        lines.append(line)
    return "\n".join(lines)

def normalize_space(s):
    return re.sub(r"\s+", " ", s).strip()

def split_statements(sql):
    parts = []
    current = []
    in_single = False
    in_double = False
    prev = ""
    for ch in sql:
        if ch == "'" and not in_double and prev != "\\":
            in_single = not in_single
        elif ch == '"' and not in_single and prev != "\\":
            in_double = not in_double
        if ch == ";" and not in_single and not in_double:
            statement = "".join(current).strip()
            if statement:
                parts.append(statement)
            current = []
        else:
            current.append(ch)
        prev = ch
    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return parts

def clean_ident(s):
    s = s.strip()
    s = s.strip('"')
    return s

def parse_index_statement(stmt):
    stmt_norm = normalize_space(stmt)
    pattern = re.compile(
        r"^CREATE\s+(UNIQUE\s+)?INDEX\s+(CONCURRENTLY\s+)?(IF\s+NOT\s+EXISTS\s+)?(?P<idx>\"?[A-Za-z0-9_]+\"?)\s+ON\s+(?P<table>\"?[A-Za-z0-9_]+\"?(?:\.\"?[A-Za-z0-9_]+\"?)?)\s+",
        re.IGNORECASE,
    )
    m = pattern.search(stmt_norm)
    if not m:
        return None
    idx = clean_ident(m.group("idx"))
    table = clean_ident(m.group("table"))
    if "." not in table:
        table = "public." + table
    safe_stmt = stmt_norm
    if re.match(r"^CREATE\s+UNIQUE\s+INDEX\s+(?!CONCURRENTLY\s+)?(?!IF\s+NOT\s+EXISTS)", safe_stmt, flags=re.IGNORECASE):
        safe_stmt = re.sub(r"^CREATE\s+UNIQUE\s+INDEX\s+", "CREATE UNIQUE INDEX IF NOT EXISTS ", safe_stmt, count=1, flags=re.IGNORECASE)
    elif re.match(r"^CREATE\s+INDEX\s+(?!CONCURRENTLY\s+)?(?!IF\s+NOT\s+EXISTS)", safe_stmt, flags=re.IGNORECASE):
        safe_stmt = re.sub(r"^CREATE\s+INDEX\s+", "CREATE INDEX IF NOT EXISTS ", safe_stmt, count=1, flags=re.IGNORECASE)
    elif re.match(r"^CREATE\s+INDEX\s+CONCURRENTLY\s+(?!IF\s+NOT\s+EXISTS)", safe_stmt, flags=re.IGNORECASE):
        safe_stmt = re.sub(r"^CREATE\s+INDEX\s+CONCURRENTLY\s+", "CREATE INDEX CONCURRENTLY IF NOT EXISTS ", safe_stmt, count=1, flags=re.IGNORECASE)
    elif re.match(r"^CREATE\s+UNIQUE\s+INDEX\s+CONCURRENTLY\s+(?!IF\s+NOT\s+EXISTS)", safe_stmt, flags=re.IGNORECASE):
        safe_stmt = re.sub(r"^CREATE\s+UNIQUE\s+INDEX\s+CONCURRENTLY\s+", "CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS ", safe_stmt, count=1, flags=re.IGNORECASE)
    return idx, table, safe_stmt

needed = []
seen = set()

with open(missing_file, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("|")
        if len(parts) < 5:
            continue
        status, typ, idx, aux, file_path = parts[:5]
        key = (idx, file_path)
        if key in seen:
            continue
        seen.add(key)
        needed.append((idx, file_path))

parsed_by_file = {}

for idx, file_path in needed:
    abs_path = os.path.join(root, file_path)
    if abs_path not in parsed_by_file:
        if os.path.exists(abs_path):
            sql = strip_comments(read_file(abs_path))
            stmts = split_statements(sql)
            rows = {}
            for stmt in stmts:
                parsed = parse_index_statement(stmt)
                if parsed:
                    pidx, table, safe_stmt = parsed
                    rows[pidx] = (table, safe_stmt)
            parsed_by_file[abs_path] = rows
        else:
            parsed_by_file[abs_path] = {}

with open(out_file, "w", encoding="utf-8") as out:
    for idx, file_path in needed:
        abs_path = os.path.join(root, file_path)
        rows = parsed_by_file.get(abs_path, {})
        if idx in rows:
            table, safe_stmt = rows[idx]
            out.write(f"{idx}|{table}|{file_path}|{safe_stmt}\n")
        else:
            out.write(f"{idx}|PARSE_NOT_FOUND|{file_path}|PARSE_NOT_FOUND\n")
PY
fi

PARSED_INDEX_COUNT="$(wc -l < "$PARSED_INDEX_FILE" | tr -d ' ')"
PARSE_NOT_FOUND_COUNT="$(grep -c '|PARSE_NOT_FOUND|' "$PARSED_INDEX_FILE" 2>/dev/null || true)"

detail "PARSED_INDEX_COUNT=$PARSED_INDEX_COUNT"
detail "PARSE_NOT_FOUND_COUNT=$PARSE_NOT_FOUND_COUNT"

if [ "$PARSE_NOT_FOUND_COUNT" -gt 0 ]; then
  warn "bazi missing index statement migration dosyasindan parse edilemedi"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_1_7_psql_ok.log 2>/tmp/pix2pi_14_1_7_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_1_7_recovery_err.log || echo "error")"
  detail "PG_IS_IN_RECOVERY=$IN_RECOVERY"

  case "$IN_RECOVERY" in
    f)
      detail "DB_ROLE=PRIMARY_WRITE"
      ;;
    t)
      detail "DB_ROLE=REPLICA_READ_ONLY"
      fail "DB replica/read-only gorunuyor"
      ;;
    *)
      fail "pg_is_in_recovery okunamadi"
      ;;
  esac
fi

SAFE_INDEX_CANDIDATE_COUNT=0
SKIPPED_TABLE_MISSING_COUNT=0
ALREADY_EXISTS_INDEX_COUNT=0
PARSE_SKIP_COUNT=0
UNKNOWN_CHECK_COUNT=0

if [ "$FAIL_COUNT" -eq 0 ]; then
  while IFS='|' read -r idx table file_path sql_stmt; do
    [ -n "$idx" ] || continue

    if [ "$table" = "PARSE_NOT_FOUND" ]; then
      PARSE_SKIP_COUNT=$((PARSE_SKIP_COUNT + 1))
      echo "PARSE_SKIP|$idx|$file_path" >> "$SKIPPED_FILE"
      continue
    fi

    table_exists="$(check_table_exists "$table")"

    case "$table_exists" in
      t)
        index_exists="$(check_index_exists "$idx" "$table")"
        case "$index_exists" in
          t)
            ALREADY_EXISTS_INDEX_COUNT=$((ALREADY_EXISTS_INDEX_COUNT + 1))
            echo "ALREADY_EXISTS|$idx|$table|$file_path" >> "$EXISTS_FILE"
            ;;
          f)
            SAFE_INDEX_CANDIDATE_COUNT=$((SAFE_INDEX_CANDIDATE_COUNT + 1))
            echo "CANDIDATE|$idx|$table|$file_path|$sql_stmt" >> "$CANDIDATE_FILE"
            ;;
          *)
            UNKNOWN_CHECK_COUNT=$((UNKNOWN_CHECK_COUNT + 1))
            echo "UNKNOWN_INDEX_CHECK|$idx|$table|$file_path" >> "$UNKNOWN_FILE"
            ;;
        esac
        ;;
      f)
        SKIPPED_TABLE_MISSING_COUNT=$((SKIPPED_TABLE_MISSING_COUNT + 1))
        echo "SKIPPED_TABLE_MISSING|$idx|$table|$file_path" >> "$SKIPPED_FILE"
        ;;
      *)
        UNKNOWN_CHECK_COUNT=$((UNKNOWN_CHECK_COUNT + 1))
        echo "UNKNOWN_TABLE_CHECK|$idx|$table|$file_path" >> "$UNKNOWN_FILE"
        ;;
    esac
  done < "$PARSED_INDEX_FILE"
fi

detail "SAFE_INDEX_CANDIDATE_COUNT=$SAFE_INDEX_CANDIDATE_COUNT"
detail "SKIPPED_TABLE_MISSING_COUNT=$SKIPPED_TABLE_MISSING_COUNT"
detail "ALREADY_EXISTS_INDEX_COUNT=$ALREADY_EXISTS_INDEX_COUNT"
detail "PARSE_SKIP_COUNT=$PARSE_SKIP_COUNT"
detail "UNKNOWN_CHECK_COUNT=$UNKNOWN_CHECK_COUNT"

if [ "$UNKNOWN_CHECK_COUNT" -gt 0 ]; then
  warn "bazi index/table kontrolleri unknown dondu"
fi

if [ "$SKIPPED_TABLE_MISSING_COUNT" -gt 0 ]; then
  warn "table eksik oldugu icin bazi indexler safe candidate disinda birakildi"
fi

{
  echo "-- FAZ 4 / 14.1.7 - Index-only reconciliation plan"
  echo "-- Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "-- IMPORTANT: This file is a PLAN only."
  echo "-- IMPORTANT: It was NOT executed by 14.1.7."
  echo "-- IMPORTANT: Review before applying."
  echo "-- INDEX_PLAN_MUTATION=NO"
  echo
  echo "-- SAFE_INDEX_CANDIDATE_COUNT=$SAFE_INDEX_CANDIDATE_COUNT"
  echo "-- SKIPPED_TABLE_MISSING_COUNT=$SKIPPED_TABLE_MISSING_COUNT"
  echo "-- ALREADY_EXISTS_INDEX_COUNT=$ALREADY_EXISTS_INDEX_COUNT"
  echo "-- PARSE_SKIP_COUNT=$PARSE_SKIP_COUNT"
  echo "-- UNKNOWN_CHECK_COUNT=$UNKNOWN_CHECK_COUNT"
  echo
  while IFS='|' read -r status idx table file_path sql_stmt; do
    [ -n "$idx" ] || continue
    echo "-- source: $file_path"
    echo "-- index: $idx"
    echo "-- table: $table"
    echo "$sql_stmt;"
    echo
  done < "$CANDIDATE_FILE"
} > "$PLAN_FILE"

{
  echo "# FAZ 4 / 14.1.7 - Index Reconciliation Plan Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "INDEX_RECONCILIATION_PLAN=PASS"
  else
    echo "INDEX_RECONCILIATION_PLAN=FAIL"
  fi

  echo
  echo "## Safe Index Candidates"
  echo "STATUS | INDEX | TABLE | FILE | SQL"
  if [ -s "$CANDIDATE_FILE" ]; then
    cat "$CANDIDATE_FILE"
  else
    echo "safe candidate yok"
  fi

  echo
  echo "## Already Existing Indexes"
  if [ -s "$EXISTS_FILE" ]; then
    cat "$EXISTS_FILE"
  else
    echo "already exists index yok"
  fi

  echo
  echo "## Skipped Indexes"
  if [ -s "$SKIPPED_FILE" ]; then
    cat "$SKIPPED_FILE"
  else
    echo "skipped index yok"
  fi

  echo
  echo "## Unknown Checks"
  if [ -s "$UNKNOWN_FILE" ]; then
    cat "$UNKNOWN_FILE"
  else
    echo "unknown check yok"
  fi

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
  echo "PASSWORD_MASKING=ENABLED"
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "PLAN_FILE=$PLAN_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SAFE_INDEX_CANDIDATE_COUNT=$SAFE_INDEX_CANDIDATE_COUNT"
echo "SKIPPED_TABLE_MISSING_COUNT=$SKIPPED_TABLE_MISSING_COUNT"
echo "ALREADY_EXISTS_INDEX_COUNT=$ALREADY_EXISTS_INDEX_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "INDEX_RECONCILIATION_PLAN=FAIL ❌"
  exit 1
fi

echo "INDEX_RECONCILIATION_PLAN=PASS ✅"
