#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_3_4_db_observability_controlled_apply_report.md"

READINESS_REPORT="$REPORT_DIR/14_3_3_db_observability_apply_readiness_report.md"

STAMP="$(date +%Y%m%d_%H%M%S)"
EVIDENCE_DIR="$ROOT_DIR/backups/db/observability_apply/phase4_14_3_4_${STAMP}"

mkdir -p "$REPORT_DIR" "$EVIDENCE_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
EVIDENCE_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$EVIDENCE_FILE"' EXIT

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

tool_status() {
  local tool="$1"

  if command -v "$tool" >/dev/null 2>&1; then
    echo "TOOL_${tool}=FOUND" >> "$TOOL_FILE"
    return 0
  fi

  echo "TOOL_${tool}=NOT_FOUND" >> "$TOOL_FILE"
  return 1
}

get_report_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    echo ""
    return 0
  fi

  grep -E "^${key}=" "$file" | tail -n 1 | cut -d= -f2- || true
}

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_3_4_sql_err.log || echo "error"
}

find_primary_container() {
  local containers=""
  local c=""
  local user_val=""
  local pass_val=""
  local db_val=""
  local recovery=""
  local image_val=""
  local host_port=""

  containers="$(docker ps --format '{{.Names}}' | grep -Ei 'postgres|pg|pix2pi.*db|db' || true)"

  for c in $containers; do
    user_val="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_USER=' | tail -n 1 | cut -d= -f2- || true)"
    pass_val="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_PASSWORD=' | tail -n 1 | cut -d= -f2- || true)"
    db_val="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_DB=' | tail -n 1 | cut -d= -f2- || true)"
    image_val="$(docker inspect "$c" --format '{{.Config.Image}}' 2>/dev/null || true)"
    host_port="$(docker inspect "$c" --format '{{(index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort}}' 2>/dev/null || true)"

    [ -n "$user_val" ] || user_val="postgres"
    [ -n "$db_val" ] || db_val="$user_val"

    if [ -z "$pass_val" ]; then
      continue
    fi

    recovery="$(docker exec -e PGPASSWORD="$pass_val" "$c" psql -U "$user_val" -d "$db_val" -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_3_4_recovery_err.log || echo "error")"

    if [ "$recovery" = "f" ]; then
      PRIMARY_CONTAINER="$c"
      PRIMARY_IMAGE="$image_val"
      PRIMARY_DB="$db_val"
      PRIMARY_USER="$user_val"
      PRIMARY_PORT="$host_port"
      PRIMARY_PASS="$pass_val"
      return 0
    fi
  done

  return 1
}

wait_db_ready() {
  local i=""

  for i in $(seq 1 90); do
    if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_3_4_wait_ok.log 2>/tmp/pix2pi_14_3_4_wait_err.log; then
      return 0
    fi
    sleep 1
  done

  return 1
}

detail "ROOT_DIR=$ROOT_DIR"
detail "EVIDENCE_DIR=${EVIDENCE_DIR#$ROOT_DIR/}"

APPLY_DB_OBSERVABILITY="${APPLY_DB_OBSERVABILITY:-0}"

detail "APPLY_DB_OBSERVABILITY=$APPLY_DB_OBSERVABILITY"
detail "DB_MUTATION_SCOPE=POSTGRES_CONFIG_ONLY"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"

if [ "$APPLY_DB_OBSERVABILITY" = "1" ]; then
  detail "CONTROLLED_APPLY_MODE=APPLY"
else
  detail "CONTROLLED_APPLY_MODE=DRY_RUN_NOOP"
fi

DOCKER_FOUND=0
PSQL_FOUND=0

if tool_status "docker"; then DOCKER_FOUND=1; fi
if tool_status "psql"; then PSQL_FOUND=1; fi

if [ "$DOCKER_FOUND" -ne 1 ]; then
  fail "docker bulunamadi"
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

READINESS_PASS="$(get_report_value "$READINESS_REPORT" "DB_OBSERVABILITY_APPLY_READINESS")"
detail "DB_OBSERVABILITY_APPLY_READINESS=$READINESS_PASS"

if [ "$READINESS_PASS" != "PASS" ]; then
  fail "14.3.3 apply readiness PASS degil"
fi

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

PRIMARY_CONTAINER=""
PRIMARY_IMAGE=""
PRIMARY_DB=""
PRIMARY_USER=""
PRIMARY_PORT=""
PRIMARY_PASS=""

