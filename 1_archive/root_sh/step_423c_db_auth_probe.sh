#!/bin/bash
set -euo pipefail

GW_PID=""
cleanup() {
  if [ -n "${GW_PID:-}" ] && kill -0 "$GW_PID" 2>/dev/null; then
    kill "$GW_PID" >/dev/null 2>&1 || true
    wait "$GW_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "=== STEP 423C / DB AUTH PROBE ==="

ROOT="$HOME/pix2pi/pix2pi-SaaS"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
BACKUP_DIR="$ROOT/_backup/step_423c"

mkdir -p "$BACKUP_DIR"

echo
echo "1. common.env backup aliniyor..."
if [ ! -f "$COMMON_ENV" ]; then
  echo "HATA ❌ common.env bulunamadi: $COMMON_ENV"
  exit 1
fi
cp "$COMMON_ENV" "$BACKUP_DIR/common.env_$(date +%F_%H%M%S).bak"
echo "OK ✅ common.env yedeklendi"

extract_field() {
  local dsn="$1"
  local key="$2"
  printf '%s\n' "$dsn" | tr ' ' '\n' | awk -F= -v k="$key" '$1==k {sub($1"=",""); print; exit}'
}

echo
echo "2. mevcut env yukleniyor..."
set -a
source "$COMMON_ENV"
set +a
echo "OK ✅ env yüklendi"

DB_HOST="$(extract_field "${DB_WRITE_DSN:-}" host)"
DB_PORT="$(extract_field "${DB_WRITE_DSN:-}" port)"
DB_USER="$(extract_field "${DB_WRITE_DSN:-}" user)"
DB_NAME="$(extract_field "${DB_WRITE_DSN:-}" dbname)"
DB_SSLMODE="$(extract_field "${DB_WRITE_DSN:-}" sslmode)"
CURRENT_PASSWORD="$(extract_field "${DB_WRITE_DSN:-}" password)"

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-5433}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-pix2pi}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

echo
echo "3. mevcut baglanti bilgisi..."
echo "DB_HOST=$DB_HOST"
echo "DB_PORT=$DB_PORT"
echo "DB_USER=$DB_USER"
echo "DB_NAME=$DB_NAME"
echo "DB_SSLMODE=$DB_SSLMODE"
if [ -n "${CURRENT_PASSWORD:-}" ]; then
  echo "DB_PASSWORD(current)=SET"
else
  echo "DB_PASSWORD(current)=BOS"
fi
echo "OK ✅ mevcut baglanti bilgisi okundu"

CAND_FILE="$(mktemp)"

add_candidate() {
  local value="${1:-}"
  [ -n "$value" ] || return 0
  grep -Fxq "$value" "$CAND_FILE" 2>/dev/null || printf '%s\n' "$value" >> "$CAND_FILE"
}

echo
echo "4. aday sifreler toplanıyor..."
add_candidate "$CURRENT_PASSWORD"
add_candidate "postgres"

if [ -d "$ROOT" ]; then
  while IFS= read -r line; do
    add_candidate "${line#POSTGRES_PASSWORD=}"
  done < <(grep -Rho '^POSTGRES_PASSWORD=.*' "$ROOT" 2>/dev/null || true)
fi

if [ -d /opt/pix2pi ]; then
  while IFS= read -r line; do
    add_candidate "${line#POSTGRES_PASSWORD=}"
  done < <(grep -Rho '^POSTGRES_PASSWORD=.*' /opt/pix2pi 2>/dev/null || true)
fi

DB_CONTAINER="$(docker ps --format '{{.Names}} {{.Ports}}' | awk '/5433->5432/ {print $1; exit}')"
if [ -z "$DB_CONTAINER" ] && docker ps --format '{{.Names}}' | grep -qx 'pix2pi-db'; then
  DB_CONTAINER="pix2pi-db"
fi

