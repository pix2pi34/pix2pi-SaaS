#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_2_6_pitr_enable_gate_report.md"
PLAN_FILE="$REPORT_DIR/14_2_6_pitr_enable_candidate_execution.sh"

READINESS_REPORT="$REPORT_DIR/14_2_1_db_backup_pitr_readiness_report.md"
RESTORE_REPORT="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
DESIGN_REPORT="$REPORT_DIR/14_2_5_pitr_design_wal_archive_report.md"

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

    recovery="$(docker exec -e PGPASSWORD="$pass_val" "$c" psql -U "$user_val" -d "$db_val" -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_2_6_recovery_err.log || echo "error")"

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

APPLY_PITR="${APPLY_PITR:-0}"

detail "ROOT_DIR=$ROOT_DIR"
detail "APPLY_PITR=$APPLY_PITR"
detail "APPLY_PITR_DEFAULT=0"
detail "PITR_ENABLE_EXECUTED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "DB_MUTATION=NO"
detail "WAL_ARCHIVE_DIR_CREATED=NO"
detail "CANDIDATE_PLAN_FILE=docs/phase4/14_2_6_pitr_enable_candidate_execution.sh"

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

READINESS_PASS="$(get_report_value "$READINESS_REPORT" "DB_BACKUP_PITR_READINESS_ASSESSMENT")"
RESTORE_PASS="$(get_report_value "$RESTORE_REPORT" "RESTORE_DRILL_TEST")"
DESIGN_PASS="$(get_report_value "$DESIGN_REPORT" "PITR_DESIGN_WAL_ARCHIVE_PLAN")"

detail "READINESS_ASSESSMENT=$READINESS_PASS"
detail "RESTORE_DRILL_TEST=$RESTORE_PASS"
detail "PITR_DESIGN_WAL_ARCHIVE_PLAN=$DESIGN_PASS"

if [ "$READINESS_PASS" != "PASS" ]; then
  fail "14.2.1 readiness PASS degil"
fi

if [ "$RESTORE_PASS" != "PASS" ]; then
  fail "14.2.4 restore drill PASS degil"
fi

if [ "$DESIGN_PASS" != "PASS" ]; then
  fail "14.2.5 PITR design PASS degil"
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
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_2_6_psql_ok.log 2>/tmp/pix2pi_14_2_6_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_2_6_recovery_err.log || echo "error")"
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

WAL_LEVEL="unknown"
ARCHIVE_MODE="unknown"
ARCHIVE_COMMAND="unknown"
CONFIG_FILE="unknown"
DATA_DIRECTORY="unknown"

if [ "$FAIL_COUNT" -eq 0 ]; then
  WAL_LEVEL="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show wal_level;" 2>/dev/null || echo "error")"
  ARCHIVE_MODE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_mode;" 2>/dev/null || echo "error")"
  ARCHIVE_COMMAND="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_command;" 2>/dev/null || echo "error")"
  CONFIG_FILE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show config_file;" 2>/dev/null || echo "error")"
  DATA_DIRECTORY="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show data_directory;" 2>/dev/null || echo "error")"

  detail "POSTGRES_WAL_LEVEL=$WAL_LEVEL"
  detail "POSTGRES_ARCHIVE_MODE=$ARCHIVE_MODE"
  detail "POSTGRES_ARCHIVE_COMMAND_STATUS=$(if [ "$ARCHIVE_COMMAND" = "(disabled)" ] || [ -z "$ARCHIVE_COMMAND" ]; then echo DISABLED; else echo CONFIGURED; fi)"
  detail "POSTGRES_CONFIG_FILE=$CONFIG_FILE"
  detail "POSTGRES_DATA_DIRECTORY=$DATA_DIRECTORY"
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

HOST_WAL_ARCHIVE_DIR="$ROOT_DIR/backups/db/wal_archive"
CONTAINER_WAL_ARCHIVE_DIR="/var/lib/postgresql/wal_archive"
ARCHIVE_COMMAND_PLAN="test ! -f ${CONTAINER_WAL_ARCHIVE_DIR}/%f && cp %p ${CONTAINER_WAL_ARCHIVE_DIR}/%f"