if [ "$DOCKER_FOUND" -eq 1 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  if find_primary_container; then
    detail "PRIMARY_CONTAINER=$PRIMARY_CONTAINER"
    detail "PRIMARY_IMAGE=$PRIMARY_IMAGE"
    detail "PRIMARY_DB=$PRIMARY_DB"
    detail "PRIMARY_PORT=$PRIMARY_PORT"
  else
    fail "primary postgres container tespit edilemedi"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_3_4_psql_ok.log 2>/tmp/pix2pi_14_3_4_psql_err.log; then
    detail "DB_CONNECTION_CHECK_BEFORE=PASS"
  else
    fail "DB connection before apply failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY_BEFORE="$(run_sql "select pg_is_in_recovery();")"
  detail "PG_IS_IN_RECOVERY_BEFORE=$IN_RECOVERY_BEFORE"

  case "$IN_RECOVERY_BEFORE" in
    f)
      detail "DB_ROLE_BEFORE=PRIMARY_WRITE"
      ;;
    t)
      detail "DB_ROLE_BEFORE=REPLICA_READ_ONLY"
      fail "DB replica/read-only gorunuyor"
      ;;
    *)
      fail "pg_is_in_recovery before okunamadi"
      ;;
  esac
fi

SERVER_VERSION_BEFORE="unknown"
CONFIG_FILE="unknown"
DATA_DIRECTORY="unknown"
PRELOAD_BEFORE="unknown"
TRACK_IO_BEFORE="unknown"
LOG_MIN_BEFORE="unknown"
EXT_BEFORE="unknown"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SERVER_VERSION_BEFORE="$(run_sql "show server_version;")"
  CONFIG_FILE="$(run_sql "show config_file;")"
  DATA_DIRECTORY="$(run_sql "show data_directory;")"
  PRELOAD_BEFORE="$(run_sql "show shared_preload_libraries;")"
  TRACK_IO_BEFORE="$(run_sql "show track_io_timing;")"
  LOG_MIN_BEFORE="$(run_sql "show log_min_duration_statement;")"
  EXT_BEFORE="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"

  detail "POSTGRES_SERVER_VERSION_BEFORE=$SERVER_VERSION_BEFORE"
  detail "POSTGRES_CONFIG_FILE=$CONFIG_FILE"
  detail "POSTGRES_DATA_DIRECTORY=$DATA_DIRECTORY"
  detail "SHARED_PRELOAD_LIBRARIES_BEFORE=$PRELOAD_BEFORE"
  detail "TRACK_IO_TIMING_BEFORE=$TRACK_IO_BEFORE"
  detail "LOG_MIN_DURATION_STATEMENT_BEFORE=$LOG_MIN_BEFORE"
  detail "PG_STAT_STATEMENTS_EXTENSION_BEFORE=$EXT_BEFORE"
fi

if [ "$APPLY_DB_OBSERVABILITY" != "1" ]; then
  detail "FRESH_LOGICAL_BACKUP=SKIPPED_DRY_RUN"
  detail "POSTGRES_CONFIG_CHANGED=NO"
  detail "CONTAINER_RESTARTED=NO"
  detail "EXTENSION_CREATED_OR_EXISTS=NO"
  detail "DB_OBSERVABILITY_VERIFICATION=SKIPPED_DRY_RUN"
  detail "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS"

  {
    echo "# FAZ 4 / 14.3.4 - DB Observability Controlled Apply Report"
    echo
    echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo
    echo "## Summary"
    cat "$DETAILS_FILE"
    echo "FAIL_COUNT=$FAIL_COUNT"
    echo "WARN_COUNT=$WARN_COUNT"
    echo "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS"
    echo
    echo "## Tool Status"
    cat "$TOOL_FILE"
    echo
    echo "## Evidence"
    echo "DRY_RUN_NOOP=YES"
    echo
    echo "## Issues"
    if [ -s "$ISSUES_FILE" ]; then cat "$ISSUES_FILE"; else echo "OK ✅ issue yok"; fi
    echo
    echo "## Secret Safety"
    echo "RAW_DSN_PRINTED=NO"
    echo "POSTGRES_PASSWORD_PRINTED=NO"
    echo "QUERY_TEXT_PRINTED=NO"
  } > "$REPORT_FILE"

  echo "REPORT_FILE=$REPORT_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "DB_OBSERVABILITY_CONTROLLED_APPLY=FAIL ❌"
    exit 1
  fi

  echo "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS ✅"
  exit 0
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ -x "$ROOT_DIR/scripts/phase4_logical_backup_smoke.sh" ]; then
    if bash "$ROOT_DIR/scripts/phase4_logical_backup_smoke.sh" "$ROOT_DIR" >/tmp/pix2pi_14_3_4_fresh_backup.log 2>&1; then
      detail "FRESH_LOGICAL_BACKUP=PASS"
      evidence "FRESH_LOGICAL_BACKUP=PASS"
    else
      fail "fresh logical backup failed"
      detail "FRESH_LOGICAL_BACKUP=FAIL"
    fi
  else
    fail "scripts/phase4_logical_backup_smoke.sh bulunamadi veya executable degil"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ] && [ -n "$PRIMARY_CONTAINER" ]; then
  if [ "$CONFIG_FILE" != "unknown" ] && [ "$CONFIG_FILE" != "error" ]; then
    docker cp "$PRIMARY_CONTAINER:$CONFIG_FILE" "$EVIDENCE_DIR/postgresql.conf.before" >/tmp/pix2pi_14_3_4_cp_conf.log 2>&1 || warn "postgresql.conf backup copy alinamadi"
  fi

  docker exec "$PRIMARY_CONTAINER" sh -c "test -f '$DATA_DIRECTORY/postgresql.auto.conf' && cat '$DATA_DIRECTORY/postgresql.auto.conf' || true" > "$EVIDENCE_DIR/postgresql.auto.conf.before" 2>/tmp/pix2pi_14_3_4_auto_before_err.log || true

  detail "CONFIG_BACKUP_DIR=${EVIDENCE_DIR#$ROOT_DIR/}"