if [ -n "$DB_CONTAINER" ]; then
  while IFS= read -r line; do
    case "$line" in
      POSTGRES_PASSWORD=*)
        add_candidate "${line#POSTGRES_PASSWORD=}"
        ;;
    esac
  done < <(docker inspect "$DB_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)
  echo "DB_CONTAINER=$DB_CONTAINER"
else
  echo "DB_CONTAINER=BULUNAMADI"
fi

echo "Toplanan aday sifre sayisi: $(wc -l < "$CAND_FILE" | tr -d ' ')"
echo "OK ✅ aday sifre toplama bitti"

test_with_psql_host() {
  local password="$1"
  PGPASSWORD="$password" psql -h 127.0.0.1 -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -Atqc 'select 1;' >/tmp/step_423c_psql.out 2>/tmp/step_423c_psql.err
}

test_with_docker_container() {
  local password="$1"
  [ -n "$DB_CONTAINER" ] || return 1
  docker exec -e PGPASSWORD="$password" "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -Atqc 'select 1;' >/tmp/step_423c_psql.out 2>/tmp/step_423c_psql.err
}

WORKING_PASSWORD=""

echo
echo "5. aday sifreler test ediliyor..."
while IFS= read -r candidate; do
  [ -n "$candidate" ] || continue
  echo "deneniyor -> [$candidate]"

  if command -v psql >/dev/null 2>&1; then
    if test_with_psql_host "$candidate"; then
      WORKING_PASSWORD="$candidate"
      break
    fi
  else
    if test_with_docker_container "$candidate"; then
      WORKING_PASSWORD="$candidate"
      break
    fi
  fi
done < "$CAND_FILE"

if [ -z "$WORKING_PASSWORD" ]; then
  echo "HATA ❌ çalışan DB şifresi bulunamadi"
  echo "--- son psql hatasi ---"
  cat /tmp/step_423c_psql.err || true
  exit 1
fi

echo "OK ✅ çalışan DB şifresi bulundu: $WORKING_PASSWORD"

WRITE_DSN="host=$DB_HOST port=$DB_PORT user=$DB_USER password=$WORKING_PASSWORD dbname=$DB_NAME sslmode=$DB_SSLMODE"
READ_DSN="host=$DB_HOST port=$DB_PORT user=$DB_USER password=$WORKING_PASSWORD dbname=$DB_NAME sslmode=$DB_SSLMODE"

echo
echo "6. API Gateway geçici doğru DSN ile test ediliyor..."
cd "$ROOT"
DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423c_gateway.log 2>&1 &
GW_PID=$!
sleep 4

if kill -0 "$GW_PID" 2>/dev/null; then
  if curl -fsS http://127.0.0.1:9010/health >/tmp/step_423c_health.out 2>/tmp/step_423c_health.err; then
    echo "OK ✅ /health ayağa kalktı"
    cat /tmp/step_423c_health.out
  else
    echo "HATA ❌ gateway process açık ama /health cevap vermedi"
    echo "--- health stderr ---"
    cat /tmp/step_423c_health.err || true
    echo "--- gateway log ---"
    cat /tmp/step_423c_gateway.log || true
    exit 1
  fi
else
  echo "HATA ❌ gateway hemen düştü"
  echo "--- gateway log ---"
  cat /tmp/step_423c_gateway.log || true
  exit 1
fi

APPLY_SCRIPT="$ROOT/step_423d_apply_common_env_fix.sh"

cat <<EOF2 > "$APPLY_SCRIPT"
#!/bin/bash
set -euo pipefail

echo "=== STEP 423D / COMMON.ENV KALICI FIX ==="

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
BACKUP_DIR="\$HOME/pix2pi/pix2pi-SaaS/_backup/step_423d"
TMP_FILE="\$(mktemp)"

mkdir -p "\$BACKUP_DIR"

echo
echo "1. common.env backup aliniyor..."
cp "\$COMMON_ENV" "\$BACKUP_DIR/common.env_\$(date +%F_%H%M%S).bak"
echo "OK ✅ common.env yedeklendi"

FOUND_WRITE=0
FOUND_READ=0

echo
echo "2. common.env guncelleniyor..."
while IFS= read -r line || [ -n "\$line" ]; do
  case "\$line" in
    DB_WRITE_DSN=*)
      printf '%s\n' 'DB_WRITE_DSN=$WRITE_DSN' >> "\$TMP_FILE"
      FOUND_WRITE=1
      ;;
    DB_READ_DSN=*)
      printf '%s\n' 'DB_READ_DSN=$READ_DSN' >> "\$TMP_FILE"
      FOUND_READ=1
      ;;
    *)
      printf '%s\n' "\$line" >> "\$TMP_FILE"
      ;;
  esac
done < "\$COMMON_ENV"

if [ "\$FOUND_WRITE" -eq 0 ]; then
  printf '%s\n' 'DB_WRITE_DSN=$WRITE_DSN' >> "\$TMP_FILE"
fi

if [ "\$FOUND_READ" -eq 0 ]; then
  printf '%s\n' 'DB_READ_DSN=$READ_DSN' >> "\$TMP_FILE"
fi

cat "\$TMP_FILE" > "\$COMMON_ENV"
rm -f "\$TMP_FILE"
echo "OK ✅ common.env güncellendi"

echo
echo "3. service restart..."
systemctl restart pix2pi-api-gateway.service
sleep 3
echo "OK ✅ service restart tamam"

echo
echo "4. service test..."
systemctl status pix2pi-api-gateway.service --no-pager -l | head -n 20 || true
echo "--- HEALTH ---"
curl -fsS http://127.0.0.1:9010/health
echo
echo "OK ✅ service testi bitti"
EOF2

chmod +x "$APPLY_SCRIPT"
echo
echo "7. kalici fix scripti hazirlandi..."
echo "OK ✅ $APPLY_SCRIPT"

echo
echo "8. kullanilacak kalici DSN degerleri..."
echo "DB_WRITE_DSN=$WRITE_DSN"
echo "DB_READ_DSN=$READ_DSN"
echo "OK ✅ STEP 423C tamam"
