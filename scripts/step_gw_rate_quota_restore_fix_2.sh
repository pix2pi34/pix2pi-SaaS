#!/usr/bin/env bash
set -u

ROOT="/root/pix2pi/pix2pi-SaaS"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
TMP_DIR="$ROOT/tmp"
TMP_ENV="$TMP_DIR/common.env.restore_fix_2.tmp"
BACKUP_DIR="$ROOT/backups/gateway_rate_quota_restore_fix_2/$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$ROOT/reports/gw_rate_quota_restore_fix_2_$(date +%Y%m%d_%H%M%S).txt"
LATEST_LINK="$ROOT/reports/gw_rate_quota_restore_fix_2_latest.txt"

mkdir -p "$BACKUP_DIR" "$TMP_DIR" "$ROOT/reports"

echo "===== STEP 1 - FIX2 YEDEK ====="
cp "$ENV_FILE" "$BACKUP_DIR/common.env.before_fix2.bak"
echo "OK ✅ env yedegi alindi: $BACKUP_DIR/common.env.before_fix2.bak"

echo
echo "===== STEP 2 - SON TEST YEDEGI BUL ====="
LATEST_TEST_DIR="$(find "$ROOT/backups/gateway_rate_quota_live" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n 1)"
if [ -z "${LATEST_TEST_DIR:-}" ]; then
  echo "HATA ❌ gateway_rate_quota_live altinda test yedegi bulunamadi"
  exit 1
fi

BACKUP_FILE="$LATEST_TEST_DIR/common.env.bak"
if [ ! -f "$BACKUP_FILE" ]; then
  echo "HATA ❌ backup dosyasi yok: $BACKUP_FILE"
  exit 1
fi

echo "OK ✅ son test yedegi bulundu: $BACKUP_FILE"

echo
echo "===== STEP 3 - ORIJINAL DURUMU COZ ====="
BACKUP_RATE="$(awk -F= '/^GATEWAY_RATE_LIMIT_PER_MINUTE=/{print $2}' "$BACKUP_FILE" | tail -n 1)"
BACKUP_QUOTA="$(awk -F= '/^GATEWAY_DAILY_QUOTA=/{print $2}' "$BACKUP_FILE" | tail -n 1)"

USE_DEFAULTS="0"
EXPECTED_RATE=""
EXPECTED_QUOTA=""

if [ -n "$BACKUP_RATE" ] && [ -n "$BACKUP_QUOTA" ]; then
  EXPECTED_RATE="$BACKUP_RATE"
  EXPECTED_QUOTA="$BACKUP_QUOTA"
  echo "OK ✅ backup icinde explicit rate bulundu: $EXPECTED_RATE"
  echo "OK ✅ backup icinde explicit quota bulundu: $EXPECTED_QUOTA"
elif [ -z "$BACKUP_RATE" ] && [ -z "$BACKUP_QUOTA" ]; then
  USE_DEFAULTS="1"
  EXPECTED_RATE="3"
  EXPECTED_QUOTA="10"
  echo "OK ✅ backup icinde explicit rate/quota yok"
  echo "OK ✅ kod default varsayildi: rate=$EXPECTED_RATE quota=$EXPECTED_QUOTA"
else
  echo "HATA ❌ backup tutarsiz: sadece bir anahtar var"
  echo "BACKUP_RATE=$BACKUP_RATE"
  echo "BACKUP_QUOTA=$BACKUP_QUOTA"
  exit 1
fi

echo
echo "===== STEP 4 - ENV TEMIZLE ====="
grep -Ev '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" > "$TMP_ENV"

if [ "$USE_DEFAULTS" = "0" ]; then
  cat <<ENVEOF >> "$TMP_ENV"
GATEWAY_RATE_LIMIT_PER_MINUTE=$EXPECTED_RATE
GATEWAY_DAILY_QUOTA=$EXPECTED_QUOTA
ENVEOF
  echo "OK ✅ explicit rate/quota tekrar env dosyasina yazildi"
else
  echo "OK ✅ explicit rate/quota env dosyasina yazilmadi (default mod)"
fi

cp "$TMP_ENV" "$ENV_FILE"

