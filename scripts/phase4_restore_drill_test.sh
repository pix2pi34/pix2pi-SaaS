#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
REPORT_DIR="$ROOT_DIR/docs/phase4"
PLAN_REPORT="$REPORT_DIR/14_2_3_restore_drill_sandbox_plan_report.md"
REPORT_FILE="$REPORT_DIR/14_2_4_restore_drill_test_report.md"

STAMP="$(date +%Y%m%d_%H%M%S)"
EVIDENCE_DIR="$ROOT_DIR/backups/db/restore_drills/phase4_14_2_4_${STAMP}"

mkdir -p "$REPORT_DIR" "$EVIDENCE_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
EVIDENCE_FILE="$(mktemp)"
RESTORE_STDOUT="$EVIDENCE_DIR/pg_restore_stdout.txt"
RESTORE_STDERR_RAW="$EVIDENCE_DIR/pg_restore_stderr_raw.txt"
RESTORE_STDERR_SANITIZED="$EVIDENCE_DIR/pg_restore_stderr_sanitized.txt"
SANDBOX_EVIDENCE="$EVIDENCE_DIR/sandbox_sql_evidence.txt"

SANDBOX_CONTAINER=""
SANDBOX_VOLUME=""
SANDBOX_CREATED=0
VOLUME_CREATED=0

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

get_report_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    echo ""
    return 0
  fi

  grep -E "^${key}=" "$file" | tail -n 1 | cut -d= -f2- || true
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

pick_port() {
  local preferred="$1"

  if [ -n "$preferred" ] && is_port_free "$preferred"; then
    echo "$preferred"
    return 0
  fi

  for p in 55433 55434 55435 55436 55437 55438 55439; do
    if is_port_free "$p"; then
      echo "$p"
      return 0
    fi
  done

  echo ""
}

safe_positive_int() {
  local v="$1"

  case "$v" in
    ''|*[!0-9]*)
      return 1
      ;;
    *)
      [ "$v" -gt 0 ]
      ;;
  esac
}

cleanup_sandbox() {
  local cleanup_fail=0

  if [ -n "$SANDBOX_CONTAINER" ]; then
    if docker ps -a --format '{{.Names}}' | grep -qx "$SANDBOX_CONTAINER"; then
      if docker rm -f "$SANDBOX_CONTAINER" >/tmp/pix2pi_14_2_4_cleanup_container.log 2>&1; then
        detail "SANDBOX_CONTAINER_CLEANUP=PASS"
      else
        detail "SANDBOX_CONTAINER_CLEANUP=FAIL"
        cleanup_fail=1
      fi
    else
      detail "SANDBOX_CONTAINER_CLEANUP=NO_CONTAINER"
    fi
  fi

  if [ -n "$SANDBOX_VOLUME" ]; then
    if docker volume ls --format '{{.Name}}' | grep -qx "$SANDBOX_VOLUME"; then
      if docker volume rm "$SANDBOX_VOLUME" >/tmp/pix2pi_14_2_4_cleanup_volume.log 2>&1; then
        detail "SANDBOX_VOLUME_CLEANUP=PASS"
      else
        detail "SANDBOX_VOLUME_CLEANUP=FAIL"
        cleanup_fail=1
      fi
    else
      detail "SANDBOX_VOLUME_CLEANUP=NO_VOLUME"
    fi
  fi

  if [ "$cleanup_fail" -eq 0 ]; then
    detail "SANDBOX_CLEANUP_STATUS=PASS"
  else
    detail "SANDBOX_CLEANUP_STATUS=FAIL"
    fail "sandbox cleanup failed"
  fi
}

RESTORE_DRILL_PASSWORD_VALUE="$(openssl rand -hex 24 2>/dev/null || date +%s%N | sha256sum | awk '{print $1}')"

detail "ROOT_DIR=$ROOT_DIR"
detail "PLAN_REPORT=docs/phase4/14_2_3_restore_drill_sandbox_plan_report.md"
detail "EVIDENCE_DIR=${EVIDENCE_DIR#$ROOT_DIR/}"
detail "LIVE_DB_MUTATION=NO"
detail "DB_MUTATION_SCOPE=SANDBOX_ONLY"
detail "PITR_CONFIG_CHANGE=NO"
detail "RESTORE_TARGET=SANDBOX_ONLY"
detail "RESTORE_DRILL_PASSWORD_PRINTED=NO"

