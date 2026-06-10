#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_4A_real_dsn_repair_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0
FOUND_WORKING=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
CANDIDATES_FILE="$(mktemp)"
SECRET_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$CANDIDATES_FILE" "$SECRET_FILE"' EXIT

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

mask_secret() {
  local v="$1"
  v="$(printf '%s' "$v" | sed -E 's#(://[^:/@]+:)[^@]+@#\1***@#g')"
  v="$(printf '%s' "$v" | sed -E 's#(password=)[^[:space:]]+#\1***#Ig')"
  echo "$v"
}

test_dsn() {
  local label="$1"
  local dsn="$2"

  local masked=""
  masked="$(mask_secret "$dsn")"

  echo "$label | $masked" >> "$CANDIDATES_FILE"

  if command -v psql >/dev/null 2>&1; then
    if PGCONNECT_TIMEOUT=3 psql "$dsn" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_1_4A_psql_ok.log 2>/tmp/pix2pi_14_1_4A_psql_err.log; then
      FOUND_WORKING=1
      printf '%s' "$dsn" > "$SECRET_FILE"
      detail "WORKING_DSN_LABEL=$label"
      detail "WORKING_DSN_MASKED=$masked"
      return 0
    fi
  else
    warn "psql bulunamadi"
  fi

  return 1
}

detail "ROOT_DIR=$ROOT_DIR"
detail "ENV_FILE=$ENV_FILE"

if ! command -v docker >/dev/null 2>&1; then
  fail "docker bulunamadi"
fi

if ! command -v psql >/dev/null 2>&1; then
  warn "psql bulunamadi; DSN test edilemez"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  CONTAINERS="$(docker ps --format '{{.Names}}' | grep -Ei 'postgres|pg|pix2pi.*db|db' || true)"

  if [ -z "$CONTAINERS" ]; then
    warn "calisan postgres/db container bulunamadi"
  fi

  for c in $CONTAINERS; do
    echo "CONTAINER_CANDIDATE=$c" >> "$DETAILS_FILE"

    USER_VAL="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_USER=' | tail -n 1 | cut -d= -f2- || true)"
    PASS_VAL="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_PASSWORD=' | tail -n 1 | cut -d= -f2- || true)"
    DB_VAL="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_DB=' | tail -n 1 | cut -d= -f2- || true)"
    PORT_VAL="$(docker inspect "$c" --format '{{(index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort}}' 2>/dev/null || true)"

    [ -n "$USER_VAL" ] || USER_VAL="postgres"
    [ -n "$DB_VAL" ] || DB_VAL="$USER_VAL"

    if [ -z "$PASS_VAL" ]; then
      echo "CONTAINER_${c}_PASSWORD_STATUS=NOT_FOUND" >> "$DETAILS_FILE"
      continue
    fi

    if [ -z "$PORT_VAL" ]; then
      echo "CONTAINER_${c}_HOST_PORT_STATUS=NOT_FOUND" >> "$DETAILS_FILE"
      continue
    fi

    DSN="postgres://${USER_VAL}:${PASS_VAL}@127.0.0.1:${PORT_VAL}/${DB_VAL}?sslmode=disable"

    if test_dsn "docker:${c}:127.0.0.1:${PORT_VAL}/${DB_VAL}" "$DSN"; then
      break
    fi
  done
fi

if [ "$FOUND_WORKING" -eq 1 ]; then
  WORKING_DSN="$(cat "$SECRET_FILE")"

  if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
  fi

  TMP_ENV="$(mktemp)"

  grep -v -E '^(DB_DSN|DB_WRITE_DSN)=' "$ENV_FILE" > "$TMP_ENV" || true

  {
    cat "$TMP_ENV"
    echo "DB_WRITE_DSN=$WORKING_DSN"
    echo "DB_DSN=$WORKING_DSN"
  } > "$ENV_FILE"

  chmod 600 "$ENV_FILE"
  rm -f "$TMP_ENV"

  detail "ENV_REPAIR_STATUS=UPDATED"
else
  warn "calisan DSN bulunamadi; .env guncellenmedi"
  detail "ENV_REPAIR_STATUS=NOT_UPDATED"
fi

{
  echo "# FAZ 4 / 14.1.4A - Real DB DSN Repair Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FOUND_WORKING_DSN=$FOUND_WORKING"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ] && [ "$FOUND_WORKING" -eq 1 ]; then
    echo "REAL_DSN_REPAIR=PASS"
  elif [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REAL_DSN_REPAIR=NEEDS_MANUAL_DSN"
  else
    echo "REAL_DSN_REPAIR=FAIL"
  fi

  echo
  echo "## Candidates"
  if [ -s "$CANDIDATES_FILE" ]; then
    cat "$CANDIDATES_FILE"
  else
    echo "DSN adayi yok"
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
echo "FOUND_WORKING_DSN=$FOUND_WORKING"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "REAL_DSN_REPAIR=FAIL ❌"
  exit 1
fi

if [ "$FOUND_WORKING" -eq 1 ]; then
  echo "REAL_DSN_REPAIR=PASS ✅"
else
  echo "REAL_DSN_REPAIR=NEEDS_MANUAL_DSN ⚠️"
fi