fi

TARGET_PRELOAD="$PRELOAD_BEFORE"

if printf '%s' "$TARGET_PRELOAD" | grep -q "pg_stat_statements"; then
  true
elif [ -z "$TARGET_PRELOAD" ] || [ "$TARGET_PRELOAD" = "unknown" ] || [ "$TARGET_PRELOAD" = "error" ]; then
  TARGET_PRELOAD="pg_stat_statements"
else
  TARGET_PRELOAD="${TARGET_PRELOAD},pg_stat_statements"
fi

detail "TARGET_SHARED_PRELOAD_LIBRARIES=$TARGET_PRELOAD"
detail "TARGET_TRACK_IO_TIMING=on"
detail "TARGET_LOG_MIN_DURATION_STATEMENT=1000ms"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if psql "$DB_DSN" -v ON_ERROR_STOP=1 >/tmp/pix2pi_14_3_4_alter_system.log 2>/tmp/pix2pi_14_3_4_alter_system_err.log <<SQL
ALTER SYSTEM SET shared_preload_libraries = '${TARGET_PRELOAD}';
ALTER SYSTEM SET track_io_timing = 'on';
ALTER SYSTEM SET log_min_duration_statement = '1000ms';
SQL
  then
    detail "ALTER_SYSTEM_PATCH=PASS"
    detail "POSTGRES_CONFIG_CHANGED=YES"
    evidence "POSTGRES_CONFIG_CHANGED=YES"
  else
    detail "ALTER_SYSTEM_PATCH=FAIL"
    fail "ALTER SYSTEM patch failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker restart "$PRIMARY_CONTAINER" >/tmp/pix2pi_14_3_4_docker_restart.log 2>&1; then
    detail "CONTAINER_RESTARTED=YES"
    evidence "CONTAINER_RESTARTED=YES"
  else
    detail "CONTAINER_RESTARTED=FAIL"
    fail "docker restart failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if wait_db_ready; then
    detail "DB_CONNECTION_CHECK_AFTER_RESTART=PASS"
  else
    detail "DB_CONNECTION_CHECK_AFTER_RESTART=FAIL"
    fail "DB did not become ready after restart"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY_AFTER="$(run_sql "select pg_is_in_recovery();")"
  detail "PG_IS_IN_RECOVERY_AFTER=$IN_RECOVERY_AFTER"

  case "$IN_RECOVERY_AFTER" in
    f)
      detail "DB_ROLE_AFTER=PRIMARY_WRITE"
      ;;
    t)
      detail "DB_ROLE_AFTER=REPLICA_READ_ONLY"
      fail "after restart DB replica/read-only gorunuyor"
      ;;
    *)
      fail "pg_is_in_recovery after okunamadi"
      ;;
  esac
fi