DOCKER_FOUND=0
SHA_FOUND=0

if tool_status "docker"; then DOCKER_FOUND=1; fi
if tool_status "sha256sum"; then SHA_FOUND=1; fi

if [ "$DOCKER_FOUND" -ne 1 ]; then
  fail "docker bulunamadi"
fi

if [ "$SHA_FOUND" -ne 1 ]; then
  fail "sha256sum bulunamadi"
fi

if [ ! -f "$PLAN_REPORT" ]; then
  fail "14.2.3 restore drill sandbox plan report bulunamadi"
fi

SOURCE_DUMP_REL="$(get_report_value "$PLAN_REPORT" "SOURCE_DUMP_FILE")"
EXPECTED_SHA="$(get_report_value "$PLAN_REPORT" "DUMP_EXPECTED_SHA256")"
PLAN_IMAGE="$(get_report_value "$PLAN_REPORT" "PRIMARY_IMAGE")"
PLAN_CONTAINER="$(get_report_value "$PLAN_REPORT" "SANDBOX_CONTAINER")"
PLAN_VOLUME="$(get_report_value "$PLAN_REPORT" "SANDBOX_VOLUME")"
PLAN_PORT="$(get_report_value "$PLAN_REPORT" "SANDBOX_PORT")"

[ -n "$PLAN_IMAGE" ] || PLAN_IMAGE="postgres:16"
[ -n "$PLAN_CONTAINER" ] || PLAN_CONTAINER="pix2pi_pg_restore_drill_14_2_4"
[ -n "$PLAN_VOLUME" ] || PLAN_VOLUME="pix2pi_pg_restore_drill_14_2_4_data"

SANDBOX_CONTAINER="$PLAN_CONTAINER"
SANDBOX_VOLUME="$PLAN_VOLUME"
SANDBOX_IMAGE="$PLAN_IMAGE"
SANDBOX_DB="pix2pi_restore_drill"
SANDBOX_USER="pix2pi_restore"
SANDBOX_DUMP_PATH="/tmp/pix2pi_schema_only.dump"

SOURCE_DUMP_FILE="$(to_abs_path "$SOURCE_DUMP_REL")"

detail "SOURCE_DUMP_FILE=${SOURCE_DUMP_FILE#$ROOT_DIR/}"
detail "EXPECTED_SHA256=$EXPECTED_SHA"
detail "SANDBOX_CONTAINER=$SANDBOX_CONTAINER"
detail "SANDBOX_VOLUME=$SANDBOX_VOLUME"
detail "SANDBOX_IMAGE=$SANDBOX_IMAGE"
detail "SANDBOX_DB=$SANDBOX_DB"
detail "SANDBOX_USER=$SANDBOX_USER"

if [ ! -s "$SOURCE_DUMP_FILE" ]; then
  fail "source dump file yok veya bos"
fi

DUMP_SIZE_BYTES=0
if [ -f "$SOURCE_DUMP_FILE" ]; then
  DUMP_SIZE_BYTES="$(wc -c < "$SOURCE_DUMP_FILE" | tr -d ' ')"
fi
detail "DUMP_SIZE_BYTES=$DUMP_SIZE_BYTES"

ACTUAL_SHA=""
if [ "$SHA_FOUND" -eq 1 ] && [ -s "$SOURCE_DUMP_FILE" ]; then
  ACTUAL_SHA="$(sha256sum "$SOURCE_DUMP_FILE" | awk '{print $1}')"
fi

detail "ACTUAL_SHA256=$ACTUAL_SHA"

if [ -n "$EXPECTED_SHA" ] && [ -n "$ACTUAL_SHA" ]; then
  if [ "$EXPECTED_SHA" = "$ACTUAL_SHA" ]; then
    detail "DUMP_CHECKSUM_VERIFY=PASS"
  else
    fail "dump checksum mismatch"
    detail "DUMP_CHECKSUM_VERIFY=FAIL"
  fi
else
  fail "dump checksum degeri okunamadi"
  detail "DUMP_CHECKSUM_VERIFY=FAIL"
fi

SANDBOX_PORT="$(pick_port "$PLAN_PORT")"

if [ -z "$SANDBOX_PORT" ]; then
  fail "uygun sandbox port bulunamadi"
