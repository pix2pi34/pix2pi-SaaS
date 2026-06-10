#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_2_1_db_backup_pitr_readiness_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
BACKUP_PATHS_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$BACKUP_PATHS_FILE" "$TOOL_FILE"' EXIT

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

tool_status() {
  local tool="$1"

  if command -v "$tool" >/dev/null 2>&1; then
    echo "TOOL_${tool}=FOUND" >> "$TOOL_FILE"
    return 0
  fi

  echo "TOOL_${tool}=NOT_FOUND" >> "$TOOL_FILE"
  return 1
}

path_status() {
  local label="$1"
  local path="$2"

  if [ -e "$path" ]; then
    size="$(du -sh "$path" 2>/dev/null | awk '{print $1}' || echo unknown)"
    echo "$label|EXISTS|$path|$size" >> "$BACKUP_PATHS_FILE"
  else
    echo "$label|NOT_FOUND|$path|-" >> "$BACKUP_PATHS_FILE"
  fi
}

detail "ROOT_DIR=$ROOT_DIR"
detail "ENV_FILE=$ENV_FILE"
detail "MUTATION=NO"
detail "BACKUP_DELETE=NO"
detail "RESTORE_EXECUTED=NO"
detail "PITR_CONFIG_CHANGE=NO"

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

PG_DUMP_FOUND=0
PG_RESTORE_FOUND=0
PSQL_FOUND=0
RESTIC_FOUND=0

if tool_status "psql"; then PSQL_FOUND=1; fi
if tool_status "pg_dump"; then PG_DUMP_FOUND=1; fi
if tool_status "pg_restore"; then PG_RESTORE_FOUND=1; fi
if tool_status "restic"; then RESTIC_FOUND=1; fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

if [ "$PG_DUMP_FOUND" -ne 1 ]; then
  warn "pg_dump bulunamadi; logical backup readiness eksik"
fi

if [ "$PG_RESTORE_FOUND" -ne 1 ]; then
  warn "pg_restore bulunamadi; restore drill readiness eksik"
fi

if [ "$RESTIC_FOUND" -ne 1 ]; then
  warn "restic bulunamadi; file-level backup repo kontrolu eksik"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_2_1_psql_ok.log 2>/tmp/pix2pi_14_2_1_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_2_1_recovery_err.log || echo "error")"
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

WAL_LEVEL="unknown"
ARCHIVE_MODE="unknown"
ARCHIVE_COMMAND="unknown"
MAX_WAL_SENDERS="unknown"
WAL_KEEP_SIZE="unknown"
DATA_DIRECTORY="unknown"

if [ "$FAIL_COUNT" -eq 0 ]; then
  WAL_LEVEL="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show wal_level;" 2>/dev/null || echo "error")"
  ARCHIVE_MODE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_mode;" 2>/dev/null || echo "error")"
  ARCHIVE_COMMAND="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_command;" 2>/dev/null || echo "error")"
  MAX_WAL_SENDERS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show max_wal_senders;" 2>/dev/null || echo "error")"
  WAL_KEEP_SIZE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show wal_keep_size;" 2>/dev/null || echo "error")"
  DATA_DIRECTORY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show data_directory;" 2>/dev/null || echo "error")"

  detail "POSTGRES_WAL_LEVEL=$WAL_LEVEL"
  detail "POSTGRES_ARCHIVE_MODE=$ARCHIVE_MODE"
  detail "POSTGRES_ARCHIVE_COMMAND_STATUS=$(if [ "$ARCHIVE_COMMAND" = "(disabled)" ] || [ -z "$ARCHIVE_COMMAND" ]; then echo DISABLED; else echo CONFIGURED; fi)"
  detail "POSTGRES_MAX_WAL_SENDERS=$MAX_WAL_SENDERS"
  detail "POSTGRES_WAL_KEEP_SIZE=$WAL_KEEP_SIZE"
  detail "POSTGRES_DATA_DIRECTORY=$DATA_DIRECTORY"
fi

PITR_READY="NO"
RESTORE_DRILL_READY="NO"
LOGICAL_BACKUP_READY="NO"
FILE_BACKUP_REPO_FOUND="NO"

if [ "$PG_DUMP_FOUND" -eq 1 ]; then
  LOGICAL_BACKUP_READY="YES"
fi

if [ "$PG_DUMP_FOUND" -eq 1 ] && [ "$PG_RESTORE_FOUND" -eq 1 ]; then
  RESTORE_DRILL_READY="YES"
fi

if [ "$WAL_LEVEL" = "replica" ] || [ "$WAL_LEVEL" = "logical" ]; then
  WAL_LEVEL_READY="YES"
else
  WAL_LEVEL_READY="NO"
fi

if [ "$ARCHIVE_MODE" = "on" ] || [ "$ARCHIVE_MODE" = "always" ]; then
  ARCHIVE_MODE_READY="YES"
else
  ARCHIVE_MODE_READY="NO"
fi

if [ "$WAL_LEVEL_READY" = "YES" ] && [ "$ARCHIVE_MODE_READY" = "YES" ] && [ "$ARCHIVE_COMMAND" != "(disabled)" ] && [ -n "$ARCHIVE_COMMAND" ]; then
  PITR_READY="YES"
fi

path_status "PROJECT_BACKUPS" "$ROOT_DIR/backups"
path_status "RESTIC_REPO_ROOT" "/root/pix2pi-restic-repo"
path_status "ALT_RESTIC_REPO_ROOT" "/root/pix2pi/pix2pi-restic-repo"
path_status "PIX2PI_LOG_ARCHIVE" "/var/log/pix2pi/archive"
path_status "POSTGRES_DATA_DIRECTORY" "$DATA_DIRECTORY"

if grep -q 'RESTIC_REPO_ROOT|EXISTS' "$BACKUP_PATHS_FILE" || grep -q 'ALT_RESTIC_REPO_ROOT|EXISTS' "$BACKUP_PATHS_FILE"; then
  FILE_BACKUP_REPO_FOUND="YES"
fi

detail "LOGICAL_BACKUP_READY=$LOGICAL_BACKUP_READY"
detail "RESTORE_DRILL_READY=$RESTORE_DRILL_READY"
detail "WAL_LEVEL_READY=$WAL_LEVEL_READY"
detail "ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY"
detail "PITR_READY=$PITR_READY"
detail "FILE_BACKUP_REPO_FOUND=$FILE_BACKUP_REPO_FOUND"

if [ "$PITR_READY" != "YES" ]; then
  warn "PITR tam hazir degil; archive_mode/archive_command kontrol edilmeli"
fi

if [ "$RESTORE_DRILL_READY" != "YES" ]; then
  warn "restore drill hazirligi eksik"
fi

if [ "$FILE_BACKUP_REPO_FOUND" != "YES" ]; then
  warn "file-level backup repo bulunamadi"
fi

{
  echo "# FAZ 4 / 14.2.1 - DB Backup / Restore / PITR Readiness Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS"
  else
    echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Backup Paths"
  echo "LABEL | STATUS | PATH | SIZE"
  if [ -s "$BACKUP_PATHS_FILE" ]; then
    cat "$BACKUP_PATHS_FILE"
  else
    echo "backup path yok"
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
echo "RESTORE_DRILL_READY=$RESTORE_DRILL_READY"
echo "PITR_READY=$PITR_READY"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=FAIL ❌"
  exit 1
fi

echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS ✅"
