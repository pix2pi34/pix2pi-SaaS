#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
MODE="${2:-status}"

ACTIVE_MIGRATION_DIR_REL="${ACTIVE_MIGRATION_DIR:-db/migrations}"
ACTIVE_MIGRATION_DIR="$ROOT_DIR/$ACTIVE_MIGRATION_DIR_REL"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_2_migration_apply_gate_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
SECRET_ENV_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$SECRET_ENV_FILE"' EXIT

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

case "$MODE" in
  status|dry-run|apply-check)
    true
    ;;
  *)
    fail "invalid mode: $MODE"
    ;;
esac

detail "ROOT_DIR=$ROOT_DIR"
detail "MODE=$MODE"
detail "ACTIVE_MIGRATION_DIR=$ACTIVE_MIGRATION_DIR_REL"

if [ ! -d "$ACTIVE_MIGRATION_DIR" ]; then
  fail "active migration dir not found: $ACTIVE_MIGRATION_DIR_REL"
  SQL_COUNT=0
else
  SQL_COUNT="$(find "$ACTIVE_MIGRATION_DIR" -maxdepth 1 -type f -name '*.sql' | wc -l | tr -d ' ')"
  if [ "$SQL_COUNT" -eq 0 ]; then
    fail "active migration sql file not found"
  fi
fi

detail "ACTIVE_MIGRATION_SQL_COUNT=$SQL_COUNT"

VALIDATOR="$ROOT_DIR/scripts/phase4_validate_migration_chain.sh"

if [ ! -x "$VALIDATOR" ]; then
  fail "migration chain validator not executable"
else
  if bash "$VALIDATOR" "$ROOT_DIR" "$ACTIVE_MIGRATION_DIR_REL" >/tmp/pix2pi_phase4_14_1_2_validator.log 2>&1; then
    detail "MIGRATION_CHAIN_VALIDATOR=PASS"
  else
    fail "migration chain validator failed"
  fi
fi

DISCOVERY="$ROOT_DIR/scripts/phase4_db_env_discovery.sh"

DB_DSN="${DB_DSN:-${DB_WRITE_DSN:-${DATABASE_URL:-}}}"

if [ -z "$DB_DSN" ] && [ -x "$DISCOVERY" ]; then
  if bash "$DISCOVERY" "$ROOT_DIR" write-env "$SECRET_ENV_FILE" >/tmp/pix2pi_phase4_14_1_2_db_env_loader.log 2>&1; then
    . "$SECRET_ENV_FILE"
    detail "DB_ENV_DISCOVERY=LOADED"
    detail "DB_DSN_KEY=${DB_DSN_KEY:-unknown}"
    detail "DB_DSN_SOURCE=${DB_DSN_SOURCE:-unknown}"
  else
    detail "DB_ENV_DISCOVERY=NO_DSN_FOUND"
  fi
elif [ -n "$DB_DSN" ]; then
  detail "DB_ENV_DISCOVERY=PROCESS_ENV"
else
  detail "DB_ENV_DISCOVERY=SCRIPT_NOT_FOUND"
fi

TOOL="not_found"

if [ -n "${MIGRATION_TOOL:-}" ]; then
  TOOL="$MIGRATION_TOOL"
elif command -v migrate >/dev/null 2>&1; then
  TOOL="migrate"
elif command -v goose >/dev/null 2>&1; then
  TOOL="goose"
fi

detail "MIGRATION_TOOL=$TOOL"

if [ "$TOOL" = "not_found" ]; then
  warn "migration tool bulunamadi"
fi

if [ -z "$DB_DSN" ]; then
  detail "DB_DSN_STATUS=NOT_CONFIGURED"
  warn "DB DSN bulunamadi; dirty check skip edildi"
else
  detail "DB_DSN_STATUS=CONFIGURED"

  if command -v psql >/dev/null 2>&1; then
    if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_phase4_14_1_2_psql_ok.log 2>/tmp/pix2pi_phase4_14_1_2_psql_err.log; then
      detail "DB_CONNECTION_CHECK=PASS"
      SCHEMA_MIGRATIONS_EXISTS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select to_regclass('public.schema_migrations') is not null;" 2>/dev/null || echo "error")"
      detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_MIGRATIONS_EXISTS"
    else
      detail "DB_CONNECTION_CHECK=SKIPPED_OR_FAILED"
      warn "DB connection check failed or timeout; raw DSN rapora yazilmadi"
    fi
  else
    warn "psql bulunamadi; dirty check skip edildi"
    detail "DB_CONNECTION_CHECK=PSQL_NOT_FOUND"
  fi
fi

if [ "$MODE" = "dry-run" ]; then
  detail "DRY_RUN_MODE=ON"
  detail "DRY_RUN_MUTATION=NO"
fi

if [ "$MODE" = "apply-check" ]; then
  detail "APPLY_CHECK_MODE=ON"
  detail "APPLY_MUTATION=NO"

  if [ "${APPLY:-0}" != "1" ]; then
    fail "APPLY_REQUIRES_EXPLICIT_CONFIRMATION"
  fi

  if [ "${BACKUP_GATE:-}" != "CONFIRMED" ]; then
    fail "APPLY_REQUIRES_BACKUP_GATE"
  fi

  if [ "$TOOL" = "not_found" ]; then
    fail "APPLY_REQUIRES_MIGRATION_TOOL"
  fi

  if [ -z "$DB_DSN" ]; then
    fail "APPLY_REQUIRES_DB_DSN"
  fi
fi

{
  echo "# FAZ 4 / 14.1.2 - Migration Apply Gate Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_APPLY_GATE=PASS"
  else
    echo "MIGRATION_APPLY_GATE=FAIL"
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
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "MIGRATION_APPLY_GATE=FAIL ❌"
  exit 1
fi

echo "MIGRATION_APPLY_GATE=PASS ✅"
