#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

STAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="$ROOT_DIR/backups/db/logical/phase4_14_2_2_${STAMP}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"

DUMP_FILE="$OUTPUT_DIR/pix2pi_schema_only.dump"
SHA_FILE="$OUTPUT_DIR/pix2pi_schema_only.dump.sha256"
RESTORE_LIST_FILE="$OUTPUT_DIR/pg_restore_list.txt"
PG_DUMP_ERR_FILE="$OUTPUT_DIR/pg_dump_error_sanitized.txt"
PG_RESTORE_ERR_FILE="$OUTPUT_DIR/pg_restore_error_sanitized.txt"

mkdir -p "$REPORT_DIR" "$OUTPUT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE"' EXIT

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
  v="$(printf '%s' "$v" | sed -E 's#(PGPASSWORD=)[^[:space:]]+#\1***#Ig')"
  echo "$v"
}

sanitize_file() {
  local in_file="$1"
  local out_file="$2"

  if [ -f "$in_file" ]; then
    sed -E \
      -e 's#(://[^:/@]+:)[^@]+@#\1***@#g' \
      -e 's#(password=)[^[:space:]]+#\1***#Ig' \
      -e 's#(PGPASSWORD=)[^[:space:]]+#\1***#Ig' \
      "$in_file" > "$out_file" || true
  fi
}

tool_status() {
  local tool="$1"

  if command -v "$tool" >/dev/null 2>&1; then
    echo "TOOL_${tool}=FOUND" >> "$TOOL_FILE"
    return 0
  fi

  echo "TOOL_${tool}=NOT_FOUND" >> "$TOOL_FILE"
  return 1
}

find_primary_container() {
  local containers=""
  local c=""
  local user_val=""
  local pass_val=""
  local db_val=""
  local recovery=""

  containers="$(docker ps --format '{{.Names}}' | grep -Ei 'postgres|pg|pix2pi.*db|db' || true)"

  for c in $containers; do
    user_val="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_USER=' | tail -n 1 | cut -d= -f2- || true)"
    pass_val="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_PASSWORD=' | tail -n 1 | cut -d= -f2- || true)"
    db_val="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_DB=' | tail -n 1 | cut -d= -f2- || true)"

    [ -n "$user_val" ] || user_val="postgres"
    [ -n "$db_val" ] || db_val="$user_val"

    if [ -z "$pass_val" ]; then
      continue
    fi

    recovery="$(docker exec -e PGPASSWORD="$pass_val" "$c" psql -U "$user_val" -d "$db_val" -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_2_2_container_recovery_err.log || echo "error")"

    if [ "$recovery" = "f" ]; then
      PRIMARY_CONTAINER="$c"
      PRIMARY_CONTAINER_USER="$user_val"
      PRIMARY_CONTAINER_PASS="$pass_val"
      PRIMARY_CONTAINER_DB="$db_val"
      return 0
    fi
  done

  return 1
}

detail "ROOT_DIR=$ROOT_DIR"
detail "ENV_FILE=$ENV_FILE"
detail "OUTPUT_DIR=${OUTPUT_DIR#$ROOT_DIR/}"
detail "DUMP_FILE=${DUMP_FILE#$ROOT_DIR/}"
detail "RESTORE_LIST_FILE=${RESTORE_LIST_FILE#$ROOT_DIR/}"
detail "DB_MUTATION=NO"
detail "RESTORE_EXECUTED=NO"
detail "PITR_CONFIG_CHANGE=NO"
detail "BACKUP_TYPE=SCHEMA_ONLY_CUSTOM_FORMAT"
detail "FALLBACK_ENABLED=YES"

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

PSQL_FOUND=0
PG_DUMP_FOUND=0
PG_RESTORE_FOUND=0
SHA256_FOUND=0
DOCKER_FOUND=0

if tool_status "psql"; then PSQL_FOUND=1; fi
if tool_status "pg_dump"; then PG_DUMP_FOUND=1; fi
if tool_status "pg_restore"; then PG_RESTORE_FOUND=1; fi
if tool_status "sha256sum"; then SHA256_FOUND=1; fi
if tool_status "docker"; then DOCKER_FOUND=1; fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