detail "HOST_WAL_ARCHIVE_DIR=${HOST_WAL_ARCHIVE_DIR#$ROOT_DIR/}"
detail "CONTAINER_WAL_ARCHIVE_DIR=$CONTAINER_WAL_ARCHIVE_DIR"
detail "ARCHIVE_COMMAND_PLAN=$ARCHIVE_COMMAND_PLAN"

if [ -d "$HOST_WAL_ARCHIVE_DIR" ]; then
  detail "HOST_WAL_ARCHIVE_DIR_STATUS=EXISTS"
else
  detail "HOST_WAL_ARCHIVE_DIR_STATUS=NOT_FOUND"
  warn "host WAL archive dizini henuz yok; 14.2.6 apply adiminda olusturulmali"
fi

if [ -n "$PRIMARY_CONTAINER" ]; then
  docker inspect "$PRIMARY_CONTAINER" --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}' 2>/dev/null > "$MOUNT_FILE" || true
fi

if grep -q -- "-> ${CONTAINER_WAL_ARCHIVE_DIR}$" "$MOUNT_FILE" 2>/dev/null; then
  detail "WAL_ARCHIVE_MOUNT_STATUS=EXISTS"
else
  detail "WAL_ARCHIVE_MOUNT_STATUS=NOT_FOUND"
  warn "primary container icinde WAL archive mount henuz yok"
fi

find "$ROOT_DIR" -maxdepth 5 \( -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'compose*.yml' -o -name 'compose*.yaml' \) 2>/dev/null | sort > "$COMPOSE_FILE_LIST" || true
COMPOSE_FILE_COUNT="$(wc -l < "$COMPOSE_FILE_LIST" | tr -d ' ')"
detail "COMPOSE_FILE_COUNT=$COMPOSE_FILE_COUNT"

if [ "$COMPOSE_FILE_COUNT" -eq 0 ]; then
  warn "docker compose dosyasi otomatik bulunamadi; enable apply icin manuel compose path gerekebilir"
  risk "RISK_COMPOSE_FILE_NOT_FOUND=compose path manuel dogrulanmali"
fi

WAL_LEVEL_READY="NO"
ARCHIVE_MODE_READY="NO"
ARCHIVE_COMMAND_READY="NO"
PITR_CURRENT_READY="NO"

if [ "$WAL_LEVEL" = "replica" ] || [ "$WAL_LEVEL" = "logical" ]; then
  WAL_LEVEL_READY="YES"
fi

if [ "$ARCHIVE_MODE" = "on" ] || [ "$ARCHIVE_MODE" = "always" ]; then
  ARCHIVE_MODE_READY="YES"
fi

if [ "$ARCHIVE_COMMAND" != "(disabled)" ] && [ -n "$ARCHIVE_COMMAND" ] && [ "$ARCHIVE_COMMAND" != "error" ]; then
  ARCHIVE_COMMAND_READY="YES"
fi

if [ "$WAL_LEVEL_READY" = "YES" ] && [ "$ARCHIVE_MODE_READY" = "YES" ] && [ "$ARCHIVE_COMMAND_READY" = "YES" ]; then
  PITR_CURRENT_READY="YES"
fi

detail "WAL_LEVEL_READY=$WAL_LEVEL_READY"
detail "ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY"
detail "ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"
detail "PITR_CURRENT_READY=$PITR_CURRENT_READY"

if [ "$ARCHIVE_MODE_READY" != "YES" ]; then
  risk "RISK_ARCHIVE_MODE_OFF=archive_mode on yapilmadan PITR aktif olmaz"
fi

if [ "$ARCHIVE_COMMAND_READY" != "YES" ]; then
  risk "RISK_ARCHIVE_COMMAND_DISABLED=archive_command tanimlanmadan WAL archive olusmaz"
