#!/bin/bash
set -u

cd ~/pix2pi/pix2pi-SaaS

TS="$(date +%Y%m%d_%H%M%S)"
TXT="reports/api_gateway_final_suite_${TS}.txt"
MD="reports/api_gateway_final_suite_${TS}.md"
LATEST_TXT="reports/api_gateway_final_suite_latest.txt"
LATEST_MD="reports/api_gateway_final_suite_latest.md"

PASS_COUNT=0
FAIL_COUNT=0

export REDIS_ADDR="${REDIS_ADDR:-127.0.0.1:6379}"
export REDIS_KEY_PREFIX="${REDIS_KEY_PREFIX:-tenant}"
export REDIS_DEFAULT_TTL_SECONDS="${REDIS_DEFAULT_TTL_SECONDS:-120}"

run_step() {
  local title="$1"
  shift

  echo "============================================================" | tee -a "$TXT"
  echo "$title" | tee -a "$TXT"
  echo "============================================================" | tee -a "$TXT"

  if "$@" >>"$TXT" 2>&1; then
    echo "OK ✅ $title basarili" | tee -a "$TXT"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "HATA ❌ $title basarisiz" | tee -a "$TXT"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

: > "$TXT"

echo "API GATEWAY FINAL SUITE BASLIYOR" | tee -a "$TXT"
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$TXT"
echo "Root: $(pwd)" | tee -a "$TXT"
echo "Redis Addr: $REDIS_ADDR" | tee -a "$TXT"
echo "Redis Prefix: $REDIS_KEY_PREFIX" | tee -a "$TXT"
echo "Redis Default TTL: $REDIS_DEFAULT_TTL_SECONDS" | tee -a "$TXT"

run_step "GATEWAY BUILD" go build ./cmd/api-gateway
run_step "GATEWAY UNIT TEST" go test ./cmd/api-gateway -v
run_step "GATEWAY INTERNAL TEST" go test ./internal/platform/gateway/... -v
run_step "GATEWAY RATE LIMIT REDIS TEST" go run ./cmd/gateway-rate-limit-redis-test
run_step "GATEWAY QUOTA REDIS TEST" go run ./cmd/gateway-quota-redis-test

TOTAL_COUNT=$((PASS_COUNT + FAIL_COUNT))

cat <<EOF2 > "$MD"
# API Gateway Final Suite Report
- Tarih: $(date '+%Y-%m-%d %H:%M:%S')
- Klasor: \`$(pwd)\`
- Gecen: **$PASS_COUNT**
- Kalan/Hata: **$FAIL_COUNT**
- Toplam: **$TOTAL_COUNT**
> Genel sonuc: **$( [ "$FAIL_COUNT" -eq 0 ] && echo 'BASARILI ✅' || echo 'HATALI ❌' )**

## Test Ozeti
| Test | Durum |
|---|---|
| GATEWAY BUILD | $(grep -q "OK ✅ GATEWAY BUILD basarili" "$TXT" && echo OK || echo FAIL) |
| GATEWAY UNIT TEST | $(grep -q "OK ✅ GATEWAY UNIT TEST basarili" "$TXT" && echo OK || echo FAIL) |
| GATEWAY INTERNAL TEST | $(grep -q "OK ✅ GATEWAY INTERNAL TEST basarili" "$TXT" && echo OK || echo FAIL) |
| GATEWAY RATE LIMIT REDIS TEST | $(grep -q "OK ✅ GATEWAY RATE LIMIT REDIS TEST basarili" "$TXT" && echo OK || echo FAIL) |
| GATEWAY QUOTA REDIS TEST | $(grep -q "OK ✅ GATEWAY QUOTA REDIS TEST basarili" "$TXT" && echo OK || echo FAIL) |

## Redis Test Env
- REDIS_ADDR: \`$REDIS_ADDR\`
- REDIS_KEY_PREFIX: \`$REDIS_KEY_PREFIX\`
- REDIS_DEFAULT_TTL_SECONDS: \`$REDIS_DEFAULT_TTL_SECONDS\`
EOF2

cp "$TXT" "$LATEST_TXT"
cp "$MD" "$LATEST_MD"

echo "============================================================" | tee -a "$TXT"
echo "FINAL OZET" | tee -a "$TXT"
echo "============================================================" | tee -a "$TXT"
echo "Passed : $PASS_COUNT" | tee -a "$TXT"
echo "Failed : $FAIL_COUNT" | tee -a "$TXT"
echo "TXT    : $(pwd)/$TXT" | tee -a "$TXT"
echo "MD     : $(pwd)/$MD" | tee -a "$TXT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "OK ✅ API GATEWAY FINAL SUITE BASARILI" | tee -a "$TXT"
  exit 0
fi

echo "HATA ❌ API GATEWAY FINAL SUITE HATALI" | tee -a "$TXT"
exit 1
