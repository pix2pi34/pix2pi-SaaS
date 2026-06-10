#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"
MIGRATION_DIR="$ROOT_DIR/db/migrations"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_6_migration_drift_evidence_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0
EXPECTED_COUNT=0
EXISTING_COUNT=0
MISSING_COUNT=0
UNKNOWN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
EXPECTED_FILE="$(mktemp)"
RESULT_FILE="$(mktemp)"
MISSING_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$EXPECTED_FILE" "$RESULT_FILE" "$MISSING_FILE"' EXIT

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

clean_identifier() {
  local v="$1"

  v="$(printf '%s' "$v" | tr -d '\r' | sed -E 's/[;,(].*$//')"
  v="$(printf '%s' "$v" | sed -E 's/^"//; s/"$//; s/"//g')"
  v="$(printf '%s' "$v" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

  echo "$v"
}

normalize_relation_name() {
  local obj="$1"

  obj="$(clean_identifier "$obj")"

  if [[ "$obj" != *"."* ]]; then
    obj="public.$obj"
  fi

  echo "$obj"
}

parse_index_line() {
  local line="$1"
  local short="$2"
  local rest=""
  local index_name=""
  local table_name=""

  rest="$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX[[:space:]]+(CONCURRENTLY[[:space:]]+)?(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?//I')"

  index_name="$(printf '%s\n' "$rest" | awk '{print $1}')"
  index_name="$(clean_identifier "$index_name")"

  table_name="$(printf '%s\n' "$rest" | sed -E 's/^([^[:space:]]+)[[:space:]]+ON[[:space:]]+//I' | awk '{print $1}')"
  table_name="$(normalize_relation_name "$table_name")"

  if [ -n "$index_name" ]; then
    echo "INDEX|$index_name|$table_name|$short" >> "$EXPECTED_FILE"
  fi
}

parse_objects_from_file() {
  local file="$1"
  local short=""
  local line=""
  local obj=""

  short="${file#$ROOT_DIR/}"

  while IFS= read -r line; do
    line="$(printf '%s' "$line" | sed -E 's/--.*$//')"

    if printf '%s\n' "$line" | grep -Eiq '^[[:space:]]*CREATE[[:space:]]+SCHEMA'; then
      obj="$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*CREATE[[:space:]]+SCHEMA[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?//I')"
      obj="$(clean_identifier "$obj")"
      [ -n "$obj" ] && echo "SCHEMA|$obj|-|$short" >> "$EXPECTED_FILE"
    fi

    if printf '%s\n' "$line" | grep -Eiq '^[[:space:]]*CREATE[[:space:]]+TABLE'; then
      obj="$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?//I')"
      obj="$(normalize_relation_name "$obj")"
      [ -n "$obj" ] && echo "TABLE|$obj|-|$short" >> "$EXPECTED_FILE"
    fi

    if printf '%s\n' "$line" | grep -Eiq '^[[:space:]]*CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX'; then
      parse_index_line "$line" "$short"
    fi
  done < "$file"
}

sql_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

split_schema_table() {
  local rel="$1"
  local schema=""
  local name=""

  if [[ "$rel" == *"."* ]]; then
    schema="${rel%%.*}"
    name="${rel#*.}"
  else
    schema="public"
    name="$rel"
  fi

  printf '%s|%s' "$schema" "$name"
}

check_schema_exists() {
  local schema="$1"
  local escaped=""
  escaped="$(sql_escape "$schema")"
  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from information_schema.schemata where schema_name='${escaped}');" 2>/tmp/pix2pi_14_1_6_schema_check_err.log || echo "error"
}

check_relation_exists() {
  local rel="$1"
  local escaped=""
  escaped="$(sql_escape "$rel")"
  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('${escaped}') is not null;" 2>/tmp/pix2pi_14_1_6_relation_check_err.log || echo "error"
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

  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from pg_indexes where schemaname='${escaped_schema}' and tablename='${escaped_table}' and indexname='${escaped_index}');" 2>/tmp/pix2pi_14_1_6_index_check_err.log || echo "error"
}

detail "ROOT_DIR=$ROOT_DIR"
detail "ENV_FILE=$ENV_FILE"
detail "MIGRATION_DIR=db/migrations"
detail "MUTATION=NO"
detail "APPLY=NO"
detail "INDEX_PARSE_CORRECTION=ENABLED"

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

if [ ! -d "$MIGRATION_DIR" ]; then
  fail "migration dir not found: db/migrations"
