#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
SERVICE_NAME="pix2pi-api-gateway.service"
GATEWAY_URL="http://127.0.0.1:9010"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "===== STEP 1 - ENV YEDEK ====="
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="backups/gateway_env/common.env.bak.${STAMP}"
cp "$ENV_FILE" "$BACKUP_PATH"
echo "OK ✅ common.env yedegi alindi: $BACKUP_PATH"

echo
echo "===== STEP 2 - ANAHTAR DEGERINI BUL ====="
KEY_VALUE="$(grep -E '^GATEWAY_INTERNAL_KEY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2- || true)"
if [ -z "${KEY_VALUE}" ]; then
  KEY_VALUE="$(grep -E '^INTERNAL_GATEWAY_KEY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2- || true)"
fi

if [ -z "${KEY_VALUE}" ]; then
  echo "HATA ❌ common.env icinde ne GATEWAY_INTERNAL_KEY ne INTERNAL_GATEWAY_KEY bulundu"
  exit 1
fi

echo "OK ✅ anahtar degeri bulundu: ${KEY_VALUE}"

echo
echo "===== STEP 3 - ENV HIZALAMA ====="
if grep -q '^GATEWAY_INTERNAL_KEY=' "$ENV_FILE"; then
  echo "OK ✅ GATEWAY_INTERNAL_KEY zaten var"
else
  cat <<ENVADD >> "$ENV_FILE"
GATEWAY_INTERNAL_KEY=${KEY_VALUE}
ENVADD
  echo "OK ✅ GATEWAY_INTERNAL_KEY common.env sonuna eklendi"
fi

echo
echo "===== STEP 4 - ENV SON DURUM ====="
grep -nE '^(INTERNAL_GATEWAY_KEY|GATEWAY_INTERNAL_KEY)=' "$ENV_FILE" || true
echo "OK ✅ env kontrolu bitti"

echo
echo "===== STEP 5 - GATEWAY RESTART ====="
systemctl restart "$SERVICE_NAME"
sleep 2
systemctl --no-pager --full status "$SERVICE_NAME" | head -n 20
echo "OK ✅ gateway restart denendi"

echo
echo "===== STEP 6 - CANLI PROCESS ENV ====="
MAIN_PID="$(systemctl show -p MainPID --value "$SERVICE_NAME")"
if [ -z "${MAIN_PID}" ] || [ "${MAIN_PID}" = "0" ]; then
  echo "HATA ❌ MainPID bulunamadi"
  exit 1
fi

tr '\0' '\n' < "/proc/${MAIN_PID}/environ" | grep -E '^(INTERNAL_GATEWAY_KEY|GATEWAY_INTERNAL_KEY)=' || true
echo "OK ✅ process env kontrolu bitti"

echo
echo "===== STEP 7 - CANLI HTTP DOGRULAMA ====="

echo "--- /health/live ---"
curl -sS -D "$TMP_DIR/health.headers" -o "$TMP_DIR/health.body" \
  "${GATEWAY_URL}/health/live" || true
head -n 20 "$TMP_DIR/health.headers"
cat "$TMP_DIR/health.body"

echo
echo "--- /internal/routes | key yok ---"
curl -sS -D "$TMP_DIR/internal_no_key.headers" -o "$TMP_DIR/internal_no_key.body" \
  "${GATEWAY_URL}/internal/routes" || true
head -n 20 "$TMP_DIR/internal_no_key.headers"
cat "$TMP_DIR/internal_no_key.body"

echo
echo "--- /internal/routes | key var ---"
curl -sS -D "$TMP_DIR/internal_key.headers" -o "$TMP_DIR/internal_key.body" \
  -H "X-Gateway-Internal-Key: ${KEY_VALUE}" \
  "${GATEWAY_URL}/internal/routes" || true
head -n 25 "$TMP_DIR/internal_key.headers"
cat "$TMP_DIR/internal_key.body"

echo
echo "--- /internal/policy | key var ---"
curl -sS -D "$TMP_DIR/policy_key.headers" -o "$TMP_DIR/policy_key.body" \
  -H "X-Gateway-Internal-Key: ${KEY_VALUE}" \
  "${GATEWAY_URL}/internal/policy" || true
head -n 25 "$TMP_DIR/policy_key.headers"
cat "$TMP_DIR/policy_key.body"

echo
echo "===== STEP 8 - GATEWAY LOG SON 40 ====="
journalctl -u "$SERVICE_NAME" -n 40 --no-pager || true

echo
echo "OK ✅ GW-INTERNAL-KEY-FIX-1 script bitti"