if [ "$PG_RESTORE_FOUND" -ne 1 ]; then
  warn "host pg_restore bulunamadi; docker fallback denenebilir"
fi

if [ "$SHA256_FOUND" -ne 1 ]; then
  warn "sha256sum bulunamadi; checksum uretilemeyecek"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_2_2_psql_ok.log 2>/tmp/pix2pi_14_2_2_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_2_2_recovery_err.log || echo "error")"
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
  SCHEMA_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/dev/null || echo "error")"
  detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

  if [ "$SCHEMA_EXISTS" = "t" ]; then
    DIRTY_STATE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select coalesce(bool_or(dirty), false) from public.schema_migrations;" 2>/dev/null || echo "error")"
    detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DIRTY_STATE"

    if [ "$DIRTY_STATE" != "f" ]; then
      fail "schema_migrations dirty state temiz degil: $DIRTY_STATE"
    fi
  else
    warn "schema_migrations bulunamadi veya okunamadi"
  fi
fi

DUMP_METHOD="NOT_STARTED"
PRIMARY_CONTAINER=""
PRIMARY_CONTAINER_USER=""
PRIMARY_CONTAINER_PASS=""
PRIMARY_CONTAINER_DB=""

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ "$PG_DUMP_FOUND" -eq 1 ]; then
    DUMP_METHOD="HOST_PG_DUMP"

    if PGCONNECT_TIMEOUT=5 pg_dump \
      --dbname="$DB_DSN" \
      --schema-only \
      --format=custom \
      --no-owner \
      --no-privileges \
      --file="$DUMP_FILE" \
      >/tmp/pix2pi_14_2_2_pg_dump_ok.log \
      2>/tmp/pix2pi_14_2_2_pg_dump_err.log
    then
      detail "PG_DUMP_METHOD=$DUMP_METHOD"
      detail "PG_DUMP_SMOKE=PASS"
    else
      sanitize_file /tmp/pix2pi_14_2_2_pg_dump_err.log "$PG_DUMP_ERR_FILE"
      warn "host pg_dump failed; docker primary pg_dump fallback denenecek"
      detail "HOST_PG_DUMP_ERROR_FILE=${PG_DUMP_ERR_FILE#$ROOT_DIR/}"
      rm -f "$DUMP_FILE"
    fi
  else
    warn "host pg_dump bulunamadi; docker primary pg_dump fallback denenecek"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ] && [ ! -s "$DUMP_FILE" ]; then
  if [ "$DOCKER_FOUND" -ne 1 ]; then
    fail "host pg_dump basarisiz ve docker bulunamadi"
  else
    if find_primary_container; then
      DUMP_METHOD="DOCKER_PRIMARY_PG_DUMP"
      detail "PRIMARY_CONTAINER=$PRIMARY_CONTAINER"
      detail "PRIMARY_CONTAINER_DB=$PRIMARY_CONTAINER_DB"

      if docker exec -e PGPASSWORD="$PRIMARY_CONTAINER_PASS" "$PRIMARY_CONTAINER" \
        pg_dump \
          -U "$PRIMARY_CONTAINER_USER" \
          -d "$PRIMARY_CONTAINER_DB" \
          --schema-only \
          --format=custom \
          --no-owner \
          --no-privileges \
        > "$DUMP_FILE" \
        2>/tmp/pix2pi_14_2_2_docker_pg_dump_err.log
      then
        detail "PG_DUMP_METHOD=$DUMP_METHOD"
        detail "PG_DUMP_SMOKE=PASS"
      else
        sanitize_file /tmp/pix2pi_14_2_2_docker_pg_dump_err.log "$PG_DUMP_ERR_FILE"
        detail "DOCKER_PG_DUMP_ERROR_FILE=${PG_DUMP_ERR_FILE#$ROOT_DIR/}"
        fail "docker primary pg_dump fallback failed"
      fi
    else
      fail "primary postgres container bulunamadi"
    fi
  fi
fi

DUMP_SIZE_BYTES=0

if [ -f "$DUMP_FILE" ]; then
  DUMP_SIZE_BYTES="$(wc -c < "$DUMP_FILE" | tr -d ' ')"