else
  while IFS= read -r f; do
    parse_objects_from_file "$f"
  done < <(find "$MIGRATION_DIR" -maxdepth 1 -type f -name '*.up.sql' | sort)
fi

sort -u "$EXPECTED_FILE" -o "$EXPECTED_FILE"

EXPECTED_COUNT="$(wc -l < "$EXPECTED_FILE" | tr -d ' ')"
EXPECTED_INDEX_COUNT="$(awk -F'|' '$1=="INDEX" {c++} END {print c+0}' "$EXPECTED_FILE")"

detail "EXPECTED_OBJECT_COUNT=$EXPECTED_COUNT"
detail "EXPECTED_INDEX_COUNT=$EXPECTED_INDEX_COUNT"

if [ "$EXPECTED_COUNT" -eq 0 ]; then
  warn "migration dosyalarindan create object bulunamadi"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_1_6_psql_ok.log 2>/tmp/pix2pi_14_1_6_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_1_6_recovery_err.log || echo "error")"
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

if [ "$FAIL_COUNT" -eq 0 ]; then
  while IFS='|' read -r type obj aux file; do
    [ -n "$type" ] || continue

    exists="error"

    case "$type" in
      SCHEMA)
        exists="$(check_schema_exists "$obj")"
        ;;
      TABLE)
        exists="$(check_relation_exists "$obj")"
        ;;
      INDEX)
        exists="$(check_index_exists "$obj" "$aux")"
        ;;
      *)
        exists="error"
        ;;
    esac

    case "$exists" in
      t)
        EXISTING_COUNT=$((EXISTING_COUNT + 1))
        echo "EXISTS|$type|$obj|$aux|$file" >> "$RESULT_FILE"
        ;;
      f)
        MISSING_COUNT=$((MISSING_COUNT + 1))
        echo "MISSING|$type|$obj|$aux|$file" >> "$RESULT_FILE"
        echo "MISSING|$type|$obj|$aux|$file" >> "$MISSING_FILE"
        ;;
      *)
        UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
        echo "UNKNOWN|$type|$obj|$aux|$file" >> "$RESULT_FILE"
        ;;
    esac
  done < "$EXPECTED_FILE"
fi

detail "EXISTING_OBJECT_COUNT=$EXISTING_COUNT"
detail "MISSING_OBJECT_COUNT=$MISSING_COUNT"
detail "UNKNOWN_OBJECT_COUNT=$UNKNOWN_COUNT"

if [ "$MISSING_COUNT" -gt 0 ]; then
  detail "DRIFT_STATUS=OBJECTS_MISSING"
  warn "migration dosyalarinda beklenen bazi objeler DB'de yok"
else
  detail "DRIFT_STATUS=NO_MISSING_OBJECTS"
fi

if [ "$UNKNOWN_COUNT" -gt 0 ]; then
  warn "bazi objelerin varligi kontrol edilemedi"
fi

SCHEMA_EXISTS="unknown"
DIRTY_STATE="unknown"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SCHEMA_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/dev/null || echo "error")"
  detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

  if [ "$SCHEMA_EXISTS" = "t" ]; then
    DIRTY_STATE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select coalesce(bool_or(dirty), false) from public.schema_migrations;" 2>/dev/null || echo "error")"
    detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DIRTY_STATE"
  fi
fi

{
  echo "# FAZ 4 / 14.1.6 - Migration Drift Evidence Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_DRIFT_EVIDENCE=PASS"
  else
    echo "MIGRATION_DRIFT_EVIDENCE=FAIL"
  fi

  echo
  echo "## Expected Objects"
  echo "TYPE | OBJECT | AUX_TABLE | FILE"
  if [ -s "$EXPECTED_FILE" ]; then
    cat "$EXPECTED_FILE"
  else
    echo "expected object yok"
  fi

  echo
  echo "## Object Check Results"
  echo "STATUS | TYPE | OBJECT | AUX_TABLE | FILE"
  if [ -s "$RESULT_FILE" ]; then
    cat "$RESULT_FILE"
  else
    echo "object check sonucu yok"
  fi

  echo
  echo "## Missing Objects"
  if [ -s "$MISSING_FILE" ]; then
    cat "$MISSING_FILE"
  else
    echo "OK ✅ missing object yok"
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
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "EXPECTED_OBJECT_COUNT=$EXPECTED_COUNT"
echo "MISSING_OBJECT_COUNT=$MISSING_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "MIGRATION_DRIFT_EVIDENCE=FAIL ❌"
  exit 1
fi

echo "MIGRATION_DRIFT_EVIDENCE=PASS ✅"