fi

if [ "$WAL_LEVEL_READY" != "YES" ]; then
  fail "wal_level PITR icin hazir degil"
fi

PITR_ENABLE_DECISION="PLAN_READY_APPLY_NOT_EXECUTED"

if [ "$FAIL_COUNT" -gt 0 ]; then
  PITR_ENABLE_DECISION="BLOCKED_REVIEW_REQUIRED"
elif [ "$APPLY_PITR" != "0" ]; then
  PITR_ENABLE_DECISION="BLOCKED_BY_14_2_6_GATE_USE_NEXT_APPLY_STEP"
  warn "APPLY_PITR sifir degil; bu adim uygulama yapmaz, sadece gate kurar"
else
  PITR_ENABLE_DECISION="PLAN_READY_APPLY_NOT_EXECUTED"
fi

detail "PITR_ENABLE_DECISION=$PITR_ENABLE_DECISION"

cat <<PLAN > "$PLAN_FILE"
#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.2.6 PITR enable candidate execution file."
echo "14.2.6 gate does not execute PITR enable."
echo "Actual config change must be done in a separate approved apply step."
exit 99

# FAZ 4 / 14.2.6 - PITR Enable Candidate Execution
# Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')
# This file is intentionally blocked by exit 99 above.

PRIMARY_CONTAINER="$PRIMARY_CONTAINER"
PRIMARY_IMAGE="$PRIMARY_IMAGE"
PRIMARY_DB="$PRIMARY_DB"
PRIMARY_PORT="$PRIMARY_PORT"

HOST_WAL_ARCHIVE_DIR="$HOST_WAL_ARCHIVE_DIR"
CONTAINER_WAL_ARCHIVE_DIR="$CONTAINER_WAL_ARCHIVE_DIR"
ARCHIVE_COMMAND_PLAN="$ARCHIVE_COMMAND_PLAN"

# Candidate high-level apply sequence:
# 1. Take fresh logical backup and restic backup.
# 2. Backup Docker compose/config files.
# 3. mkdir -p "\$HOST_WAL_ARCHIVE_DIR"
# 4. Add mount:
#    \$HOST_WAL_ARCHIVE_DIR:\$CONTAINER_WAL_ARCHIVE_DIR
# 5. Configure PostgreSQL:
#    wal_level=replica
#    archive_mode=on
#    archive_command='test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f'
# 6. Restart primary PostgreSQL container in maintenance window.
# 7. Verify:
#    show archive_mode;
#    show archive_command;
#    select pg_switch_wal();
#    check WAL file appears in \$HOST_WAL_ARCHIVE_DIR
# 8. Run backup job including WAL archive directory.
# 9. Record evidence.
#
# Rollback:
# 1. Restore previous compose/config.
# 2. Restart PostgreSQL.
# 3. Verify DB_CONNECTION_CHECK=PASS and DB_ROLE=PRIMARY_WRITE.
PLAN

chmod 600 "$PLAN_FILE"

detail "PITR_ENABLE_CANDIDATE_EXECUTION_CREATED=YES"
detail "PITR_ENABLE_CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES"

{
  echo "# FAZ 4 / 14.2.6 - PITR Enable Gate Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "PITR_ENABLE_GATE=PASS"
  else
    echo "PITR_ENABLE_GATE=FAIL"
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
    echo "OK ✅ major risk yok"
  fi

  echo
  echo "## Planned Execution"
  echo "PITR_ENABLE_EXECUTED=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "DB_MUTATION=NO"
  echo "WAL_ARCHIVE_DIR_CREATED=NO"

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
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "PLAN_FILE=$PLAN_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "PITR_ENABLE_DECISION=$PITR_ENABLE_DECISION"
echo "PITR_CURRENT_READY=$PITR_CURRENT_READY"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "PITR_ENABLE_GATE=FAIL ❌"
  exit 1
fi

echo "PITR_ENABLE_GATE=PASS ✅"
