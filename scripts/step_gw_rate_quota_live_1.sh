#!/usr/bin/env bash
set -u

ROOT="/root/pix2pi/pix2pi-SaaS"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
REPORT_DIR="$ROOT/reports"
BACKUP_DIR="$ROOT/backups/gateway_rate_quota_live/$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/gw_rate_quota_live_1_$(date +%Y%m%d_%H%M%S).txt"
LATEST_LINK="$REPORT_DIR/gw_rate_quota_live_1_latest.txt"

mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

ORIGINAL_ENV_BACKUP="$BACKUP_DIR/common.env.bak"
cp "$ENV_FILE" "$ORIGINAL_ENV_BACKUP"

cleanup() {
  echo
  echo "WARN ⚠ cleanup devrede, env geri yukleniyor..."
  cp "$ORIGINAL_ENV_BACKUP" "$ENV_FILE"
  systemctl restart pix2pi-api-gateway >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "===== GW RATE + QUOTA LIVE 1 ====="
echo "Tarih: $(date '+%F %T %z')"
echo "Root: $ROOT"
echo "Public Base: https://pix2pi.com.tr"
echo "Local Base: http://127.0.0.1:9010"
echo "Protected Path: /api/me"
echo

echo "===== STEP 1 - ENV YEDEK ====="
echo "OK ✅ env yedegi alindi: $ORIGINAL_ENV_BACKUP"

ORIG_RATE="$(awk -F= '/^GATEWAY_RATE_LIMIT_PER_MINUTE=/{print $2}' "$ORIGINAL_ENV_BACKUP" | tail -n 1)"
ORIG_QUOTA="$(awk -F= '/^GATEWAY_DAILY_QUOTA=/{print $2}' "$ORIGINAL_ENV_BACKUP" | tail -n 1)"

EXPECTED_RESTORE_RATE=""
EXPECTED_RESTORE_QUOTA=""
RESTORE_MODE=""

if [ -n "$ORIG_RATE" ] && [ -n "$ORIG_QUOTA" ]; then
  RESTORE_MODE="explicit"
  EXPECTED_RESTORE_RATE="$ORIG_RATE"
  EXPECTED_RESTORE_QUOTA="$ORIG_QUOTA"
elif [ -z "$ORIG_RATE" ] && [ -z "$ORIG_QUOTA" ]; then
  RESTORE_MODE="default"
  EXPECTED_RESTORE_RATE="3"
  EXPECTED_RESTORE_QUOTA="10"
else
  echo "HATA ❌ orijinal env tutarsiz. Sadece bir anahtar var."
  echo "ORIG_RATE=$ORIG_RATE"
  echo "ORIG_QUOTA=$ORIG_QUOTA"
  exit 1
fi

echo "OK ✅ orijinal restore modu: $RESTORE_MODE"
echo "OK ✅ restore hedefi rate=$EXPECTED_RESTORE_RATE quota=$EXPECTED_RESTORE_QUOTA"
echo

restart_gateway_and_wait() {
  systemctl restart pix2pi-api-gateway
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl -sS http://127.0.0.1:9010/health/live >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

get_internal_key() {
  grep -E '^(GATEWAY_INTERNAL_KEY|INTERNAL_GATEWAY_KEY)=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-
}

get_policy_json() {
  local key
  key="$(get_internal_key)"
  curl -sS -H "X-Gateway-Internal-Key: $key" http://127.0.0.1:9010/internal/policy
}

extract_policy_number() {
  local json="$1"
  local key="$2"
  printf '%s' "$json" | grep -o "\"$key\":[0-9]\+" | head -n 1 | cut -d: -f2
}

get_jwt_env_from_file() {
  grep -E '^GW_TEST_BEARER=' "$ROOT/tmp/gw_jwt_default_probe_winner.env" 2>/dev/null | tail -n 1 | cut -d= -f2-
}

get_tenant_env_from_file() {
  grep -E '^GW_TEST_TENANT=' "$ROOT/tmp/gw_jwt_default_probe_winner.env" 2>/dev/null | tail -n 1 | cut -d= -f2-
}

remove_rate_quota_lines() {
  grep -Ev '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" > "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"
}

restore_original_env() {
  cp "$ORIGINAL_ENV_BACKUP" "$ENV_FILE"
}

JWT_BEARER="${GW_TEST_BEARER:-}"
TENANT_ID="${GW_TEST_TENANT:-}"

if [ -z "$JWT_BEARER" ]; then
  JWT_BEARER="$(get_jwt_env_from_file)"
fi

if [ -z "$TENANT_ID" ]; then
  TENANT_ID="$(get_tenant_env_from_file)"
fi

if [ -z "$JWT_BEARER" ]; then
  echo "HATA ❌ JWT bulunamadi"
  echo "IPUCU: once su scripti calistir:"
  echo "bash scripts/step_gw_jwt_default_probe_1.sh"
  exit 1
fi

if [ -z "$TENANT_ID" ]; then
  TENANT_ID="tenant-001"
fi

echo "===== STEP 2 - RATE PHASE HAZIRLIK ====="
remove_rate_quota_lines
cat <<ENVEOF >> "$ENV_FILE"
GATEWAY_RATE_LIMIT_PER_MINUTE=2
GATEWAY_DAILY_QUOTA=50
ENVEOF
echo "OK ✅ test rate env yazildi: GATEWAY_RATE_LIMIT_PER_MINUTE=2"
echo "OK ✅ test quota env yazildi: GATEWAY_DAILY_QUOTA=50"
echo

echo "===== GATEWAY RESTART ====="
if restart_gateway_and_wait; then
  echo "OK ✅ gateway restart ve local health tamam"
else
  echo "HATA ❌ gateway restart sonrasi health gelmedi"
  exit 1
fi
echo

echo "===== STEP 3 - RATE PHASE JWT ====="
echo "OK ✅ JWT env uzerinden alindi"
echo "OK ✅ tenant env uzerinden alindi: $TENANT_ID"
echo

echo "===== STEP 4 - RATE PHASE CANLI ISTEK ====="
RATE_HIT_429="0"
RATE_STATUSES=""

for i in 1 2 3 4 5; do
  HDR_FILE="$ROOT/tmp/gw_rate_headers_$i.txt"
  BODY_FILE="$ROOT/tmp/gw_rate_body_$i.txt"

  STATUS="$(curl -sS \
    -D "$HDR_FILE" \
    -o "$BODY_FILE" \
    -w '%{http_code}' \
    -H "Authorization: Bearer $JWT_BEARER" \
    -H "X-Tenant-ID: $TENANT_ID" \
    https://pix2pi.com.tr/api/me || true)"

  RATE_STATUSES="${RATE_STATUSES}rate call #$i => status=$STATUS"$'\n'

  if [ "$STATUS" = "429" ]; then
    RATE_HIT_429="1"
    echo "OK ✅ rate phase 429 yakalandi"
    break
  fi
done

echo "$RATE_STATUSES"

if [ "$RATE_HIT_429" != "1" ]; then
  echo "HATA ❌ rate phase 429 yakalanamadi"
  for i in 1 2 3 4 5; do
    [ -f "$ROOT/tmp/gw_rate_body_$i.txt" ] && { echo "--- rate body #$i ---"; cat "$ROOT/tmp/gw_rate_body_$i.txt"; }
    [ -f "$ROOT/tmp/gw_rate_headers_$i.txt" ] && { echo "--- rate headers #$i ---"; sed -n '1,40p' "$ROOT/tmp/gw_rate_headers_$i.txt"; }
  done
  exit 1
fi
echo

echo "===== STEP 5 - QUOTA PHASE HAZIRLIK ====="
remove_rate_quota_lines
cat <<ENVEOF >> "$ENV_FILE"
GATEWAY_RATE_LIMIT_PER_MINUTE=50
GATEWAY_DAILY_QUOTA=3
ENVEOF
echo "OK ✅ quota test icin env yazildi: GATEWAY_RATE_LIMIT_PER_MINUTE=50"
echo "OK ✅ quota test icin env yazildi: GATEWAY_DAILY_QUOTA=3"
echo

echo "===== GATEWAY RESTART ====="
if restart_gateway_and_wait; then
  echo "OK ✅ gateway restart ve local health tamam"
else
  echo "HATA ❌ quota phase restart sonrasi health gelmedi"
  exit 1
fi
echo

echo "===== STEP 6 - QUOTA PHASE JWT ====="
echo "OK ✅ JWT env uzerinden alindi"
echo "OK ✅ tenant env uzerinden alindi: $TENANT_ID"
echo

echo "===== STEP 7 - QUOTA PHASE CANLI ISTEK ====="
QUOTA_BLOCKED="0"
QUOTA_STATUSES=""

for i in 1 2 3 4 5; do
  HDR_FILE="$ROOT/tmp/gw_quota_headers_$i.txt"
  BODY_FILE="$ROOT/tmp/gw_quota_body_$i.txt"

  STATUS="$(curl -sS \
    -D "$HDR_FILE" \
    -o "$BODY_FILE" \
    -w '%{http_code}' \
    -H "Authorization: Bearer $JWT_BEARER" \
    -H "X-Tenant-ID: $TENANT_ID" \
    https://pix2pi.com.tr/api/me || true)"

  QUOTA_STATUSES="${QUOTA_STATUSES}quota call #$i => status=$STATUS"$'\n'

  if [ "$STATUS" = "429" ]; then
    QUOTA_BLOCKED="1"
    echo "OK ✅ quota phase blok yakalandi"
    break
  fi
done

echo "$QUOTA_STATUSES"

if [ "$QUOTA_BLOCKED" != "1" ]; then
  echo "HATA ❌ quota phase blok yakalanamadi"
  for i in 1 2 3 4 5; do
    [ -f "$ROOT/tmp/gw_quota_body_$i.txt" ] && { echo "--- quota body #$i ---"; cat "$ROOT/tmp/gw_quota_body_$i.txt"; }
    [ -f "$ROOT/tmp/gw_quota_headers_$i.txt" ] && { echo "--- quota headers #$i ---"; sed -n '1,40p' "$ROOT/tmp/gw_quota_headers_$i.txt"; }
  done
  exit 1
fi
echo

echo "===== STEP 8 - ENV RESTORE ====="
restore_original_env
echo "OK ✅ common.env yedekten geri yuklendi"
echo

echo "===== GATEWAY RESTART ====="
if restart_gateway_and_wait; then
  echo "OK ✅ gateway restart ve local health tamam"
else
  echo "HATA ❌ restore sonrasi gateway health gelmedi"
  exit 1
fi
echo

echo "===== STEP 9 - RESTORE DOGRULAMA ====="
RESTORE_HEALTH="$(curl -sS http://127.0.0.1:9010/health/live || true)"
echo "restore health => 200"
echo "$RESTORE_HEALTH"

RESTORE_POLICY="$(get_policy_json)"
RESTORE_RATE="$(extract_policy_number "$RESTORE_POLICY" "rate_limit_per_minute")"
RESTORE_QUOTA="$(extract_policy_number "$RESTORE_POLICY" "daily_quota")"

echo "restore policy rate=$RESTORE_RATE quota=$RESTORE_QUOTA"

PASS_RESTORE="1"

if [ "$RESTORE_RATE" != "$EXPECTED_RESTORE_RATE" ]; then
  PASS_RESTORE="0"
fi

if [ "$RESTORE_QUOTA" != "$EXPECTED_RESTORE_QUOTA" ]; then
  PASS_RESTORE="0"
fi

if [ "$RESTORE_MODE" = "default" ]; then
  if grep -q '^GATEWAY_RATE_LIMIT_PER_MINUTE=' "$ENV_FILE"; then PASS_RESTORE="0"; fi
  if grep -q '^GATEWAY_DAILY_QUOTA=' "$ENV_FILE"; then PASS_RESTORE="0"; fi
else
  RATE_COUNT="$(grep -c '^GATEWAY_RATE_LIMIT_PER_MINUTE=' "$ENV_FILE" || true)"
  QUOTA_COUNT="$(grep -c '^GATEWAY_DAILY_QUOTA=' "$ENV_FILE" || true)"
  if [ "$RATE_COUNT" != "1" ]; then PASS_RESTORE="0"; fi
  if [ "$QUOTA_COUNT" != "1" ]; then PASS_RESTORE="0"; fi
fi

if [ "$PASS_RESTORE" = "1" ]; then
  echo "OK ✅ restore sonrasi policy dogru"
else
  echo "HATA ❌ restore sonrasi policy hatali"
  echo "$RESTORE_POLICY"
  exit 1
fi
echo

echo "===== STEP 10 - RAPOR ====="
{
  echo "time=$(date '+%F %T %z')"
  echo "restore_mode=$RESTORE_MODE"
  echo "expected_restore_rate=$EXPECTED_RESTORE_RATE"
  echo "expected_restore_quota=$EXPECTED_RESTORE_QUOTA"
  echo "actual_restore_rate=$RESTORE_RATE"
  echo "actual_restore_quota=$RESTORE_QUOTA"
  echo
  echo "[rate_statuses]"
  echo "$RATE_STATUSES"
  echo
  echo "[quota_statuses]"
  echo "$QUOTA_STATUSES"
  echo
  echo "[restore_policy]"
  echo "$RESTORE_POLICY"
} > "$REPORT_FILE"

ln -sf "$REPORT_FILE" "$LATEST_LINK"

echo "OK ✅ rapor yazildi: $REPORT_FILE"
echo "OK ✅ latest rapor: $LATEST_LINK"
echo

echo "===== STEP 11 - SON ====="
echo "OK ✅ rate phase calisti"
echo "OK ✅ quota phase calisti"
echo "OK ✅ restore dogrulamasi default-aware gecti"

trap - EXIT
