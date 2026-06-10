#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"
MIGRATION_DIR="$ROOT_DIR/db/migrations"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_5A_migration_version_normalization_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
LOCAL_FILE="$(mktemp)"
MATCH_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$LOCAL_FILE" "$MATCH_FILE"' EXIT

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

normalize_version() {
  local raw="$1"
  local compact=""

  compact="$(printf '%s' "$raw" | tr -d '_')"

  compact="$(printf '%s' "$compact" | sed -E 's/^0+//')"

  if [ -z "$compact" ]; then
    compact="0"
  fi

  echo "$compact"
}

parse_file() {
  local f="$1"
  local base=""
  local raw_version=""
  local norm_version=""
  local style=""

  base="$(basename "$f")"
  base="${base%.up.sql}"

  if [[ "$base" =~ ^([0-9]{14})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}"
    style="NEW_STANDARD_TIMESTAMP"
  elif [[ "$base" =~ ^([0-9]{8}_[0-9]{6})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}"
    style="LEGACY_SPLIT_TIMESTAMP"
  elif [[ "$base" =~ ^([0-9]{8}_[0-9]{7})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}"
    style="LEGACY_SPLIT_TIMESTAMP_7_DIGIT_TIME"
  elif [[ "$base" =~ ^([0-9]{3,4})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}"
    style="LEGACY_SEQUENCE"
  else
    raw_version="INVALID"
    norm_version="INVALID"
    style="INVALID"
    echo "$norm_version | $raw_version | $style | $base.up.sql"
    return 0
  fi

  norm_version="$(normalize_version "$raw_version")"
  echo "$norm_version | $raw_version | $style | $base.up.sql"
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

if [ -z "$DB_DSN" ] && [ -z "${PHASE4_TEST_DB_VERSION:-}" ]; then
  fail "DB DSN bulunamadi"
else
  if [ -n "$DB_DSN" ]; then
    detail "DB_DSN_STATUS=CONFIGURED"
    detail "DB_DSN_MASKED=$(mask_secret "$DB_DSN")"
  else
    detail "DB_DSN_STATUS=TEST_OVERRIDE"
  fi
fi

if [ ! -d "$MIGRATION_DIR" ]; then
  fail "migration dir not found: db/migrations"
else
  while IFS= read -r f; do
    parse_file "$f" >> "$LOCAL_FILE"
  done < <(find "$MIGRATION_DIR" -maxdepth 1 -type f -name '*.up.sql' | sort)

  LOCAL_UP_COUNT="$(wc -l < "$LOCAL_FILE" | tr -d ' ')"
  LOCAL_INVALID_COUNT="$(grep -c '^INVALID' "$LOCAL_FILE" 2>/dev/null || true)"

  LOCAL_LATEST_NORMALIZED_VERSION="$(awk -F'|' '
    {
      gsub(/ /, "", $1)
      if ($1 != "INVALID" && $1 != "") {
        print $1
      }
    }
  ' "$LOCAL_FILE" | sort -n | tail -n 1)"

  LOCAL_LATEST_FILE="$(awk -F'|' -v latest="$LOCAL_LATEST_NORMALIZED_VERSION" '
    {
      n=$1
      gsub(/ /, "", n)
      if (n == latest) {
        print $4
      }
    }
  ' "$LOCAL_FILE" | tail -n 1 | sed 's/^ *//')"

  detail "LOCAL_UP_MIGRATION_COUNT=$LOCAL_UP_COUNT"
  detail "LOCAL_INVALID_VERSION_COUNT=$LOCAL_INVALID_COUNT"
  detail "LOCAL_LATEST_NORMALIZED_VERSION=$LOCAL_LATEST_NORMALIZED_VERSION"
  detail "LOCAL_LATEST_FILE=$LOCAL_LATEST_FILE"

  if [ "$LOCAL_UP_COUNT" -eq 0 ]; then
    fail "local up migration bulunamadi"
  fi

  if [ "$LOCAL_INVALID_COUNT" -gt 0 ]; then
    warn "invalid local migration filename var"
  fi
fi

DB_ROLE="UNKNOWN"
DB_CURRENT_VERSION=""
DB_CURRENT_VERSION_NORMALIZED=""
DB_DIRTY_STATE=""
SCHEMA_EXISTS=""

if [ -n "${PHASE4_TEST_DB_VERSION:-}" ]; then
  DB_ROLE="${PHASE4_TEST_DB_ROLE:-PRIMARY_WRITE}"
  DB_CURRENT_VERSION="$PHASE4_TEST_DB_VERSION"
  DB_DIRTY_STATE="${PHASE4_TEST_DB_DIRTY_STATE:-f}"
  SCHEMA_EXISTS="${PHASE4_TEST_SCHEMA_EXISTS:-t}"

  detail "DB_CONNECTION_CHECK=TEST_OVERRIDE"
  detail "DB_ROLE=$DB_ROLE"
  detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"
  detail "DB_CURRENT_VERSION=$DB_CURRENT_VERSION"
  detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DB_DIRTY_STATE"
else
  if ! command -v psql >/dev/null 2>&1; then
    fail "psql bulunamadi"
  fi

  if [ "$FAIL_COUNT" -eq 0 ]; then
    if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_1_5A_psql_ok.log 2>/tmp/pix2pi_14_1_5A_psql_err.log; then
      detail "DB_CONNECTION_CHECK=PASS"
    else
      fail "DB connection failed"
    fi
  fi

  if [ "$FAIL_COUNT" -eq 0 ]; then
    IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_1_5A_recovery_err.log || echo "error")"

    detail "PG_IS_IN_RECOVERY=$IN_RECOVERY"

    case "$IN_RECOVERY" in
      f)
        DB_ROLE="PRIMARY_WRITE"
        detail "DB_ROLE=PRIMARY_WRITE"
        ;;
      t)
        DB_ROLE="REPLICA_READ_ONLY"
        detail "DB_ROLE=REPLICA_READ_ONLY"
        fail "DB replica/read-only gorunuyor"
        ;;
      *)
        fail "pg_is_in_recovery okunamadi"
        ;;
    esac
  fi

  if [ "$FAIL_COUNT" -eq 0 ]; then
    SCHEMA_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/tmp/pix2pi_14_1_5A_schema_err.log || echo "error")"
    detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

    if [ "$SCHEMA_EXISTS" != "t" ]; then
      fail "public.schema_migrations bulunamadi"
    fi
  fi

  if [ "$FAIL_COUNT" -eq 0 ]; then
    DB_CURRENT_VERSION="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select max(version)::text from public.schema_migrations;" 2>/tmp/pix2pi_14_1_5A_version_err.log || echo "error")"
    DB_DIRTY_STATE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select coalesce(bool_or(dirty), false) from public.schema_migrations;" 2>/tmp/pix2pi_14_1_5A_dirty_err.log || echo "error")"

    detail "DB_CURRENT_VERSION=$DB_CURRENT_VERSION"
    detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DB_DIRTY_STATE"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  DB_CURRENT_VERSION_NORMALIZED="$(normalize_version "$DB_CURRENT_VERSION")"
  detail "DB_CURRENT_VERSION_NORMALIZED=$DB_CURRENT_VERSION_NORMALIZED"

  if [ "$DB_DIRTY_STATE" != "f" ]; then
    fail "schema_migrations dirty state temiz degil: $DB_DIRTY_STATE"
  fi

  awk -F'|' -v dbv="$DB_CURRENT_VERSION_NORMALIZED" '
    {
      n=$1
      gsub(/ /, "", n)
      if (n == dbv) {
        print $0
      }
    }
  ' "$LOCAL_FILE" > "$MATCH_FILE"

  MATCH_COUNT="$(wc -l < "$MATCH_FILE" | tr -d ' ')"

  if [ "$MATCH_COUNT" -gt 0 ]; then
    detail "DB_VERSION_MATCH_LOCAL=YES"
    MATCHED_FILE="$(head -n 1 "$MATCH_FILE" | awk -F'|' '{print $4}' | sed 's/^ *//')"
    detail "DB_VERSION_MATCHED_LOCAL_FILE=$MATCHED_FILE"
  else
    detail "DB_VERSION_MATCH_LOCAL=NO"
    warn "DB current version local active migration dosyalariyla eslesmedi"
  fi

  if [ "$DB_CURRENT_VERSION_NORMALIZED" = "$LOCAL_LATEST_NORMALIZED_VERSION" ]; then
    detail "DB_VERSION_EQUALS_LOCAL_LATEST=YES"
    detail "DB_LOCAL_CHAIN_MISMATCH=NO"
  else
    detail "DB_VERSION_EQUALS_LOCAL_LATEST=NO"
    detail "DB_LOCAL_CHAIN_MISMATCH=YES"
    warn "DB current version local latest migration ile ayni degil"
  fi

  detail "DB_LOCAL_CHAIN_MISMATCH_ANALYZED=YES"
fi

{
  echo "# FAZ 4 / 14.1.5A - Migration Version Normalization Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_VERSION_NORMALIZATION=PASS"
  else
    echo "MIGRATION_VERSION_NORMALIZATION=FAIL"
  fi

  echo
  echo "## Local Normalized Up Migrations"
  echo "NORMALIZED_VERSION | RAW_VERSION | STYLE | FILE"
  if [ -s "$LOCAL_FILE" ]; then
    cat "$LOCAL_FILE"
  else
    echo "local migration yok"
  fi

  echo
  echo "## DB Version Match"
  if [ -s "$MATCH_FILE" ]; then
    cat "$MATCH_FILE"
  else
    echo "DB version local dosyada eslesmedi"
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
  echo "MIGRATION_VERSION_NORMALIZATION=FAIL ❌"
  exit 1
fi

echo "MIGRATION_VERSION_NORMALIZATION=PASS ✅"
