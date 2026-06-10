#!/usr/bin/env bash
set -u

ROOT="/root/pix2pi/pix2pi-SaaS"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
FIX_BACKUP_DIR="$ROOT/backups/gateway_rate_quota_restore_fix/$(date +%Y%m%d_%H%M%S)"
TMP_FILE="$ROOT/tmp/common.env.restore_fix.tmp"

mkdir -p "$FIX_BACKUP_DIR" "$ROOT/tmp"

echo "===== STEP 1 - FIX YEDEK ====="
cp "$ENV_FILE" "$FIX_BACKUP_DIR/common.env.before_fix.bak"
echo "OK ✅ env yedegi alindi: $FIX_BACKUP_DIR/common.env.before_fix.bak"

echo
echo "===== STEP 2 - SON TEST YEDEGI BUL ====="
LATEST_TEST_DIR="$(find "$ROOT/backups/gateway_rate_quota_live" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n 1)"
if [ -z "${LATEST_TEST_DIR:-}" ]; then
  echo "HATA ❌ gateway_rate_quota_live altinda backup dizini bulunamadi"
  exit 1
fi

BACKUP_FILE="$LATEST_TEST_DIR/common.env.bak"
if [ ! -f "$BACKUP_FILE" ]; then
  echo "HATA ❌ backup dosyasi yok: $BACKUP_FILE"
  exit 1
fi

echo "OK ✅ son test yedegi bulundu: $BACKUP_FILE"

echo
echo "===== STEP 3 - ORIJINAL DEGERLERI CEK ====="
ORIG_RATE="$(grep -E '^GATEWAY_RATE_LIMIT_PER_MINUTE=' "$BACKUP_FILE" | tail -n 1 | cut -d= -f2-)"
ORIG_QUOTA="$(grep -E '^GATEWAY_DAILY_QUOTA=' "$BACKUP_FILE" | tail -n 1 | cut -d= -f2-)"

if [ -z "${ORIG_RATE:-}" ] || [ -z "${ORIG_QUOTA:-}" ]; then
  echo "HATA ❌ backup icinden orijinal rate/quota okunamadi"
  exit 1
fi

echo "OK ✅ orijinal rate: $ORIG_RATE"
echo "OK ✅ orijinal quota: $ORIG_QUOTA"

echo
echo "===== STEP 4 - ENV TEMIZLE VE TEKIL YAZ ====="
grep -Ev '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" > "$TMP_FILE"

cat <<ENVEOF >> "$TMP_FILE"
GATEWAY_RATE_LIMIT_PER_MINUTE=$ORIG_RATE
GATEWAY_DAILY_QUOTA=$ORIG_QUOTA
ENVEOF

cp "$TMP_FILE" "$ENV_FILE"

echo "OK ✅ env tekil restore yazildi"
grep -nE '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" || true

echo
echo "===== STEP 5 - GATEWAY RESTART ====="
systemctl restart pix2pi-api-gateway
sleep 2
systemctl --no-pager --full status pix2pi-api-gateway | sed -n '1,25p'
echo "OK ✅ gateway restart denendi"

echo
echo "===== STEP 6 - LOCAL HEALTH ====="
HEALTH="$(curl -sS http://127.0.0.1:9010/health/live || true)"
echo "$HEALTH"

echo
echo "===== STEP 7 - INTERNAL POLICY DOGRULAMA ====="
INTERNAL_KEY="$(grep -E '^(GATEWAY_INTERNAL_KEY|INTERNAL_GATEWAY_KEY)=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"
if [ -z "${INTERNAL_KEY:-}" ]; then
  echo "HATA ❌ internal key env icinden okunamadi"
  exit 1
fi

POLICY="$(curl -sS -H "X-Gateway-Internal-Key: $INTERNAL_KEY" http://127.0.0.1:9010/internal/policy || true)"
echo "$POLICY"

PASS=1

echo "$POLICY" | grep -q "\"rate_limit_per_minute\":$ORIG_RATE" || PASS=0
echo "$POLICY" | grep -q "\"daily_quota\":$ORIG_QUOTA" || PASS=0

echo
echo "===== STEP 8 - SONUC ====="
if [ "$PASS" = "1" ]; then
  echo "OK ✅ restore policy duzeldi"
  echo "OK ✅ rate=$ORIG_RATE quota=$ORIG_QUOTA"
else
  echo "HATA ❌ restore policy hala beklenen degil"
  echo "BEKLENEN rate=$ORIG_RATE quota=$ORIG_QUOTA"
fi

echo
echo "===== STEP 9 - RAPOR ====="
REPORT_FILE="$ROOT/reports/gw_rate_quota_restore_fix_1_$(date +%Y%m%d_%H%M%S).txt"
{
  echo "restore_fix_time=$(date '+%F %T %z')"
  echo "backup_file=$BACKUP_FILE"
  echo "expected_rate=$ORIG_RATE"
  echo "expected_quota=$ORIG_QUOTA"
  echo
  echo "[env]"
  grep -nE '^(GATEWAY_RATE_LIMIT_PER_MINUTE|GATEWAY_DAILY_QUOTA)=' "$ENV_FILE" || true
  echo
  echo "[policy]"
  echo "$POLICY"
} > "$REPORT_FILE"

ln -sf "$REPORT_FILE" "$ROOT/reports/gw_rate_quota_restore_fix_1_latest.txt"

echo "OK ✅ rapor yazildi: $REPORT_FILE"
echo "OK ✅ latest rapor: $ROOT/reports/gw_rate_quota_restore_fix_1_latest.txt"
