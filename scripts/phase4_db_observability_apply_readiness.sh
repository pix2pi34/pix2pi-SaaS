#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_3_3_db_observability_apply_readiness_report.md"
PATCH_PLAN_FILE="$REPORT_DIR/14_3_3_db_observability_config_patch_candidate.sh"
ROLLBACK_PLAN_FILE="$REPORT_DIR/14_3_3_db_observability_rollback_plan.sh"

DISCOVERY_REPORT="$REPORT_DIR/14_3_1_db_observability_performance_report.md"
GATE_REPORT="$REPORT_DIR/14_3_2_db_observability_enable_gate_report.md"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
COMPOSE_FILE_LIST="$(mktemp)"
MOUNT_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$COMPOSE_FILE_LIST" "$MOUNT_FILE"' EXIT

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

risk() {
  echo "$1" >> "$RISK_FILE"
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
  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_3_3_sql_err.log || echo "error"
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

    recovery="$(docker exec -e PGPASSWORD="$pass_val" "$c" psql -U "$user_val" -d "$db_val" -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_3_3_recovery_err.log || echo "error")"

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

mkdir -p "$REPORT_DIR"

APPLY_DB_OBSERVABILITY="${APPLY_DB_OBSERVABILITY:-0}"

detail "ROOT_DIR=$ROOT_DIR"
detail "APPLY_DB_OBSERVABILITY=$APPLY_DB_OBSERVABILITY"
detail "APPLY_DB_OBSERVABILITY_DEFAULT=0"
detail "DB_OBSERVABILITY_APPLY_EXECUTED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "DB_MUTATION=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "PATCH_PLAN_FILE=docs/phase4/14_3_3_db_observability_config_patch_candidate.sh"
detail "ROLLBACK_PLAN_FILE=docs/phase4/14_3_3_db_observability_rollback_plan.sh"

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

DISCOVERY_PASS="$(get_report_value "$DISCOVERY_REPORT" "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY")"
GATE_PASS="$(get_report_value "$GATE_REPORT" "DB_OBSERVABILITY_ENABLE_GATE")"

detail "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=$DISCOVERY_PASS"
detail "DB_OBSERVABILITY_ENABLE_GATE=$GATE_PASS"

if [ "$DISCOVERY_PASS" != "PASS" ]; then
  fail "14.3.1 DB observability discovery PASS degil"
fi

if [ "$GATE_PASS" != "PASS" ]; then
  fail "14.3.2 DB observability enable gate PASS degil"
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

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_3_3_psql_ok.log 2>/tmp/pix2pi_14_3_3_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"
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

SERVER_VERSION="unknown"
CONFIG_FILE="unknown"
DATA_DIRECTORY="unknown"
SHARED_PRELOAD_LIBRARIES="unknown"
PG_STAT_EXTENSION="unknown"
PG_STAT_AVAILABLE="unknown"
TRACK_IO_TIMING="unknown"
LOG_MIN_DURATION_STATEMENT="unknown"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SERVER_VERSION="$(run_sql "show server_version;")"
  CONFIG_FILE="$(run_sql "show config_file;")"
  DATA_DIRECTORY="$(run_sql "show data_directory;")"
  SHARED_PRELOAD_LIBRARIES="$(run_sql "show shared_preload_libraries;")"
  PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  PG_STAT_AVAILABLE="$(run_sql "select exists(select 1 from pg_available_extensions where name='pg_stat_statements');")"
  TRACK_IO_TIMING="$(run_sql "show track_io_timing;")"
  LOG_MIN_DURATION_STATEMENT="$(run_sql "show log_min_duration_statement;")"
fi

PG_STAT_PRELOAD="NO"
if printf '%s' "$SHARED_PRELOAD_LIBRARIES" | grep -q "pg_stat_statements"; then
  PG_STAT_PRELOAD="YES"
fi

detail "POSTGRES_SERVER_VERSION=$SERVER_VERSION"
detail "POSTGRES_CONFIG_FILE=$CONFIG_FILE"
detail "POSTGRES_DATA_DIRECTORY=$DATA_DIRECTORY"
detail "SHARED_PRELOAD_LIBRARIES=$SHARED_PRELOAD_LIBRARIES"
detail "PG_STAT_STATEMENTS_AVAILABLE=$PG_STAT_AVAILABLE"
detail "PG_STAT_STATEMENTS_EXTENSION=$PG_STAT_EXTENSION"
detail "PG_STAT_STATEMENTS_PRELOAD=$PG_STAT_PRELOAD"
detail "TRACK_IO_TIMING=$TRACK_IO_TIMING"
detail "LOG_MIN_DURATION_STATEMENT=$LOG_MIN_DURATION_STATEMENT"

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

CONFIG_FILE_READABLE="UNKNOWN"

if [ -n "$PRIMARY_CONTAINER" ] && [ "$CONFIG_FILE" != "unknown" ] && [ "$CONFIG_FILE" != "error" ]; then
  if docker exec "$PRIMARY_CONTAINER" sh -c "test -r '$CONFIG_FILE'" >/tmp/pix2pi_14_3_3_config_readable.log 2>&1; then
    CONFIG_FILE_READABLE="YES"
  else
    CONFIG_FILE_READABLE="NO"
    warn "postgres config file container icinden okunamadi"
  fi
fi

detail "POSTGRES_CONFIG_FILE_READABLE=$CONFIG_FILE_READABLE"

if [ -n "$PRIMARY_CONTAINER" ]; then
  docker inspect "$PRIMARY_CONTAINER" --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}' 2>/dev/null > "$MOUNT_FILE" || true
