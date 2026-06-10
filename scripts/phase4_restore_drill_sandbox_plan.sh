#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_2_3_restore_drill_sandbox_plan_report.md"
PLAN_FILE="$REPORT_DIR/14_2_3_restore_drill_execution_plan.sh"

LOGICAL_REPORT="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"

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

  grep -E "^${key}=" "$file" | head -n 1 | cut -d= -f2- || true
}

to_abs_path() {
  local p="$1"

  if [[ "$p" = /* ]]; then
    echo "$p"
  else
    echo "$ROOT_DIR/$p"
  fi
}

is_port_free() {
  local port="$1"

  if command -v ss >/dev/null 2>&1; then
    if ss -ltn | awk '{print $4}' | grep -q ":${port}$"; then
      return 1
    fi
  elif command -v lsof >/dev/null 2>&1; then
    if lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      return 1
    fi
  fi

  return 0
}

find_primary_container_image() {
  local containers=""
  local c=""
  local user_val=""
  local pass_val=""
  local db_val=""
  local recovery=""
  local image_val=""

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

    recovery="$(docker exec -e PGPASSWORD="$pass_val" "$c" psql -U "$user_val" -d "$db_val" -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_2_3_container_recovery_err.log || echo "error")"

    if [ "$recovery" = "f" ]; then
      image_val="$(docker inspect "$c" --format '{{.Config.Image}}' 2>/dev/null || true)"

      PRIMARY_CONTAINER="$c"
      PRIMARY_IMAGE="$image_val"
      PRIMARY_DB="$db_val"
      return 0
    fi
  done

  return 1
}

mkdir -p "$REPORT_DIR"

detail "ROOT_DIR=$ROOT_DIR"
detail "LOGICAL_REPORT=docs/phase4/14_2_2_logical_backup_smoke_report.md"
detail "EXECUTION_PLAN_FILE=docs/phase4/14_2_3_restore_drill_execution_plan.sh"
detail "DB_MUTATION=NO"
detail "RESTORE_EXECUTED=NO"
detail "SANDBOX_CONTAINER_CREATE_EXECUTED=NO"
detail "PITR_CONFIG_CHANGE=NO"

DOCKER_FOUND=0
SHA_FOUND=0

if tool_status "docker"; then DOCKER_FOUND=1; fi
if tool_status "sha256sum"; then SHA_FOUND=1; fi

if [ "$DOCKER_FOUND" -ne 1 ]; then
  fail "docker bulunamadi"
fi

if [ "$SHA_FOUND" -ne 1 ]; then
  warn "sha256sum bulunamadi; checksum verify skip edilecek"
fi

if [ ! -f "$LOGICAL_REPORT" ]; then
  fail "14.2.2 logical backup smoke report bulunamadi"
fi

DUMP_REL="$(get_report_value "$LOGICAL_REPORT" "DUMP_FILE")"
SHA_REL="$(get_report_value "$LOGICAL_REPORT" "SHA_FILE")"
RESTORE_LIST_REL="$(get_report_value "$LOGICAL_REPORT" "RESTORE_LIST_FILE")"

if [ -z "$DUMP_REL" ]; then
  DUMP_REL="$(find "$ROOT_DIR/backups/db/logical" -path '*phase4_14_2_2_*' -name 'pix2pi_schema_only.dump' -type f 2>/dev/null | sort | tail -n 1)"
fi

DUMP_FILE="$(to_abs_path "$DUMP_REL")"
SHA_FILE="$(to_abs_path "$SHA_REL")"
RESTORE_LIST_FILE="$(to_abs_path "$RESTORE_LIST_REL")"

detail "SOURCE_DUMP_FILE=${DUMP_FILE#$ROOT_DIR/}"
detail "SOURCE_SHA_FILE=${SHA_FILE#$ROOT_DIR/}"
detail "SOURCE_RESTORE_LIST_FILE=${RESTORE_LIST_FILE#$ROOT_DIR/}"

if [ ! -s "$DUMP_FILE" ]; then
  fail "source dump file yok veya bos"
fi

if [ ! -s "$RESTORE_LIST_FILE" ]; then
  fail "pg_restore list file yok veya bos"
fi

DUMP_SIZE_BYTES=0
RESTORE_LIST_LINE_COUNT=0

if [ -f "$DUMP_FILE" ]; then
  DUMP_SIZE_BYTES="$(wc -c < "$DUMP_FILE" | tr -d ' ')"
fi

if [ -f "$RESTORE_LIST_FILE" ]; then
  RESTORE_LIST_LINE_COUNT="$(wc -l < "$RESTORE_LIST_FILE" | tr -d ' ')"
fi

detail "DUMP_SIZE_BYTES=$DUMP_SIZE_BYTES"
detail "RESTORE_LIST_LINE_COUNT=$RESTORE_LIST_LINE_COUNT"

CHECKSUM_VERIFY="SKIPPED"
EXPECTED_SHA256=""
ACTUAL_SHA256=""

if [ "$SHA_FOUND" -eq 1 ] && [ -s "$SHA_FILE" ] && [ -s "$DUMP_FILE" ]; then
  EXPECTED_SHA256="$(awk '{print $1}' "$SHA_FILE" | head -n 1)"
  ACTUAL_SHA256="$(sha256sum "$DUMP_FILE" | awk '{print $1}')"

  detail "DUMP_EXPECTED_SHA256=$EXPECTED_SHA256"
  detail "DUMP_ACTUAL_SHA256=$ACTUAL_SHA256"

  if [ -n "$EXPECTED_SHA256" ] && [ "$EXPECTED_SHA256" = "$ACTUAL_SHA256" ]; then
    CHECKSUM_VERIFY="PASS"
  else
    CHECKSUM_VERIFY="FAIL"
    fail "dump checksum verify failed"
  fi
elif [ ! -s "$SHA_FILE" ]; then
  warn "sha256 dosyasi bulunamadi; checksum verify skip edildi"
elif [ ! -s "$DUMP_FILE" ]; then
  fail "dump file yok veya bos; checksum verify yapilamadi"
fi

detail "DUMP_CHECKSUM_VERIFY=$CHECKSUM_VERIFY"

PRIMARY_CONTAINER=""
PRIMARY_IMAGE=""
PRIMARY_DB=""

if [ "$FAIL_COUNT" -eq 0 ]; then
  if find_primary_container_image; then
    detail "PRIMARY_CONTAINER=$PRIMARY_CONTAINER"
    detail "PRIMARY_IMAGE=$PRIMARY_IMAGE"
    detail "PRIMARY_DB=$PRIMARY_DB"
  else
    fail "primary postgres container/image tespit edilemedi"
  fi
fi

SANDBOX_CONTAINER="pix2pi_pg_restore_drill_14_2_4"
SANDBOX_VOLUME="pix2pi_pg_restore_drill_14_2_4_data"
SANDBOX_DB="pix2pi_restore_drill"
SANDBOX_USER="pix2pi_restore"
SANDBOX_DUMP_PATH="/tmp/pix2pi_schema_only.dump"
SANDBOX_PORT=""

for p in 55433 55434 55435 55436 55437 55438 55439; do
  if is_port_free "$p"; then
    SANDBOX_PORT="$p"
    break
  fi
done

if [ -z "$SANDBOX_PORT" ]; then
  fail "uygun sandbox port bulunamadi"
fi

detail "SANDBOX_CONTAINER=$SANDBOX_CONTAINER"
detail "SANDBOX_VOLUME=$SANDBOX_VOLUME"
detail "SANDBOX_DB=$SANDBOX_DB"
detail "SANDBOX_USER=$SANDBOX_USER"
detail "SANDBOX_PORT=$SANDBOX_PORT"
detail "SANDBOX_DUMP_PATH=$SANDBOX_DUMP_PATH"

if [ "$DOCKER_FOUND" -eq 1 ]; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$SANDBOX_CONTAINER"; then
    warn "sandbox container zaten var; 14.2.4 oncesi cleanup gerekir"
    detail "SANDBOX_CONTAINER_ALREADY_EXISTS=YES"
  else
    detail "SANDBOX_CONTAINER_ALREADY_EXISTS=NO"
  fi

  if docker volume ls --format '{{.Name}}' | grep -qx "$SANDBOX_VOLUME"; then
    warn "sandbox volume zaten var; 14.2.4 oncesi cleanup gerekir"
    detail "SANDBOX_VOLUME_ALREADY_EXISTS=YES"
  else
    detail "SANDBOX_VOLUME_ALREADY_EXISTS=NO"
  fi
fi

cat <<PLAN > "$PLAN_FILE"
#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.2.3 restore drill execution plan."
echo "14.2.3 does not execute restore."
exit 99

# FAZ 4 / 14.2.3 - Restore Drill Execution Plan
# Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')
# This file is intentionally blocked by exit 99 above.
# Actual execution belongs to FAZ 4 / 14.2.4.

export RESTORE_DRILL_PASSWORD="\${RESTORE_DRILL_PASSWORD:?set RESTORE_DRILL_PASSWORD before restore drill}"

SANDBOX_CONTAINER="$SANDBOX_CONTAINER"
SANDBOX_VOLUME="$SANDBOX_VOLUME"
SANDBOX_IMAGE="$PRIMARY_IMAGE"
SANDBOX_DB="$SANDBOX_DB"
SANDBOX_USER="$SANDBOX_USER"
SANDBOX_PORT="$SANDBOX_PORT"
SOURCE_DUMP_FILE="$DUMP_FILE"
SANDBOX_DUMP_PATH="$SANDBOX_DUMP_PATH"

docker rm -f "\$SANDBOX_CONTAINER" 2>/dev/null || true
docker volume rm "\$SANDBOX_VOLUME" 2>/dev/null || true
docker volume create "\$SANDBOX_VOLUME"

docker run -d \\
  --name "\$SANDBOX_CONTAINER" \\
  -e POSTGRES_USER="\$SANDBOX_USER" \\
  -e POSTGRES_PASSWORD="\$RESTORE_DRILL_PASSWORD" \\
  -e POSTGRES_DB="\$SANDBOX_DB" \\
  -p "127.0.0.1:\$SANDBOX_PORT:5432" \\
  -v "\$SANDBOX_VOLUME:/var/lib/postgresql/data" \\
  "\$SANDBOX_IMAGE"

for i in \$(seq 1 30); do
  if docker exec -e PGPASSWORD="\$RESTORE_DRILL_PASSWORD" "\$SANDBOX_CONTAINER" \\
    psql -U "\$SANDBOX_USER" -d "\$SANDBOX_DB" -Atqc "select 1;" >/dev/null 2>&1; then
    echo "SANDBOX_DB_READY=YES"
    break
  fi
  sleep 1
done

docker cp "\$SOURCE_DUMP_FILE" "\$SANDBOX_CONTAINER:\$SANDBOX_DUMP_PATH"

docker exec -e PGPASSWORD="\$RESTORE_DRILL_PASSWORD" "\$SANDBOX_CONTAINER" \\
  pg_restore \\
    -U "\$SANDBOX_USER" \\
    -d "\$SANDBOX_DB" \\
    --no-owner \\
    --no-privileges \\
    "\$SANDBOX_DUMP_PATH"

docker exec -e PGPASSWORD="\$RESTORE_DRILL_PASSWORD" "\$SANDBOX_CONTAINER" \\
  psql -U "\$SANDBOX_USER" -d "\$SANDBOX_DB" -Atqc \\
  "select count(*) from information_schema.tables where table_schema not in ('pg_catalog','information_schema');"

# Cleanup command after evidence:
# docker rm -f "\$SANDBOX_CONTAINER"
# docker volume rm "\$SANDBOX_VOLUME"
PLAN

chmod 600 "$PLAN_FILE"

detail "EXECUTION_PLAN_CREATED=YES"
detail "EXECUTION_PLAN_BLOCKED_BY_DEFAULT=YES"

{
  echo "# FAZ 4 / 14.2.3 - Restore Drill Sandbox Plan Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "RESTORE_DRILL_SANDBOX_PLAN=PASS"
  else
    echo "RESTORE_DRILL_SANDBOX_PLAN=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Planned Execution"
  echo "RESTORE_EXECUTED=NO"
  echo "SANDBOX_CONTAINER_CREATE_EXECUTED=NO"
  echo "SANDBOX_VOLUME_CREATE_EXECUTED=NO"
  echo "DB_MUTATION=NO"
  echo "PITR_CONFIG_CHANGE=NO"

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
  echo "RESTORE_DRILL_PASSWORD_PRINTED=NO"
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "PLAN_FILE=$PLAN_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SANDBOX_CONTAINER=$SANDBOX_CONTAINER"
echo "SANDBOX_PORT=$SANDBOX_PORT"
echo "DUMP_CHECKSUM_VERIFY=$CHECKSUM_VERIFY"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESTORE_DRILL_SANDBOX_PLAN=FAIL ❌"
  exit 1
fi

echo "RESTORE_DRILL_SANDBOX_PLAN=PASS ✅"
