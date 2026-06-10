#!/bin/bash
set -euo pipefail

ROOT="$HOME/pix2pi/pix2pi-SaaS"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
BACKUP_DIR="$ROOT/_backup/step_423e"
TMP_FILE="$(mktemp)"
GW_PID=""

cleanup() {
  rm -f "$TMP_FILE" >/dev/null 2>&1 || true
  if [ -n "${GW_PID:-}" ] && kill -0 "$GW_PID" 2>/dev/null; then
    kill "$GW_PID" >/dev/null 2>&1 || true
    wait "$GW_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

extract_field() {
  local dsn="$1"
  local key="$2"
  printf '%s\n' "$dsn" | tr ' ' '\n' | awk -F= -v k="$key" '$1==k {sub($1"=",""); print; exit}'
}

echo "=== STEP 423E / GATEWAY DSN FIX ==="

mkdir -p "$BACKUP_DIR"

echo
echo "1. common.env backup aliniyor..."
if [ ! -f "$COMMON_ENV" ]; then
  echo "HATA ❌ common.env bulunamadi: $COMMON_ENV"
  exit 1
fi
cp "$COMMON_ENV" "$BACKUP_DIR/common.env_$(date +%F_%H%M%S).bak"
echo "OK ✅ common.env yedeklendi"

echo
echo "2. mevcut env okunuyor..."
set -a
source "$COMMON_ENV"
set +a

DB_HOST="$(extract_field "${DB_WRITE_DSN:-}" host)"
DB_PORT="$(extract_field "${DB_WRITE_DSN:-}" port)"
DB_NAME="$(extract_field "${DB_WRITE_DSN:-}" dbname)"
DB_SSLMODE="$(extract_field "${DB_WRITE_DSN:-}" sslmode)"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_NAME="${DB_NAME:-pix2pi}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

echo "DB_HOST=$DB_HOST"
echo "DB_PORT=$DB_PORT"
echo "DB_NAME=$DB_NAME"
echo "DB_SSLMODE=$DB_SSLMODE"
echo "OK ✅ env okundu"

echo
echo "3. dogru DB login testi..."
PGPASSWORD=pix2pi psql -h 127.0.0.1 -p "$DB_PORT" -U pix2pi -d "$DB_NAME" -Atqc 'select current_user, current_database();' \
  >/tmp/step_423e_psql.out 2>/tmp/step_423e_psql.err

cat /tmp/step_423e_psql.out
echo "OK ✅ pix2pi kullanicisi ile DB login basarili"

WRITE_DSN="host=$DB_HOST port=$DB_PORT user=pix2pi password=pix2pi dbname=$DB_NAME sslmode=$DB_SSLMODE"
READ_DSN="host=$DB_HOST port=$DB_PORT user=pix2pi password=pix2pi dbname=$DB_NAME sslmode=$DB_SSLMODE"

echo
echo "4. common.env guncelleniyor..."
FOUND_WRITE=0
FOUND_READ=0

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    DB_WRITE_DSN=*)
      printf '%s\n' "DB_WRITE_DSN=$WRITE_DSN" >> "$TMP_FILE"
      FOUND_WRITE=1
      ;;
    DB_READ_DSN=*)
      printf '%s\n' "DB_READ_DSN=$READ_DSN" >> "$TMP_FILE"
      FOUND_READ=1
      ;;
    *)
      printf '%s\n' "$line" >> "$TMP_FILE"
      ;;
  esac
done < "$COMMON_ENV"

if [ "$FOUND_WRITE" -eq 0 ]; then
  printf '%s\n' "DB_WRITE_DSN=$WRITE_DSN" >> "$TMP_FILE"
fi

if [ "$FOUND_READ" -eq 0 ]; then
  printf '%s\n' "DB_READ_DSN=$READ_DSN" >> "$TMP_FILE"
fi

cat "$TMP_FILE" > "$COMMON_ENV"
echo "OK ✅ common.env guncellendi"

echo
echo "5. go run ile gateway test..."
cd "$ROOT"
DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423e_gateway.log 2>&1 &
GW_PID=$!
sleep 5

if ! kill -0 "$GW_PID" 2>/dev/null; then
  echo "HATA ❌ gateway ayakta kalmadi"
  echo "--- gateway log ---"
  cat /tmp/step_423e_gateway.log || true
  exit 1
fi

curl -fsS http://127.0.0.1:9010/health >/tmp/step_423e_health.out 2>/tmp/step_423e_health.err
cat /tmp/step_423e_health.out
echo
echo "OK ✅ go run health testi basarili"

echo
echo "6. query route smoke test..."
set +e
curl -sS -i http://127.0.0.1:9010/api/query/users >/tmp/step_423e_query.out 2>/tmp/step_423e_query.err
QUERY_RC=$?
set -e

echo "--- /api/query/users response ---"
cat /tmp/step_423e_query.out 2>/dev/null || true
echo
echo "--- /api/query/users stderr ---"
cat /tmp/step_423e_query.err 2>/dev/null || true
echo
echo "OK ✅ query route smoke test bitti (RC=$QUERY_RC)"

echo
echo "7. systemd restart..."
kill "$GW_PID" >/dev/null 2>&1 || true
wait "$GW_PID" >/dev/null 2>&1 || true
GW_PID=""

systemctl restart pix2pi-api-gateway.service
sleep 3
echo "OK ✅ systemd restart tamam"

echo
echo "8. systemd health test..."
systemctl --no-pager --full status pix2pi-api-gateway.service | head -n 20 || true
echo "--- HEALTH ---"
curl -fsS http://127.0.0.1:9010/health
echo
echo "OK ✅ STEP 423E tamam"