fi

find "$ROOT_DIR" -maxdepth 5 \( -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'compose*.yml' -o -name 'compose*.yaml' \) 2>/dev/null | sort > "$COMPOSE_FILE_LIST" || true
COMPOSE_FILE_COUNT="$(wc -l < "$COMPOSE_FILE_LIST" | tr -d ' ')"
detail "COMPOSE_FILE_COUNT=$COMPOSE_FILE_COUNT"

if [ "$COMPOSE_FILE_COUNT" -eq 0 ]; then
  warn "docker compose dosyasi otomatik bulunamadi"
  risk "RISK_COMPOSE_FILE_NOT_FOUND=compose/config path manuel dogrulanmali"
fi

RESTART_REQUIRED="NO"
CONFIG_PATCH_REQUIRED="NO"
EXTENSION_CREATE_REQUIRED="NO"
TRACK_IO_TIMING_CHANGE_REQUIRED="NO"
SLOW_QUERY_LOG_CHANGE_REQUIRED="NO"

if [ "$PG_STAT_PRELOAD" != "YES" ]; then
  RESTART_REQUIRED="YES"
  CONFIG_PATCH_REQUIRED="YES"
  risk "RISK_RESTART_REQUIRED=shared_preload_libraries degisimi icin restart gerekir"
fi

if [ "$PG_STAT_EXTENSION" != "t" ]; then
  EXTENSION_CREATE_REQUIRED="YES"
  risk "RISK_EXTENSION_CREATE_REQUIRED=pg_stat_statements extension create gerekir"
fi

if [ "$PG_STAT_AVAILABLE" != "t" ]; then
  fail "pg_stat_statements available extension olarak gorunmuyor"
fi

if [ "$TRACK_IO_TIMING" != "on" ]; then
  TRACK_IO_TIMING_CHANGE_REQUIRED="YES"
  CONFIG_PATCH_REQUIRED="YES"
  risk "RISK_TRACK_IO_TIMING_CHANGE_REQUIRED=track_io_timing on yapilmali"
fi

if [ "$LOG_MIN_DURATION_STATEMENT" = "-1" ]; then
  SLOW_QUERY_LOG_CHANGE_REQUIRED="YES"
  CONFIG_PATCH_REQUIRED="YES"
  risk "RISK_SLOW_QUERY_LOG_CHANGE_REQUIRED=log_min_duration_statement disabled"
fi

detail "CONFIG_PATCH_METHOD=ALTER_SYSTEM_CANDIDATE"
detail "CONFIG_PATCH_REQUIRED=$CONFIG_PATCH_REQUIRED"
detail "RESTART_REQUIRED=$RESTART_REQUIRED"
detail "EXTENSION_CREATE_REQUIRED=$EXTENSION_CREATE_REQUIRED"
detail "TRACK_IO_TIMING_CHANGE_REQUIRED=$TRACK_IO_TIMING_CHANGE_REQUIRED"
detail "SLOW_QUERY_LOG_CHANGE_REQUIRED=$SLOW_QUERY_LOG_CHANGE_REQUIRED"

if [ "$APPLY_DB_OBSERVABILITY" != "0" ]; then
  warn "APPLY_DB_OBSERVABILITY sifir degil; 14.3.3 uygulama yapmaz"
fi

APPLY_READINESS_DECISION="PLAN_READY_APPLY_NOT_EXECUTED"

if [ "$FAIL_COUNT" -gt 0 ]; then
  APPLY_READINESS_DECISION="BLOCKED_REVIEW_REQUIRED"
fi

detail "DB_OBSERVABILITY_APPLY_READINESS_DECISION=$APPLY_READINESS_DECISION"

