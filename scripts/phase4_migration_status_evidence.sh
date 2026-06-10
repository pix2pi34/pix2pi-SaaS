#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"
MIGRATION_DIR="$ROOT_DIR/db/migrations"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_5_migration_status_evidence_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
LOCAL_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$LOCAL_FILE"' EXIT

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

detail "ROOT_DIR=$ROOT_DIR"
detail "ENV_FILE=$ENV_FILE"
detail "MIGRATION_DIR=db/migrations"

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
  find "$MIGRATION_DIR" -maxdepth 1 -type f -name '*.up.sql' | sort | while IFS= read -r f; do
    base="$(basename "$f")"
    version="${base%%_*}"
    echo "$version | $base" >> "$LOCAL_FILE"
  done

  LOCAL_UP_COUNT="$(wc -l < "$LOCAL_FILE" | tr -d ' ')"
  LOCAL_LATEST_VERSION="$(tail -n 1 "$LOCAL_FILE" | awk '{print $1}' || true)"

  detail "LOCAL_UP_MIGRATION_COUNT=$LOCAL_UP_COUNT"
  detail "LOCAL_LATEST_VERSION=$LOCAL_LATEST_VERSION"

  if [ "$LOCAL_UP_COUNT" -eq 0 ]; then
    fail "local up migration bulunamadi"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_1_5_psql_ok.log 2>/tmp/pix2pi_14_1_5_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_1_5_recovery_err.log || echo "error")"

  detail "PG_IS_IN_RECOVERY=$IN_RECOVERY"

  case "$IN_RECOVERY" in
    f)
      detail "DB_ROLE=PRIMARY_WRITE"
      ;;
    t)
      detail "DB_ROLE=REPLICA_READ_ONLY"
      fail "DB is replica/read-only; migration status must use primary write DSN"
      ;;
    *)
      fail "pg_is_in_recovery okunamadi"
      ;;
  esac
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  SCHEMA_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/tmp/pix2pi_14_1_5_schema_exists_err.log || echo "error")"
  detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

  if [ "$SCHEMA_EXISTS" != "t" ]; then
    fail "public.schema_migrations bulunamadi"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  HAS_VERSION_COL="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from information_schema.columns where table_schema='public' and table_name='schema_migrations' and column_name='version');" 2>/dev/null || echo "error")"
  HAS_DIRTY_COL="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from information_schema.columns where table_schema='public' and table_name='schema_migrations' and column_name='dirty');" 2>/dev/null || echo "error")"

  detail "SCHEMA_MIGRATIONS_HAS_VERSION_COLUMN=$HAS_VERSION_COL"
  detail "SCHEMA_MIGRATIONS_HAS_DIRTY_COLUMN=$HAS_DIRTY_COL"

  if [ "$HAS_VERSION_COL" != "t" ]; then
    fail "schema_migrations.version column yok"
  fi

  if [ "$HAS_DIRTY_COL" != "t" ]; then
    fail "schema_migrations.dirty column yok"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  DB_CURRENT_VERSION="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select max(version)::text from public.schema_migrations;" 2>/tmp/pix2pi_14_1_5_version_err.log || echo "error")"
  DB_DIRTY_STATE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select coalesce(bool_or(dirty), false) from public.schema_migrations;" 2>/tmp/pix2pi_14_1_5_dirty_err.log || echo "error")"
  DB_ROW_COUNT="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select count(*)::text from public.schema_migrations;" 2>/tmp/pix2pi_14_1_5_count_err.log || echo "error")"

  detail "SCHEMA_MIGRATIONS_ROW_COUNT=$DB_ROW_COUNT"
  detail "DB_CURRENT_VERSION=$DB_CURRENT_VERSION"
  detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DB_DIRTY_STATE"

  if [ "$DB_DIRTY_STATE" != "f" ]; then
    fail "schema_migrations dirty state temiz degil: $DB_DIRTY_STATE"
  fi

  if [ -z "$DB_CURRENT_VERSION" ] || [ "$DB_CURRENT_VERSION" = "error" ]; then
    fail "DB current version okunamadi"
  fi
fi

{
  echo "# FAZ 4 / 14.1.5 - Migration Status Evidence Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_STATUS_EVIDENCE=PASS"
  else
    echo "MIGRATION_STATUS_EVIDENCE=FAIL"
  fi

  echo
  echo "## Local Up Migrations"
  if [ -s "$LOCAL_FILE" ]; then
    cat "$LOCAL_FILE"
  else
    echo "local migration yok"
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

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "MIGRATION_STATUS_EVIDENCE=FAIL ❌"
  exit 1
fi

echo "MIGRATION_STATUS_EVIDENCE=PASS ✅"
