#!/usr/bin/env bash
set -euo pipefail

SCHEMA="${SCHEMA:-public}"
APPLY="${APPLY:-0}"
SEED_SCOPE="${SEED_SCOPE:-FAZ4_IMPORT_CORE}"
SEED_VERSION="${SEED_VERSION:-v1}"
APPLIED_BY="${APPLIED_BY:-system_seed}"
CORRELATION_ID="${CORRELATION_ID:-faz_4_14_2_reference_seed}"
SEED_SQL_FILE="${SEED_SQL_FILE:-}"

load_env_files() {
  set +u
  if [ -f ".env" ]; then
    source ".env"
  fi
  if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
    source "/opt/pix2pi/orchestrator/env/common.env"
  fi
  if [ -f "/etc/pix2pi/ports.env" ]; then
    source "/etc/pix2pi/ports.env"
  fi
  set -u
}

resolve_db_dsn() {
  load_env_files

  if [ -n "${DB_WRITE_DSN:-}" ]; then
    echo "$DB_WRITE_DSN"
    return 0
  fi

  if [ -n "${DATABASE_URL:-}" ]; then
    echo "$DATABASE_URL"
    return 0
  fi

  if [ -n "${POSTGRES_DSN:-}" ]; then
    echo "$POSTGRES_DSN"
    return 0
  fi

  if [ -n "${PIX2PI_DB_DSN:-}" ]; then
    echo "$PIX2PI_DB_DSN"
    return 0
  fi

  echo ""
  return 1
}

fail() {
  echo "REFERENCE_SEED_ERROR=$1"
  exit 1
}

case "$SCHEMA" in
  ''|*[!a-zA-Z0-9_]*)
    fail "INVALID_SCHEMA_NAME"
    ;;
esac

case "$SEED_SCOPE" in
  ''|*[!A-Z0-9_]*)
    fail "INVALID_SEED_SCOPE"
    ;;
esac

case "$SEED_VERSION" in
  ''|*[!a-zA-Z0-9_.-]*)
    fail "INVALID_SEED_VERSION"
    ;;
esac

if [ "$APPLY" != "0" ] && [ "$APPLY" != "1" ]; then
  fail "APPLY_MUST_BE_0_OR_1"
fi

if [ -z "$SEED_SQL_FILE" ]; then
  SEED_SQL_FILE="$(find db/seeds/faz4 -maxdepth 1 -type f -name "*_faz_4_14_2_reference_data_seed_standard.sql" | sort | tail -n 1 || true)"
fi

if [ -z "$SEED_SQL_FILE" ] || [ ! -f "$SEED_SQL_FILE" ]; then
  fail "SEED_SQL_FILE_NOT_FOUND"
fi

DB_DSN="$(resolve_db_dsn || true)"

if [ -z "$DB_DSN" ]; then
  fail "DB_DSN_NOT_FOUND"
fi

if ! command -v psql >/dev/null 2>&1; then
  fail "PSQL_NOT_FOUND"
fi

echo "===== REFERENCE DATA SEED START ====="
echo "SCHEMA=${SCHEMA}"
echo "APPLY=${APPLY}"
echo "SEED_SCOPE=${SEED_SCOPE}"
echo "SEED_VERSION=${SEED_VERSION}"
echo "SEED_SQL_FILE=${SEED_SQL_FILE}"

if [ "$APPLY" = "0" ]; then
  echo "REFERENCE_SEED_STATUS=DRY_RUN_ONLY"
  echo "REFERENCE_SEED_MUTATION_APPLIED=NO"
  echo "REFERENCE_SEED_SQL_FILE=${SEED_SQL_FILE}"
  echo "REFERENCE_SEED_SCOPE=${SEED_SCOPE}"
  echo "REFERENCE_SEED_VERSION=${SEED_VERSION}"
  exit 0
fi

psql "$DB_DSN" -v ON_ERROR_STOP=1 \
  -v schema_name="$SCHEMA" \
  -v seed_scope="$SEED_SCOPE" \
  -v seed_version="$SEED_VERSION" \
  -v applied_by="$APPLIED_BY" \
  -v correlation_id="$CORRELATION_ID" \
  -f "$SEED_SQL_FILE"

echo "REFERENCE_SEED_STATUS=APPLIED"
echo "REFERENCE_SEED_MUTATION_APPLIED=YES"