echo
echo "===== STEP 5 - ENV SON DURUM ====="
grep -nE '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" || true
echo "OK ✅ env temizleme tamam"

echo
echo "===== STEP 6 - GATEWAY RESTART ====="
systemctl restart pix2pi-api-gateway
sleep 2
systemctl --no-pager --full status pix2pi-api-gateway | sed -n '1,20p'
echo "OK ✅ gateway restart denendi"

echo
echo "===== STEP 7 - LOCAL HEALTH ====="
LOCAL_HEALTH="$(curl -sS http://127.0.0.1:9010/health/live || true)"
echo "$LOCAL_HEALTH"

echo
echo "===== STEP 8 - INTERNAL POLICY ====="
INTERNAL_KEY="$(grep -E '^(GATEWAY_INTERNAL_KEY|INTERNAL_GATEWAY_KEY)=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"
if [ -z "${INTERNAL_KEY:-}" ]; then
  echo "HATA ❌ internal key okunamadi"
  exit 1
fi

POLICY_JSON="$(curl -sS -H "X-Gateway-Internal-Key: $INTERNAL_KEY" http://127.0.0.1:9010/internal/policy || true)"
echo "$POLICY_JSON"

ACTUAL_RATE="$(printf '%s' "$POLICY_JSON" | grep -o '"rate_limit_per_minute":[0-9]\+' | head -n 1 | cut -d: -f2)"
ACTUAL_QUOTA="$(printf '%s' "$POLICY_JSON" | grep -o '"daily_quota":[0-9]\+' | head -n 1 | cut -d: -f2)"

echo
echo "===== STEP 9 - KARSILASTIR ====="
echo "beklenen rate=$EXPECTED_RATE quota=$EXPECTED_QUOTA"
echo "gelen    rate=${ACTUAL_RATE:-bos} quota=${ACTUAL_QUOTA:-bos}"

PASS="1"

if [ "${ACTUAL_RATE:-}" != "$EXPECTED_RATE" ]; then
  PASS="0"
fi

if [ "${ACTUAL_QUOTA:-}" != "$EXPECTED_QUOTA" ]; then
  PASS="0"
fi

if [ "$USE_DEFAULTS" = "1" ]; then
  if grep -q '^GATEWAY_RATE_LIMIT_PER_MINUTE=' "$ENV_FILE"; then PASS="0"; fi
  if grep -q '^GATEWAY_DAILY_QUOTA=' "$ENV_FILE"; then PASS="0"; fi
else
  RATE_COUNT="$(grep -c '^GATEWAY_RATE_LIMIT_PER_MINUTE=' "$ENV_FILE" || true)"
  QUOTA_COUNT="$(grep -c '^GATEWAY_DAILY_QUOTA=' "$ENV_FILE" || true)"
  if [ "$RATE_COUNT" != "1" ]; then PASS="0"; fi
  if [ "$QUOTA_COUNT" != "1" ]; then PASS="0"; fi
fi

echo
echo "===== STEP 10 - RAPOR ====="
{
  echo "time=$(date '+%F %T %z')"
  echo "backup_file=$BACKUP_FILE"
  echo "use_defaults=$USE_DEFAULTS"
  echo "expected_rate=$EXPECTED_RATE"
  echo "expected_quota=$EXPECTED_QUOTA"
  echo "actual_rate=${ACTUAL_RATE:-}"
  echo "actual_quota=${ACTUAL_QUOTA:-}"
  echo
  echo "[env]"
  grep -nE '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" || true
  echo
  echo "[policy]"
  echo "$POLICY_JSON"
} > "$REPORT_FILE"

ln -sf "$REPORT_FILE" "$LATEST_LINK"

echo "OK ✅ rapor yazildi: $REPORT_FILE"
echo "OK ✅ latest rapor: $LATEST_LINK"

echo
echo "===== STEP 11 - SONUC ====="
if [ "$PASS" = "1" ]; then
  echo "OK ✅ restore mantigi duzeldi"
  echo "OK ✅ gateway policy beklenen degere dondu"
else
  echo "HATA ❌ restore mantigi hala beklenen degil"
fi
