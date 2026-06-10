#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
MODE="${2:-status}"
OUT_FILE="${3:-}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_3_migration_db_env_discovery_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE"' EXIT

detail() {
  echo "$1" >> "$DETAILS_FILE"
}

fail() {
  echo "FAIL ❌ $1" >> "$ISSUES_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
  echo "WARN ⚠️ $1" >> "$ISSUES_FILE"
  WARN_COUNT=$((WARN_COUNT + 1))
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

case "$MODE" in
  status|write-env)
    true
    ;;
  *)
    fail "invalid mode: $MODE"
    ;;
esac

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

FOUND_VALUE=""
FOUND_KEY=""
FOUND_SOURCE=""
FOUND_KIND=""

for key in "${KEYS[@]}"; do
  value="$(printenv "$key" 2>/dev/null || true)"

  if [ -n "$value" ]; then
    FOUND_VALUE="$value"
    FOUND_KEY="$key"
    FOUND_SOURCE="process_env"
    FOUND_KIND="environment"
    break
  fi
done

if [ -z "$FOUND_VALUE" ]; then
  for file in "${FILES[@]}"; do
    [ -r "$file" ] || continue

    for key in "${KEYS[@]}"; do
      value="$(extract_from_file "$file" "$key" || true)"

      if [ -n "$value" ]; then
        FOUND_VALUE="$value"
        FOUND_KEY="$key"
        FOUND_SOURCE="$file"
        FOUND_KIND="env_file"
        break 2
      fi
    done
  done
fi

detail "ROOT_DIR=$ROOT_DIR"
detail "MODE=$MODE"

if [ -n "$FOUND_VALUE" ]; then
  detail "FOUND_DSN=YES"
  detail "FOUND_DSN_KEY=$FOUND_KEY"
  detail "FOUND_DSN_SOURCE=$FOUND_SOURCE"
  detail "FOUND_DSN_KIND=$FOUND_KIND"
  detail "FOUND_DSN_MASKED=$(mask_secret "$FOUND_VALUE")"
else
  detail "FOUND_DSN=NO"
  warn "DB DSN bulunamadi; apply-check icin DB_DSN veya DB_WRITE_DSN standarda alinmali"
fi

if [ "$MODE" = "write-env" ]; then
  if [ -z "$OUT_FILE" ]; then
    fail "write-env mode requires output file path"
  elif [ -z "$FOUND_VALUE" ]; then
    fail "write-env mode requires discovered DSN"
  else
    umask 077
    {
      printf 'DB_DSN=%q\n' "$FOUND_VALUE"
      printf 'DB_DSN_KEY=%q\n' "$FOUND_KEY"
      printf 'DB_DSN_SOURCE=%q\n' "$FOUND_SOURCE"
    } > "$OUT_FILE"

    chmod 600 "$OUT_FILE"
    detail "WRITE_ENV_FILE=$OUT_FILE"
    detail "WRITE_ENV_STATUS=OK"
  fi
fi

if [ -n "$FOUND_VALUE" ]; then
  if command -v psql >/dev/null 2>&1; then
    if PGCONNECT_TIMEOUT=3 psql "$FOUND_VALUE" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_phase4_14_1_3_psql_ok.log 2>/tmp/pix2pi_phase4_14_1_3_psql_err.log; then
      detail "DB_CONNECTION_CHECK=PASS"

      SCHEMA_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$FOUND_VALUE" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/dev/null || echo "error")"
      detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

      if [ "$SCHEMA_EXISTS" = "t" ]; then
        HAS_DIRTY_COL="$(PGCONNECT_TIMEOUT=3 psql "$FOUND_VALUE" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from information_schema.columns where table_schema='public' and table_name='schema_migrations' and column_name='dirty');" 2>/dev/null || echo "error")"
        detail "SCHEMA_MIGRATIONS_HAS_DIRTY_COLUMN=$HAS_DIRTY_COL"

        if [ "$HAS_DIRTY_COL" = "t" ]; then
          DIRTY_STATE="$(PGCONNECT_TIMEOUT=3 psql "$FOUND_VALUE" -v ON_ERROR_STOP=1 -Atqc "select coalesce(bool_or(dirty), false) from public.schema_migrations;" 2>/dev/null || echo "error")"
          detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DIRTY_STATE"

          if [ "$DIRTY_STATE" = "t" ]; then
            fail "schema_migrations dirty state TRUE"
          fi
        fi
      fi
    else
      warn "DB connection check failed or timeout; raw DSN rapora yazilmadi"
      detail "DB_CONNECTION_CHECK=SKIPPED_OR_FAILED"
    fi
  else
    warn "psql bulunamadi; DB connection / dirty check skip edildi"
    detail "DB_CONNECTION_CHECK=PSQL_NOT_FOUND"
  fi
else
  detail "DB_CONNECTION_CHECK=NO_DSN"
fi

{
  echo "# FAZ 4 / 14.1.3 - Migration DB Env Discovery Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_ENV_DISCOVERY=PASS"
  else
    echo "DB_ENV_DISCOVERY=FAIL"
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
  echo "DB_ENV_DISCOVERY=FAIL ❌"
  exit 1
fi

echo "DB_ENV_DISCOVERY=PASS ✅"
