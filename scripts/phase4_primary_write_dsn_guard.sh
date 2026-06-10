#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_4B_primary_write_dsn_guard_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0
PRIMARY_FOUND=0
REPLICA_FOUND=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
CANDIDATES_FILE="$(mktemp)"
SECRET_PRIMARY_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$CANDIDATES_FILE" "$SECRET_PRIMARY_FILE"' EXIT

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

test_role() {
  local label="$1"
  local dsn="$2"
  local masked=""
  local recovery=""

  masked="$(mask_secret "$dsn")"

  if ! command -v psql >/dev/null 2>&1; then
    warn "psql bulunamadi"
    return 1
  fi

  if ! PGCONNECT_TIMEOUT=3 psql "$dsn" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_1_4B_psql_ok.log 2>/tmp/pix2pi_14_1_4B_psql_err.log; then
    echo "$label | CONNECTION_FAIL | $masked" >> "$CANDIDATES_FILE"
    return 1
  fi

  recovery="$(PGCONNECT_TIMEOUT=3 psql "$dsn" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();" 2>/tmp/pix2pi_14_1_4B_recovery_err.log || echo "error")"

  case "$recovery" in
    f)
      PRIMARY_FOUND=1
      printf '%s' "$dsn" > "$SECRET_PRIMARY_FILE"
      echo "$label | PRIMARY_WRITE | $masked" >> "$CANDIDATES_FILE"
      detail "PRIMARY_DSN_LABEL=$label"
      detail "PRIMARY_DSN_MASKED=$masked"
      ;;
    t)
      REPLICA_FOUND=1
      echo "$label | REPLICA_READ_ONLY | $masked" >> "$CANDIDATES_FILE"
      ;;
    *)
      echo "$label | ROLE_UNKNOWN | $masked" >> "$CANDIDATES_FILE"
      warn "pg_is_in_recovery okunamadi: $label"
      ;;
  esac
}

detail "ROOT_DIR=$ROOT_DIR"
detail "ENV_FILE=$ENV_FILE"

if ! command -v docker >/dev/null 2>&1; then
  fail "docker bulunamadi"
fi

if ! command -v psql >/dev/null 2>&1; then
  fail "psql bulunamadi"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  CONTAINERS="$(docker ps --format '{{.Names}}' | grep -Ei 'postgres|pg|pix2pi.*db|db' || true)"

  if [ -z "$CONTAINERS" ]; then
    warn "calisan postgres/db container bulunamadi"
  fi

  for c in $CONTAINERS; do
    detail "CONTAINER_CANDIDATE=$c"

    USER_VAL="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_USER=' | tail -n 1 | cut -d= -f2- || true)"
    PASS_VAL="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_PASSWORD=' | tail -n 1 | cut -d= -f2- || true)"
    DB_VAL="$(docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^POSTGRES_DB=' | tail -n 1 | cut -d= -f2- || true)"
    PORT_VAL="$(docker inspect "$c" --format '{{(index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort}}' 2>/dev/null || true)"

    [ -n "$USER_VAL" ] || USER_VAL="postgres"
    [ -n "$DB_VAL" ] || DB_VAL="$USER_VAL"

    if [ -z "$PASS_VAL" ]; then
      detail "CONTAINER_${c}_PASSWORD_STATUS=NOT_FOUND"
      continue
    fi

    if [ -z "$PORT_VAL" ]; then
      detail "CONTAINER_${c}_HOST_PORT_STATUS=NOT_FOUND"
      continue
    fi

    DSN="postgres://${USER_VAL}:${PASS_VAL}@127.0.0.1:${PORT_VAL}/${DB_VAL}?sslmode=disable"
    test_role "docker:${c}:127.0.0.1:${PORT_VAL}/${DB_VAL}" "$DSN"
  done
fi

if [ "$PRIMARY_FOUND" -eq 1 ]; then
  PRIMARY_DSN="$(cat "$SECRET_PRIMARY_FILE")"

  if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
  fi

  TMP_ENV="$(mktemp)"
  grep -v -E '^(DB_DSN|DB_WRITE_DSN)=' "$ENV_FILE" > "$TMP_ENV" || true

  {
    cat "$TMP_ENV"
    echo "DB_WRITE_DSN=$PRIMARY_DSN"
    echo "DB_DSN=$PRIMARY_DSN"
  } > "$ENV_FILE"

  chmod 600 "$ENV_FILE"
  rm -f "$TMP_ENV"

  detail "ENV_PRIMARY_WRITE_DSN_UPDATE=UPDATED"
else
  warn "primary/write DSN bulunamadi; .env guncellenmedi"
  detail "ENV_PRIMARY_WRITE_DSN_UPDATE=NOT_UPDATED"
fi

detail "PRIMARY_DSN_FOUND=$PRIMARY_FOUND"
detail "REPLICA_DSN_FOUND=$REPLICA_FOUND"

{
  echo "# FAZ 4 / 14.1.4B - Primary Write DSN Guard Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ] && [ "$PRIMARY_FOUND" -eq 1 ]; then
    echo "PRIMARY_WRITE_DSN_GUARD=PASS"
  elif [ "$FAIL_COUNT" -eq 0 ]; then
    echo "PRIMARY_WRITE_DSN_GUARD=NEEDS_PRIMARY_DSN"
  else
    echo "PRIMARY_WRITE_DSN_GUARD=FAIL"
  fi

  echo
  echo "## DB Candidates"
  if [ -s "$CANDIDATES_FILE" ]; then
    echo "LABEL | ROLE | MASKED_DSN"
    cat "$CANDIDATES_FILE"
  else
    echo "DB adayi yok"
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
echo "PRIMARY_DSN_FOUND=$PRIMARY_FOUND"
echo "REPLICA_DSN_FOUND=$REPLICA_FOUND"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "PRIMARY_WRITE_DSN_GUARD=FAIL ❌"
  exit 1
fi

if [ "$PRIMARY_FOUND" -eq 1 ]; then
  echo "PRIMARY_WRITE_DSN_GUARD=PASS ✅"
else
  echo "PRIMARY_WRITE_DSN_GUARD=NEEDS_PRIMARY_DSN ⚠️"
fi
