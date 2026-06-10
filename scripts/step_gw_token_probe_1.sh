#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/root/pix2pi/pix2pi-SaaS}"
cd "$ROOT_DIR"

PUBLIC_BASE_URL="${GW_PUBLIC_BASE_URL:-https://pix2pi.com.tr}"
OUT_DIR="$ROOT_DIR/tmp"
OUT_FILE="$OUT_DIR/gw_token_probe.env"
REPORT_FILE="$ROOT_DIR/reports/gw_token_probe_1_latest.txt"

mkdir -p "$OUT_DIR" "$ROOT_DIR/reports"

parse_token_and_tenant() {
  python3 - <<'PY'
import sys, json, re

raw = sys.stdin.read()
if not raw.strip():
    print("|")
    raise SystemExit(0)

jwt_match = re.search(r'([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)', raw)
if jwt_match:
    print(jwt_match.group(1) + "|")
    raise SystemExit(0)

def walk(x):
    if isinstance(x, dict):
        yield x
        for v in x.values():
            yield from walk(v)
    elif isinstance(x, list):
        for item in x:
            yield from walk(item)

try:
    obj = json.loads(raw)
except Exception:
    print("|")
    raise SystemExit(0)

token = ""
tenant = ""

token_keys = {"token", "access_token", "jwt", "bearer", "id_token"}
tenant_keys = {"tenant_id", "tenant_uuid", "tenant", "tenantId", "tenantUuid"}

for node in walk(obj):
    if isinstance(node, dict):
        for k, v in node.items():
            if not token and k in token_keys and isinstance(v, str) and v.count(".") >= 2:
                token = v.strip()
            if not tenant and k in tenant_keys and isinstance(v, str):
                tenant = v.strip()

print(f"{token}|{tenant}")
PY
}

echo "===== GW TOKEN PROBE 1 =====" | tee "$REPORT_FILE"
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')" | tee -a "$REPORT_FILE"
echo "Root: $ROOT_DIR" | tee -a "$REPORT_FILE"
echo "Public Base: $PUBLIC_BASE_URL" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

URLS=(
  "${GW_TOKEN_URL:-}"
  "${PUBLIC_BASE_URL}/dev/token"
  "${PUBLIC_BASE_URL}/api/dev/token"
  "http://127.0.0.1:8080/dev/token"
  "http://127.0.0.1:8080/api/dev/token"
  "http://127.0.0.1:9001/dev/token"
  "http://127.0.0.1:9001/api/dev/token"
  "http://127.0.0.1:9002/dev/token"
  "http://127.0.0.1:9002/api/dev/token"
  "http://127.0.0.1:9012/dev/token"
  "http://127.0.0.1:9012/api/dev/token"
)

SUFFIXES=(
  ""
  "?email=gwprobe@pix2pi.local"
  "?tenant_id=tenant-demo&email=gwprobe@pix2pi.local&role=admin"
  "?tenant=tenant-demo&email=gwprobe@pix2pi.local&role=admin"
  "?tenant_uuid=tenant-demo&email=gwprobe@pix2pi.local&role=admin"
)

FOUND_TOKEN=""
FOUND_TENANT=""

for url in "${URLS[@]}"; do
  [ -z "$url" ] && continue

  for suffix in "${SUFFIXES[@]}"; do
    full="${url}${suffix}"

    echo "DENE => $full" | tee -a "$REPORT_FILE"

    body="$(curl -ksS --max-time 8 "$full" 2>/dev/null || true)"
    if [ -z "$body" ]; then
      echo "WARN ⚠ bos cevap" | tee -a "$REPORT_FILE"
      echo | tee -a "$REPORT_FILE"
      continue
    fi

    parsed="$(printf '%s' "$body" | parse_token_and_tenant)"
    token="${parsed%%|*}"
    tenant="${parsed#*|}"

    if [ -n "$token" ]; then
      FOUND_TOKEN="$token"
      FOUND_TENANT="$tenant"

      {
        echo "export GW_TEST_BEARER='$FOUND_TOKEN'"
        if [ -n "$FOUND_TENANT" ]; then
          echo "export GW_TEST_TENANT_ID='$FOUND_TENANT'"
        fi
      } > "$OUT_FILE"

      echo "OK ✅ JWT bulundu: $full" | tee -a "$REPORT_FILE"
      if [ -n "$FOUND_TENANT" ]; then
        echo "OK ✅ tenant bulundu: $FOUND_TENANT" | tee -a "$REPORT_FILE"
      else
        echo "WARN ⚠ tenant bulunamadi" | tee -a "$REPORT_FILE"
      fi
      echo "OK ✅ env dosyasi yazildi: $OUT_FILE" | tee -a "$REPORT_FILE"
      echo | tee -a "$REPORT_FILE"
      echo "===== TOKEN DOSYASI =====" | tee -a "$REPORT_FILE"
      cat "$OUT_FILE" | tee -a "$REPORT_FILE"
      echo | tee -a "$REPORT_FILE"
      echo "OK ✅ GW-TOKEN-PROBE-1 bitti" | tee -a "$REPORT_FILE"
      exit 0
    fi

    echo "WARN ⚠ token cikmadi" | tee -a "$REPORT_FILE"
    echo | tee -a "$REPORT_FILE"
  done
done

echo "HATA ❌ hicbir endpointten JWT bulunamadi" | tee -a "$REPORT_FILE"
echo "IPUCU: elindeki tokeni manuel export ederek ana scripti tekrar calistiracagiz" | tee -a "$REPORT_FILE"
exit 1
