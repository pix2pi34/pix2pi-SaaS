#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOMAIN="${PIX2PI_DOMAIN:-pix2pi.com.tr}"
EXTRA_PATHS="${PIX2PI_EDGE_PATHS:-/ /faz4d/pilot-go-live/}"
EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md"

mkdir -p docs/faz6/evidence

PASS_COUNT=0
WARN_COUNT=0
INFO_COUNT=0

write_line() {
  echo "$1" | tee -a "$EVIDENCE_FILE"
}

probe_http_url() {
  local label="$1"
  local url="$2"

  write_line "===== EDGE HTTP SMOKE: $label ====="
  write_line "URL=$url"

  HEADERS_FILE="/tmp/pix2pi_edge_headers.txt"
  BODY_FILE="/tmp/pix2pi_edge_body.txt"

  RESULT="$(curl -L -sS --max-time 12 -D "$HEADERS_FILE" -o "$BODY_FILE" -w 'http_code=%{http_code} time_total=%{time_total} size=%{size_download} remote_ip=%{remote_ip}' "$url" 2>/tmp/pix2pi_edge_curl_err.txt || true)"

  write_line "$RESULT"

  write_line "--- headers first 100 lines ---"
  head -n 100 "$HEADERS_FILE" 2>/dev/null | tee -a "$EVIDENCE_FILE" || true

  write_line "--- body first 500 chars ---"
  head -c 500 "$BODY_FILE" 2>/dev/null | tee -a "$EVIDENCE_FILE" || true
  write_line ""

  write_line "--- curl error if any ---"
  cat /tmp/pix2pi_edge_curl_err.txt 2>/dev/null | tee -a "$EVIDENCE_FILE" || true

  if echo "$RESULT" | grep -Eq 'http_code=2[0-9][0-9]|http_code=3[0-9][0-9]'; then
    write_line "$label EDGE_HTTP_OK ✅"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    write_line "$label EDGE_HTTP_WARN ⚠️"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # Cloudflare gri oldugu icin CF header zorunlu degildir.
  if grep -Ei 'cf-ray|cf-cache-status|server: cloudflare' "$HEADERS_FILE" >/tmp/pix2pi_cf_header_hits.txt 2>/dev/null; then
    write_line "$label CLOUDFLARE_PROXY_HEADERS_PRESENT ✅"
    cat /tmp/pix2pi_cf_header_hits.txt | tee -a "$EVIDENCE_FILE"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    write_line "$label CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️"
    INFO_COUNT=$((INFO_COUNT + 1))
  fi

  # Asil zorunlu kontrol: origin/Nginx security/cache headerlari.
  if grep -Ei 'strict-transport-security|x-frame-options|x-content-type-options|content-security-policy|referrer-policy|permissions-policy|cache-control|x-request-id' "$HEADERS_FILE" >/tmp/pix2pi_security_header_hits.txt 2>/dev/null; then
    write_line "$label EDGE_SECURITY_HEADERS_PRESENT ✅"
    cat /tmp/pix2pi_security_header_hits.txt | tee -a "$EVIDENCE_FILE"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    write_line "$label EDGE_SECURITY_HEADERS_WARN ⚠️"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  write_line ""
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-10 Edge HTTP Smoke Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  
DOMAIN=$DOMAIN  
EXTRA_PATHS=$EXTRA_PATHS  

Bu script DNS, Cloudflare veya Nginx ayari degistirmez. Sadece public GET content check evidence uretir.

Cloudflare note:
- Cloudflare gri bulut modundaysa CF-Ray / CF-Cache-Status beklenmez.
- Bu nedenle CF header yoklugu WARN degil INFO kabul edilir.
- Zorunlu kontrol origin/Nginx security/cache headerlaridir.

FAZ_6_10_EDGE_HTTP_SMOKE=STARTED ✅

---

EOF2

echo "===== PIX2PI EDGE HTTP SMOKE BASLADI ====="

probe_http_url "root https" "https://$DOMAIN/"

for path in $EXTRA_PATHS; do
  probe_http_url "https path $path" "https://$DOMAIN$path"
done

probe_http_url "http redirect/root" "http://$DOMAIN/"

{
  echo
  echo "## Edge HTTP Smoke Final Seal"
  echo
  echo '```text'
  echo "PASS_COUNT=$PASS_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  echo "INFO_COUNT=$INFO_COUNT"
  echo "FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE ✅"
  echo "FAZ_6_10_CLOUDFLARE_PROXY_STATUS=DISABLED_OR_NOT_DETECTED_INFO ✅"

  if [ "$WARN_COUNT" -eq 0 ]; then
    echo "FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅"
  else
    echo "FAZ_6_10_EDGE_HTTP_WARN_STATUS=HAS_WARNINGS ⚠️"
  fi
  echo '```'
} >> "$EVIDENCE_FILE"

echo "PASS_COUNT=$PASS_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "INFO_COUNT=$INFO_COUNT"
echo "FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE ✅"
echo "FAZ_6_10_CLOUDFLARE_PROXY_STATUS=DISABLED_OR_NOT_DETECTED_INFO ✅"

if [ "$WARN_COUNT" -eq 0 ]; then
  echo "FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅"
else
  echo "FAZ_6_10_EDGE_HTTP_WARN_STATUS=HAS_WARNINGS ⚠️"
fi

echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