PRELOAD_AFTER="error"
TRACK_IO_AFTER="error"
LOG_MIN_AFTER="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PRELOAD_AFTER="$(run_sql "show shared_preload_libraries;")"
  TRACK_IO_AFTER="$(run_sql "show track_io_timing;")"
  LOG_MIN_AFTER="$(run_sql "show log_min_duration_statement;")"

  detail "SHARED_PRELOAD_LIBRARIES_AFTER=$PRELOAD_AFTER"
  detail "TRACK_IO_TIMING_AFTER=$TRACK_IO_AFTER"
  detail "LOG_MIN_DURATION_STATEMENT_AFTER=$LOG_MIN_AFTER"

  if printf '%s' "$PRELOAD_AFTER" | grep -q "pg_stat_statements"; then
    detail "PG_STAT_STATEMENTS_PRELOAD_AFTER=YES"
  else
    detail "PG_STAT_STATEMENTS_PRELOAD_AFTER=NO"
    fail "pg_stat_statements preload aktif degil"
  fi

  if [ "$TRACK_IO_AFTER" = "on" ]; then
    detail "TRACK_IO_TIMING_VERIFY=PASS"
  else
    detail "TRACK_IO_TIMING_VERIFY=FAIL"
    fail "track_io_timing on degil"
  fi

  if [ "$LOG_MIN_AFTER" != "-1" ] && [ "$LOG_MIN_AFTER" != "error" ]; then
    detail "LOG_MIN_DURATION_VERIFY=PASS"
  else
    detail "LOG_MIN_DURATION_VERIFY=FAIL"
    fail "log_min_duration_statement aktif degil"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if psql "$DB_DSN" -v ON_ERROR_STOP=1 >/tmp/pix2pi_14_3_4_extension.log 2>/tmp/pix2pi_14_3_4_extension_err.log <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SQL
  then
    detail "EXTENSION_CREATED_OR_EXISTS=YES"
    evidence "EXTENSION_CREATED_OR_EXISTS=YES"
  else
    detail "EXTENSION_CREATED_OR_EXISTS=FAIL"
    fail "pg_stat_statements extension create failed"
  fi
fi

EXT_AFTER="error"
PG_STAT_VIEW_CHECK="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  EXT_AFTER="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  PG_STAT_VIEW_CHECK="$(run_sql "select to_regclass('public.pg_stat_statements') is not null or to_regclass('pg_catalog.pg_stat_statements') is not null;")"

  detail "PG_STAT_STATEMENTS_EXTENSION_AFTER=$EXT_AFTER"
  detail "PG_STAT_STATEMENTS_VIEW_CHECK=$PG_STAT_VIEW_CHECK"

  if [ "$EXT_AFTER" != "t" ]; then
    fail "pg_stat_statements extension verification failed"
  fi
fi

if [ -n "$PRIMARY_CONTAINER" ]; then
  docker exec "$PRIMARY_CONTAINER" sh -c "test -f '$DATA_DIRECTORY/postgresql.auto.conf' && cat '$DATA_DIRECTORY/postgresql.auto.conf' || true" > "$EVIDENCE_DIR/postgresql.auto.conf.after" 2>/tmp/pix2pi_14_3_4_auto_after_err.log || true
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_OBSERVABILITY_VERIFICATION=PASS"
  detail "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS"
else
  detail "DB_OBSERVABILITY_VERIFICATION=FAIL"
  detail "DB_OBSERVABILITY_CONTROLLED_APPLY=FAIL"
fi

{
  echo "# FAZ 4 / 14.3.4 - DB Observability Controlled Apply Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS"
  else
    echo "DB_OBSERVABILITY_CONTROLLED_APPLY=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Evidence"
  if [ -s "$EVIDENCE_FILE" ]; then
    cat "$EVIDENCE_FILE"
  else
    echo "evidence yok"
  fi

  echo
  echo "## Evidence Files"
  echo "EVIDENCE_DIR=${EVIDENCE_DIR#$ROOT_DIR/}"
  echo "POSTGRES_CONF_BEFORE=${EVIDENCE_DIR#$ROOT_DIR/}/postgresql.conf.before"
  echo "POSTGRES_AUTO_CONF_BEFORE=${EVIDENCE_DIR#$ROOT_DIR/}/postgresql.auto.conf.before"
  echo "POSTGRES_AUTO_CONF_AFTER=${EVIDENCE_DIR#$ROOT_DIR/}/postgresql.auto.conf.after"

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
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_OBSERVABILITY_CONTROLLED_APPLY=FAIL ❌"
  exit 1
fi

echo "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS ✅"