else
  detail "SANDBOX_PORT=$SANDBOX_PORT"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$SANDBOX_CONTAINER"; then
    docker rm -f "$SANDBOX_CONTAINER" >/tmp/pix2pi_14_2_4_pre_rm_container.log 2>&1 || true
    detail "PRE_CLEANUP_CONTAINER=REMOVED"
  else
    detail "PRE_CLEANUP_CONTAINER=NOT_FOUND"
  fi

  if docker volume ls --format '{{.Name}}' | grep -qx "$SANDBOX_VOLUME"; then
    docker volume rm "$SANDBOX_VOLUME" >/tmp/pix2pi_14_2_4_pre_rm_volume.log 2>&1 || true
    detail "PRE_CLEANUP_VOLUME=REMOVED"
  else
    detail "PRE_CLEANUP_VOLUME=NOT_FOUND"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker volume create "$SANDBOX_VOLUME" >/tmp/pix2pi_14_2_4_volume_create.log 2>&1; then
    VOLUME_CREATED=1
    detail "SANDBOX_VOLUME_CREATE=PASS"
  else
    fail "sandbox volume create failed"
    detail "SANDBOX_VOLUME_CREATE=FAIL"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker run -d \
    --name "$SANDBOX_CONTAINER" \
    -e POSTGRES_USER="$SANDBOX_USER" \
    -e POSTGRES_PASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" \
    -e POSTGRES_DB="$SANDBOX_DB" \
    -p "127.0.0.1:$SANDBOX_PORT:5432" \
    -v "$SANDBOX_VOLUME:/var/lib/postgresql/data" \
    "$SANDBOX_IMAGE" \
    >/tmp/pix2pi_14_2_4_docker_run.log 2>&1
  then
    SANDBOX_CREATED=1
    detail "SANDBOX_CONTAINER_CREATE=PASS"
  else
    fail "sandbox container create failed"
    detail "SANDBOX_CONTAINER_CREATE=FAIL"
  fi
fi

SANDBOX_READY="NO"

if [ "$FAIL_COUNT" -eq 0 ]; then
  for i in $(seq 1 60); do
    if docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" "$SANDBOX_CONTAINER" \
      psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc "select 1;" \
      >/tmp/pix2pi_14_2_4_sandbox_ready.log 2>&1
    then
      SANDBOX_READY="YES"
      break
    fi
    sleep 1
  done

  detail "SANDBOX_DB_READY=$SANDBOX_READY"

  if [ "$SANDBOX_READY" != "YES" ]; then
    fail "sandbox DB ready timeout"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker cp "$SOURCE_DUMP_FILE" "$SANDBOX_CONTAINER:$SANDBOX_DUMP_PATH" >/tmp/pix2pi_14_2_4_docker_cp.log 2>&1; then
    detail "DUMP_COPY_TO_SANDBOX=PASS"
  else
    fail "dump copy to sandbox failed"
    detail "DUMP_COPY_TO_SANDBOX=FAIL"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" "$SANDBOX_CONTAINER" \
    pg_restore \
      -U "$SANDBOX_USER" \
      -d "$SANDBOX_DB" \
      --no-owner \
      --no-privileges \
      "$SANDBOX_DUMP_PATH" \
      > "$RESTORE_STDOUT" \
      2> "$RESTORE_STDERR_RAW"
  then
    detail "SANDBOX_RESTORE_STATUS=PASS"
    evidence "RESTORE_EXECUTED=YES"
  else
    sanitize_file "$RESTORE_STDERR_RAW" "$RESTORE_STDERR_SANITIZED"
    detail "SANDBOX_RESTORE_STATUS=FAIL"
    detail "RESTORE_STDERR_SANITIZED=${RESTORE_STDERR_SANITIZED#$ROOT_DIR/}"
    fail "sandbox pg_restore failed"
  fi
fi

RESTORED_SCHEMA_COUNT=0
RESTORED_TABLE_COUNT=0
RESTORED_INDEX_COUNT=0
RESTORED_SCHEMA_MIGRATIONS_EXISTS="unknown"

