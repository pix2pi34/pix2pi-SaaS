#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
REPORT_DIR="${ROOT_DIR}/reports"
STAMP="$(date +%Y%m%d_%H%M%S)"
TXT_REPORT="${REPORT_DIR}/api_gateway_final_close_${STAMP}.txt"
MD_REPORT="${REPORT_DIR}/api_gateway_final_close_${STAMP}.md"
LATEST_TXT="${REPORT_DIR}/api_gateway_final_close_latest.txt"
LATEST_MD="${REPORT_DIR}/api_gateway_final_close_latest.md"

SERVICE_NAME="pix2pi-api-gateway.service"
GATEWAY_URL="http://127.0.0.1:9010"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

PASS_COUNT=0
FAIL_COUNT=0

log_ok() {
  echo "OK ✅ $1" | tee -a "${TXT_REPORT}"
  PASS_COUNT=$((PASS_COUNT + 1))
}

log_fail() {
  echo "HATA ❌ $1" | tee -a "${TXT_REPORT}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

write_section() {
  echo | tee -a "${TXT_REPORT}"
  echo "===== $1 =====" | tee -a "${TXT_REPORT}"
}

http_status() {
  local file="$1"
  awk 'BEGIN{code=""} /^HTTP\/[0-9.]+/ {code=$2} END{print code}' "$file"
}

echo "API GATEWAY FINAL CLOSE BASLIYOR" > "${TXT_REPORT}"
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S')" >> "${TXT_REPORT}"
echo "Root: ${ROOT_DIR}" >> "${TXT_REPORT}"
echo "Gateway URL: ${GATEWAY_URL}" >> "${TXT_REPORT}"

write_section "STEP 1 - GATEWAY BUILD"
if go build ./cmd/api-gateway >> "${TXT_REPORT}" 2>&1; then
  log_ok "gateway build basarili"
else
  log_fail "gateway build patladi"
fi

write_section "STEP 2 - CMD TEST"
if go test ./cmd/api-gateway -v >> "${TXT_REPORT}" 2>&1; then
  log_ok "cmd api-gateway test basarili"
else
  log_fail "cmd api-gateway test patladi"
fi

write_section "STEP 3 - INTERNAL TEST"
if go test ./internal/platform/gateway/... -v >> "${TXT_REPORT}" 2>&1; then
  log_ok "internal platform gateway test basarili"
else
  log_fail "internal platform gateway test patladi"
fi

write_section "STEP 4 - ENV ANAHTAR KONTROL"
INTERNAL_KEY="$(grep -E '^GATEWAY_INTERNAL_KEY=' "${ENV_FILE}" | tail -n 1 | cut -d= -f2- || true)"
if [ -n "${INTERNAL_KEY}" ]; then
  echo "GATEWAY_INTERNAL_KEY=${INTERNAL_KEY}" >> "${TXT_REPORT}"
  log_ok "gateway internal key bulundu"
else
  log_fail "gateway internal key bulunamadi"
fi

write_section "STEP 5 - SERVICE DURUM"
systemctl --no-pager --full status "${SERVICE_NAME}" | head -n 20 >> "${TXT_REPORT}" 2>&1 || true
if systemctl is-active --quiet "${SERVICE_NAME}"; then
  log_ok "gateway service aktif"
else
  log_fail "gateway service aktif degil"
fi

write_section "STEP 6 - HEALTH LIVE"
curl -sS -D "${TMP_DIR}/health.headers" -o "${TMP_DIR}/health.body" \
  "${GATEWAY_URL}/health/live" >> /dev/null 2>&1 || true
cat "${TMP_DIR}/health.headers" >> "${TXT_REPORT}"
cat "${TMP_DIR}/health.body" >> "${TXT_REPORT}"
HEALTH_CODE="$(http_status "${TMP_DIR}/health.headers")"
if [ "${HEALTH_CODE}" = "200" ]; then
  log_ok "health live 200"
else
  log_fail "health live beklenen 200 yerine ${HEALTH_CODE:-bos}"
fi

write_section "STEP 7 - API ME JWT BLOK"
curl -sS -D "${TMP_DIR}/api_me.headers" -o "${TMP_DIR}/api_me.body" \
  "${GATEWAY_URL}/api/me" >> /dev/null 2>&1 || true
cat "${TMP_DIR}/api_me.headers" >> "${TXT_REPORT}"
cat "${TMP_DIR}/api_me.body" >> "${TXT_REPORT}"
API_ME_CODE="$(http_status "${TMP_DIR}/api_me.headers")"
if [ "${API_ME_CODE}" = "401" ]; then
  log_ok "api me jwt olmadan 401"
else
  log_fail "api me beklenen 401 yerine ${API_ME_CODE:-bos}"
fi

write_section "STEP 8 - INTERNAL ROUTES KEY YOK"
curl -sS -D "${TMP_DIR}/internal_no_key.headers" -o "${TMP_DIR}/internal_no_key.body" \
  "${GATEWAY_URL}/internal/routes" >> /dev/null 2>&1 || true
cat "${TMP_DIR}/internal_no_key.headers" >> "${TXT_REPORT}"
cat "${TMP_DIR}/internal_no_key.body" >> "${TXT_REPORT}"
INTERNAL_NO_KEY_CODE="$(http_status "${TMP_DIR}/internal_no_key.headers")"
if [ "${INTERNAL_NO_KEY_CODE}" = "403" ]; then
  log_ok "internal routes key yokken 403"
else
  log_fail "internal routes key yok beklenen 403 yerine ${INTERNAL_NO_KEY_CODE:-bos}"
fi

write_section "STEP 9 - INTERNAL ROUTES KEY VAR"
if [ -n "${INTERNAL_KEY}" ]; then
  curl -sS -D "${TMP_DIR}/internal_key.headers" -o "${TMP_DIR}/internal_key.body" \
    -H "X-Gateway-Internal-Key: ${INTERNAL_KEY}" \
    "${GATEWAY_URL}/internal/routes" >> /dev/null 2>&1 || true
  cat "${TMP_DIR}/internal_key.headers" >> "${TXT_REPORT}"
  cat "${TMP_DIR}/internal_key.body" >> "${TXT_REPORT}"
  INTERNAL_KEY_CODE="$(http_status "${TMP_DIR}/internal_key.headers")"
  if [ "${INTERNAL_KEY_CODE}" = "200" ]; then
    log_ok "internal routes key varken 200"
  else
    log_fail "internal routes key var beklenen 200 yerine ${INTERNAL_KEY_CODE:-bos}"
  fi
else
  log_fail "internal routes key var testi atlandi cunku key bos"
fi

write_section "STEP 10 - INTERNAL POLICY KEY VAR"
if [ -n "${INTERNAL_KEY}" ]; then
  curl -sS -D "${TMP_DIR}/policy_key.headers" -o "${TMP_DIR}/policy_key.body" \
    -H "X-Gateway-Internal-Key: ${INTERNAL_KEY}" \
    "${GATEWAY_URL}/internal/policy" >> /dev/null 2>&1 || true
  cat "${TMP_DIR}/policy_key.headers" >> "${TXT_REPORT}"
  cat "${TMP_DIR}/policy_key.body" >> "${TXT_REPORT}"
  POLICY_KEY_CODE="$(http_status "${TMP_DIR}/policy_key.headers")"
  if [ "${POLICY_KEY_CODE}" = "200" ]; then
    log_ok "internal policy key varken 200"
  else
    log_fail "internal policy key var beklenen 200 yerine ${POLICY_KEY_CODE:-bos}"
  fi
else
  log_fail "internal policy key var testi atlandi cunku key bos"
fi

write_section "STEP 11 - LOG SON 40"
journalctl -u "${SERVICE_NAME}" -n 40 --no-pager >> "${TXT_REPORT}" 2>&1 || true
log_ok "gateway log son 40 eklendi"

write_section "STEP 12 - FINAL OZET"
echo "PASS_COUNT=${PASS_COUNT}" | tee -a "${TXT_REPORT}"
echo "FAIL_COUNT=${FAIL_COUNT}" | tee -a "${TXT_REPORT}"

{
  echo "# API Gateway Final Close Report"
  echo
  echo "- Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "- Root: ${ROOT_DIR}"
  echo "- Gateway URL: ${GATEWAY_URL}"
  echo "- Service: ${SERVICE_NAME}"
  echo "- Gecen: ${PASS_COUNT}"
  echo "- Hata: ${FAIL_COUNT}"
  echo
  echo "## Final Sonuc"
  if [ "${FAIL_COUNT}" -eq 0 ]; then
    echo "**BASARILI ✅**"
  else
    echo "**HATALI ❌**"
  fi
  echo
  echo "## Kontrol Ozetleri"
  echo "- gateway build"
  echo "- cmd api-gateway test"
  echo "- internal platform gateway test"
  echo "- env internal key kontrolu"
  echo "- service aktiflik kontrolu"
  echo "- /health/live = 200"
  echo "- /api/me jwt yok = 401"
  echo "- /internal/routes key yok = 403"
  echo "- /internal/routes key var = 200"
  echo "- /internal/policy key var = 200"
  echo "- journalctl son 40"
} > "${MD_REPORT}"

cp "${TXT_REPORT}" "${LATEST_TXT}"
cp "${MD_REPORT}" "${LATEST_MD}"

echo | tee -a "${TXT_REPORT}"
echo "TXT RAPOR: ${TXT_REPORT}" | tee -a "${TXT_REPORT}"
echo "MD RAPOR : ${MD_REPORT}" | tee -a "${TXT_REPORT}"

if [ "${FAIL_COUNT}" -eq 0 ]; then
  echo "OK ✅ GW-FINAL-CLOSE-1 basarili" | tee -a "${TXT_REPORT}"
  exit 0
else
  echo "HATA ❌ GW-FINAL-CLOSE-1 hata ile bitti" | tee -a "${TXT_REPORT}"
  exit 1
fi
