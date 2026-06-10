#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_4_db_connection_evidence_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0
FOUND_COUNT=0
WORKING_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
CANDIDATES_FILE="$(mktemp)"
WORKING_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$CANDIDATES_FILE" "$WORKING_FILE"' EXIT

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

mask_secret() {
  local v="$1"

  v="$(printf '%s' "$v" | sed -E 's#(://[^:/@]+:)[^@]+@#\1***@#g')"
  v="$(printf '%s' "$v" | sed -E 's#(password=)[^[:space:]]+#\1***#Ig')"
  v="$(printf '%s' "$v" | sed -E 's#(pwd=)[^[:space:]]+#\1***#Ig')"

  echo "$v"
}

is_placeholder_dsn() {
  local v="$1"

  case "$v" in
    *"postgres://user:"*|*"postgresql://user:"*|*"dbname"*|*"password=changeme"*|*"password=postgres"*|*"example"*|*"localhost:5433/dbname"*)
      return 0
      ;;
  esac

  return 1
}

extract_from_file() {
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

add_candidate() {
  local key="$1"
  local source="$2"
  local value="$3"

  [ -n "$value" ] || return 0

  FOUND_COUNT=$((FOUND_COUNT + 1))

  local masked=""
  masked="$(mask_secret "$value")"

  local placeholder="NO"
  if is_placeholder_dsn "$value"; then
    placeholder="YES"
  fi

  printf '%s\t%s\t%s\t%s\n' "$key" "$source" "$placeholder" "$masked" >> "$CANDIDATES_FILE"

  if [ "$placeholder" = "YES" ]; then
    return 0
  fi

  if command -v psql >/dev/null 2>&1; then
    if PGCONNECT_TIMEOUT=3 psql "$value" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_phase4_14_1_4_psql_ok.log 2>/tmp/pix2pi_phase4_14_1_4_psql_err.log; then
      WORKING_COUNT=$((WORKING_COUNT + 1))
      printf '%s\t%s\t%s\n' "$key" "$source" "$masked" >> "$WORKING_FILE"

      SCHEMA_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$value" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/dev/null || echo "error")"
      detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

      if [ "$SCHEMA_EXISTS" = "t" ]; then
        HAS_DIRTY_COL="$(PGCONNECT_TIMEOUT=3 psql "$value" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from information_schema.columns where table_schema='public' and table_name='schema_migrations' and column_name='dirty');" 2>/dev/null || echo "error")"
        detail "SCHEMA_MIGRATIONS_HAS_DIRTY_COLUMN=$HAS_DIRTY_COL"

        if [ "$HAS_DIRTY_COL" = "t" ]; then
          DIRTY_STATE="$(PGCONNECT_TIMEOUT=3 psql "$value" -v ON_ERROR_STOP=1 -Atqc "select coalesce(bool_or(dirty), false) from public.schema_migrations;" 2>/dev/null || echo "error")"
          detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DIRTY_STATE"

          if [ "$DIRTY_STATE" = "t" ]; then
            fail "schema_migrations dirty state TRUE"
          fi
        fi
      fi
    fi
  fi
}

KEYS=(
  DB_DSN
  DB_WRITE_DSN
  DATABASE_URL
  POSTGRES_DSN
  POSTGRES_URL
  DATABASE_DSN
)

FILES=(
  "$ROOT_DIR/.env"
  "$ROOT_DIR/.env.local"
  "$ROOT_DIR/.env.production"
  "$ROOT_DIR/config/.env"
  "$ROOT_DIR/config/common.env"
  "$ROOT_DIR/deploy/.env"
  "$ROOT_DIR/deploy/env/common.env"
  "$ROOT_DIR/infra/.env"
  "/etc/pix2pi/ports.env"
  "/etc/pix2pi/common.env"
  "/opt/pix2pi/orchestrator/env/common.env"
  "/opt/pix2pi/env/common.env"
)

detail "ROOT_DIR=$ROOT_DIR"

for key in "${KEYS[@]}"; do
  value="$(printenv "$key" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    add_candidate "$key" "process_env" "$value"
  fi
done

for file in "${FILES[@]}"; do
  [ -r "$file" ] || continue

  for key in "${KEYS[@]}"; do
    value="$(extract_from_file "$file" "$key" || true)"
    if [ -n "$value" ]; then
      add_candidate "$key" "$file" "$value"
    fi
  done
done

detail "DSN_CANDIDATE_COUNT=$FOUND_COUNT"
detail "WORKING_DSN_COUNT=$WORKING_COUNT"

if ! command -v psql >/dev/null 2>&1; then
  warn "psql bulunamadi; real DB connection evidence alinamadi"
  detail "DB_CONNECTION_CHECK=PSQL_NOT_FOUND"
elif [ "$FOUND_COUNT" -eq 0 ]; then
  warn "DSN adayi bulunamadi"
  detail "DB_CONNECTION_CHECK=NO_DSN"
elif [ "$WORKING_COUNT" -eq 0 ]; then
  warn "DSN adaylari bulundu ama calisan DB baglantisi kanitlanamadi"
  detail "DB_CONNECTION_CHECK=NEEDS_REAL_DSN"
else
  detail "DB_CONNECTION_CHECK=PASS"
fi

{
  echo "# FAZ 4 / 14.1.4 - Real DB Connection Evidence Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ] && [ "$WORKING_COUNT" -gt 0 ]; then
    echo "DB_CONNECTION_EVIDENCE=PASS"
  elif [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_CONNECTION_EVIDENCE=NEEDS_REAL_DSN"
  else
    echo "DB_CONNECTION_EVIDENCE=FAIL"
  fi

  echo
  echo "## DSN Candidates"
  if [ -s "$CANDIDATES_FILE" ]; then
    echo "KEY | SOURCE | PLACEHOLDER | MASKED_DSN"
    cat "$CANDIDATES_FILE"
  else
    echo "DSN adayi yok"
  fi

  echo
  echo "## Working DSN"
  if [ -s "$WORKING_FILE" ]; then
    echo "KEY | SOURCE | MASKED_DSN"
    cat "$WORKING_FILE"
  else
    echo "Calisan DSN kanitlanamadi"
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
echo "WORKING_DSN_COUNT=$WORKING_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_CONNECTION_EVIDENCE=FAIL ❌"
  exit 1
fi

if [ "$WORKING_COUNT" -gt 0 ]; then
  echo "DB_CONNECTION_EVIDENCE=PASS ✅"
else
  echo "DB_CONNECTION_EVIDENCE=NEEDS_REAL_DSN ⚠️"
fi