cat <<PLAN > "$PATCH_PLAN_FILE"
#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.3.3 DB observability config patch candidate."
echo "14.3.3 does not change PostgreSQL config."
echo "Actual controlled apply belongs to FAZ 4 / 14.3.4."
exit 99

# FAZ 4 / 14.3.3 - DB Observability Config Patch Candidate
# Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')
# This file is intentionally blocked by exit 99 above.

export DB_DSN="\${DB_DSN:?set DB_DSN before apply}"
PRIMARY_CONTAINER="$PRIMARY_CONTAINER"
PRIMARY_IMAGE="$PRIMARY_IMAGE"
PRIMARY_DB="$PRIMARY_DB"
PRIMARY_PORT="$PRIMARY_PORT"

# Fresh safety backup before apply:
# bash scripts/phase4_logical_backup_smoke.sh .
# restic backup command should be run according to current backup policy.

# Candidate config patch method:
# ALTER SYSTEM writes to postgresql.auto.conf under PGDATA.
# A restart is required for shared_preload_libraries.
psql "\$DB_DSN" -v ON_ERROR_STOP=1 <<'SQL'
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_io_timing = 'on';
ALTER SYSTEM SET log_min_duration_statement = '1000';
SQL

# Controlled maintenance restart:
# docker restart "\$PRIMARY_CONTAINER"

# After restart verification:
# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show shared_preload_libraries;"
# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show track_io_timing;"
# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show log_min_duration_statement;"

# Extension create after preload is active:
psql "\$DB_DSN" -v ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SQL

# Final verification:
# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from pg_extension where extname='pg_stat_statements');"
PLAN

chmod 600 "$PATCH_PLAN_FILE"

cat <<ROLLBACK > "$ROLLBACK_PLAN_FILE"
#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.3.3 DB observability rollback plan."
echo "14.3.3 does not execute rollback."
echo "Rollback execution belongs to a separate approved step if needed."
exit 99

# FAZ 4 / 14.3.3 - DB Observability Rollback Plan
# Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')
# This file is intentionally blocked by exit 99 above.

export DB_DSN="\${DB_DSN:?set DB_DSN before rollback}"
PRIMARY_CONTAINER="$PRIMARY_CONTAINER"

# Rollback config values written by ALTER SYSTEM:
psql "\$DB_DSN" -v ON_ERROR_STOP=1 <<'SQL'
ALTER SYSTEM RESET shared_preload_libraries;
ALTER SYSTEM RESET track_io_timing;
ALTER SYSTEM RESET log_min_duration_statement;
SQL

# Controlled restart:
# docker restart "\$PRIMARY_CONTAINER"

# Optional extension rollback is NOT recommended by default because it can drop statistics object references.
# If absolutely needed and approved:
# DROP EXTENSION IF EXISTS pg_stat_statements;

# Verify DB health:
# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;"
# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();"
ROLLBACK

chmod 600 "$ROLLBACK_PLAN_FILE"

detail "CONFIG_PATCH_PLAN_CREATED=YES"
detail "CONFIG_PATCH_PLAN_BLOCKED_BY_DEFAULT=YES"
detail "ROLLBACK_PLAN_CREATED=YES"
detail "ROLLBACK_PLAN_BLOCKED_BY_DEFAULT=YES"

{
  echo "# FAZ 4 / 14.3.3 - DB Observability Apply Readiness Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_OBSERVABILITY_APPLY_READINESS=PASS"
  else
    echo "DB_OBSERVABILITY_APPLY_READINESS=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Primary Container Mounts"
  if [ -s "$MOUNT_FILE" ]; then
    cat "$MOUNT_FILE"
  else
    echo "mount bilgisi yok"
  fi

  echo
  echo "## Compose File Candidates"
  if [ -s "$COMPOSE_FILE_LIST" ]; then
    cat "$COMPOSE_FILE_LIST"
  else
    echo "compose candidate yok"
  fi

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ major apply readiness risk yok"
  fi

  echo
  echo "## Planned Execution"
  echo "DB_OBSERVABILITY_APPLY_EXECUTED=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "EXTENSION_CREATED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "DB_MUTATION=NO"

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
echo "PATCH_PLAN_FILE=$PATCH_PLAN_FILE"
echo "ROLLBACK_PLAN_FILE=$ROLLBACK_PLAN_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DB_OBSERVABILITY_APPLY_READINESS_DECISION=$APPLY_READINESS_DECISION"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_OBSERVABILITY_APPLY_READINESS=FAIL ❌"
  exit 1
fi

echo "DB_OBSERVABILITY_APPLY_READINESS=PASS ✅"