fi

detail "DUMP_SIZE_BYTES=$DUMP_SIZE_BYTES"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ ! -s "$DUMP_FILE" ]; then
    fail "dump file olusmadi veya bos"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ] && [ "$SHA256_FOUND" -eq 1 ]; then
  sha256sum "$DUMP_FILE" > "$SHA_FILE"
  detail "DUMP_SHA256_FILE=${SHA_FILE#$ROOT_DIR/}"
  detail "DUMP_SHA256=$(cut -d' ' -f1 "$SHA_FILE")"
fi

RESTORE_LIST_METHOD="NOT_STARTED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ "$PG_RESTORE_FOUND" -eq 1 ]; then
    RESTORE_LIST_METHOD="HOST_PG_RESTORE"

    if pg_restore --list "$DUMP_FILE" > "$RESTORE_LIST_FILE" 2>/tmp/pix2pi_14_2_2_pg_restore_list_err.log; then
      detail "PG_RESTORE_LIST_METHOD=$RESTORE_LIST_METHOD"
      detail "PG_RESTORE_LIST_CHECK=PASS"
    else
      sanitize_file /tmp/pix2pi_14_2_2_pg_restore_list_err.log "$PG_RESTORE_ERR_FILE"
      warn "host pg_restore --list failed; docker pg_restore fallback denenecek"
      rm -f "$RESTORE_LIST_FILE"
    fi
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ] && [ ! -s "$RESTORE_LIST_FILE" ]; then
  if [ -n "$PRIMARY_CONTAINER" ]; then
    RESTORE_LIST_METHOD="DOCKER_PRIMARY_PG_RESTORE"

    if docker exec -i "$PRIMARY_CONTAINER" pg_restore --list < "$DUMP_FILE" > "$RESTORE_LIST_FILE" 2>/tmp/pix2pi_14_2_2_docker_pg_restore_list_err.log; then
      detail "PG_RESTORE_LIST_METHOD=$RESTORE_LIST_METHOD"
      detail "PG_RESTORE_LIST_CHECK=PASS"
    else
      sanitize_file /tmp/pix2pi_14_2_2_docker_pg_restore_list_err.log "$PG_RESTORE_ERR_FILE"
      detail "PG_RESTORE_ERROR_FILE=${PG_RESTORE_ERR_FILE#$ROOT_DIR/}"
      fail "pg_restore --list dump okuyamadi"
    fi
  else
    fail "pg_restore --list icin uygun fallback yok"
  fi
fi

RESTORE_LIST_COUNT=0

if [ -f "$RESTORE_LIST_FILE" ]; then
  RESTORE_LIST_COUNT="$(wc -l < "$RESTORE_LIST_FILE" | tr -d ' ')"
fi

detail "PG_RESTORE_LIST_LINE_COUNT=$RESTORE_LIST_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ "$RESTORE_LIST_COUNT" -eq 0 ]; then
    fail "pg_restore list bos geldi"
  fi
fi

{
  echo "# FAZ 4 / 14.2.2 - Logical Backup Smoke Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "LOGICAL_BACKUP_SMOKE=PASS"
  else
    echo "LOGICAL_BACKUP_SMOKE=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Output Files"
  echo "DUMP_FILE=${DUMP_FILE#$ROOT_DIR/}"
  echo "SHA_FILE=${SHA_FILE#$ROOT_DIR/}"
  echo "RESTORE_LIST_FILE=${RESTORE_LIST_FILE#$ROOT_DIR/}"
  echo "PG_DUMP_ERROR_FILE=${PG_DUMP_ERR_FILE#$ROOT_DIR/}"
  echo "PG_RESTORE_ERROR_FILE=${PG_RESTORE_ERR_FILE#$ROOT_DIR/}"

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
echo "DUMP_FILE=$DUMP_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DUMP_SIZE_BYTES=$DUMP_SIZE_BYTES"
echo "PG_RESTORE_LIST_LINE_COUNT=$RESTORE_LIST_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "LOGICAL_BACKUP_SMOKE=FAIL ❌"
  exit 1
fi

echo "LOGICAL_BACKUP_SMOKE=PASS ✅"
