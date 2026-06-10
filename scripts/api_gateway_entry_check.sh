#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

NOW="$(date +%Y%m%d_%H%M%S)"
REPORT_TXT="reports/api_gateway_entry_check_${NOW}.txt"
LATEST_TXT="reports/api_gateway_entry_check_latest.txt"

pick_gateway_url() {
  local candidates=(
    "${GATEWAY_ENTRY_URL:-}"
    "http://127.0.0.1:${GATEWAY_PORT:-9010}"
    "http://127.0.0.1:8080"
  )

  for url in "${candidates[@]}"; do
    [ -z "$url" ] && continue
    code="$(curl -s -o /tmp/gw_entry_probe.out -w "%{http_code}" --max-time 2 "$url/health/live" || true)"
    if [ "$code" = "200" ] || [ "$code" = "503" ]; then
      echo "$url"
      return 0
    fi
  done

  return 1
}

assert_http_code() {
  local label="$1"
  local url="$2"
  local expected="$3"

  code="$(curl -s -o /tmp/gw_entry_check.out -w "%{http_code}" --max-time 3 "$url" || true)"

  if [ "$code" = "$expected" ]; then
    echo "OK ✅ ${label} | code=${code}"
  else
    echo "HATA ❌ ${label} | beklenen=${expected} gelen=${code}"
    return 1
  fi
}

assert_http_code_with_header() {
  local label="$1"
  local url="$2"
  local header_name="$3"
  local header_value="$4"
  local expected="$5"

  code="$(curl -s -H "${header_name}: ${header_value}" -o /tmp/gw_entry_check.out -w "%{http_code}" --max-time 3 "$url" || true)"

  if [ "$code" = "$expected" ]; then
    echo "OK ✅ ${label} | code=${code}"
  else
    echo "HATA ❌ ${label} | beklenen=${expected} gelen=${code}"
    return 1
  fi
}

{
  echo "API GATEWAY ENTRY CHECK BASLIYOR"
  echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Root: $ROOT_DIR"
  echo "============================================================"

  GATEWAY_URL="$(pick_gateway_url || true)"
  if [ -z "${GATEWAY_URL:-}" ]; then
    echo "HATA ❌ calisan gateway URL bulunamadi"
    exit 1
  fi

  echo "Gateway URL: $GATEWAY_URL"
  echo "============================================================"
  echo "ENTRY SURFACE HTTP CHECK"
  echo "============================================================"

  assert_http_code "health live public acik" "${GATEWAY_URL}/health/live" "200"
  assert_http_code "api me jwt olmadan bloklu" "${GATEWAY_URL}/api/me" "401"
  assert_http_code "internal routes key olmadan bloklu" "${GATEWAY_URL}/internal/routes" "403"
  assert_http_code "legacy root leak /query/users yok" "${GATEWAY_URL}/query/users" "404"
  assert_http_code "legacy root leak /policy yok" "${GATEWAY_URL}/policy" "404"
  assert_http_code "legacy root leak /me yok" "${GATEWAY_URL}/me" "404"

  if [ -n "${GATEWAY_INTERNAL_KEY:-}" ]; then
    assert_http_code_with_header \
      "internal routes dogru key ile acik" \
      "${GATEWAY_URL}/internal/routes" \
      "X-Gateway-Internal-Key" \
      "${GATEWAY_INTERNAL_KEY}" \
      "200"
  else
    echo "WARN ⚠️ GATEWAY_INTERNAL_KEY yok, 200 internal key kontrolu atlandi"
  fi

  echo "============================================================"
  echo "LISTENER OZETI"
  echo "============================================================"
  ss -lntp | grep -E '9010|8080|9002|9001|9101|pix2pi|gateway|identity|query' || true

  echo "============================================================"
  echo "SONUC"
  echo "============================================================"
  echo "OK ✅ api gateway entry check basarili"
} | tee "$REPORT_TXT"

cp "$REPORT_TXT" "$LATEST_TXT"

echo
echo "TXT: $REPORT_TXT"
echo "LATEST: $LATEST_TXT"