if [ "$FAIL_COUNT" -eq 0 ]; then
  {
    echo "===== SANDBOX SQL EVIDENCE ====="

    echo "RESTORED_SCHEMA_COUNT=$(docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" "$SANDBOX_CONTAINER" psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc "select count(*) from information_schema.schemata where schema_name not like 'pg_%' and schema_name <> 'information_schema';" 2>/dev/null || echo error)"

    echo "RESTORED_TABLE_COUNT=$(docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" "$SANDBOX_CONTAINER" psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc "select count(*) from information_schema.tables where table_schema not in ('pg_catalog','information_schema');" 2>/dev/null || echo error)"

    echo "RESTORED_INDEX_COUNT=$(docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" "$SANDBOX_CONTAINER" psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc "select count(*) from pg_indexes where schemaname not like 'pg_%';" 2>/dev/null || echo error)"

    echo "RESTORED_SCHEMA_MIGRATIONS_EXISTS=$(docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD_VALUE" "$SANDBOX_CONTAINER" psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/dev/null || echo error)"
  } > "$SANDBOX_EVIDENCE"

  RESTORED_SCHEMA_COUNT="$(grep '^RESTORED_SCHEMA_COUNT=' "$SANDBOX_EVIDENCE" | cut -d= -f2-)"
  RESTORED_TABLE_COUNT="$(grep '^RESTORED_TABLE_COUNT=' "$SANDBOX_EVIDENCE" | cut -d= -f2-)"
  RESTORED_INDEX_COUNT="$(grep '^RESTORED_INDEX_COUNT=' "$SANDBOX_EVIDENCE" | cut -d= -f2-)"
  RESTORED_SCHEMA_MIGRATIONS_EXISTS="$(grep '^RESTORED_SCHEMA_MIGRATIONS_EXISTS=' "$SANDBOX_EVIDENCE" | cut -d= -f2-)"

  detail "RESTORED_SCHEMA_COUNT=$RESTORED_SCHEMA_COUNT"
  detail "RESTORED_TABLE_COUNT=$RESTORED_TABLE_COUNT"
  detail "RESTORED_INDEX_COUNT=$RESTORED_INDEX_COUNT"
  detail "RESTORED_SCHEMA_MIGRATIONS_EXISTS=$RESTORED_SCHEMA_MIGRATIONS_EXISTS"
  detail "SANDBOX_SQL_EVIDENCE_FILE=${SANDBOX_EVIDENCE#$ROOT_DIR/}"

  if ! safe_positive_int "$RESTORED_TABLE_COUNT"; then
    fail "restored table count positive degil: $RESTORED_TABLE_COUNT"
  fi

  if ! safe_positive_int "$RESTORED_SCHEMA_COUNT"; then
    fail "restored schema count positive degil: $RESTORED_SCHEMA_COUNT"
  fi
fi

cleanup_sandbox

if [ "$FAIL_COUNT" -eq 0 ]; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$SANDBOX_CONTAINER"; then
    fail "sandbox container cleanup sonrasi hala var"
    detail "SANDBOX_CONTAINER_REMAINING=YES"
  else
    detail "SANDBOX_CONTAINER_REMAINING=NO"
  fi

  if docker volume ls --format '{{.Name}}' | grep -qx "$SANDBOX_VOLUME"; then
    fail "sandbox volume cleanup sonrasi hala var"
    detail "SANDBOX_VOLUME_REMAINING=YES"
  else
    detail "SANDBOX_VOLUME_REMAINING=NO"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "RESTORE_DRILL_TEST=PASS"
else
  detail "RESTORE_DRILL_TEST=FAIL"
fi

{
  echo "# FAZ 4 / 14.2.4 - Restore Drill Test Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "RESTORE_DRILL_TEST=PASS"
  else
    echo "RESTORE_DRILL_TEST=FAIL"
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
  echo "SANDBOX_SQL_EVIDENCE_FILE=${SANDBOX_EVIDENCE#$ROOT_DIR/}"
  echo "RESTORE_STDOUT=${RESTORE_STDOUT#$ROOT_DIR/}"
  echo "RESTORE_STDERR_SANITIZED=${RESTORE_STDERR_SANITIZED#$ROOT_DIR/}"

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
  echo "POSTGRES_PASSWORD_PRINTED=NO"
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RESTORED_SCHEMA_COUNT=$RESTORED_SCHEMA_COUNT"
echo "RESTORED_TABLE_COUNT=$RESTORED_TABLE_COUNT"
echo "RESTORED_INDEX_COUNT=$RESTORED_INDEX_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESTORE_DRILL_TEST=FAIL ❌"
  exit 1
fi

echo "RESTORE_DRILL_TEST=PASS ✅"
