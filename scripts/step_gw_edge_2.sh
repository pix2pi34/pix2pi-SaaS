#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/backups/gateway_edge_bind/$STAMP"
REPORT_DIR="$ROOT/reports"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

TXT_REPORT="$REPORT_DIR/gw_edge_2_${STAMP}.txt"
LATEST_REPORT="$REPORT_DIR/gw_edge_2_latest.txt"

MAIN_GO="cmd/api-gateway/api_gateway_main.go"
MAIN_TEST="cmd/api-gateway/api_gateway_main_test.go"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

cp "$MAIN_GO" "$BACKUP_DIR/$(basename "$MAIN_GO").bak"
cp "$MAIN_TEST" "$BACKUP_DIR/$(basename "$MAIN_TEST").bak"
cp "$COMMON_ENV" "$BACKUP_DIR/common.env.bak"

python3 <<'PY'
from pathlib import Path
import re
import sys

main_path = Path("cmd/api-gateway/api_gateway_main.go")
test_path = Path("cmd/api-gateway/api_gateway_main_test.go")
env_path = Path("/opt/pix2pi/orchestrator/env/common.env")

main = main_path.read_text()
test = test_path.read_text()
env = env_path.read_text()

def find_block_end(text: str, start_idx: int) -> int:
    brace = 0
    started = False
    for i in range(start_idx, len(text)):
        ch = text[i]
        if ch == "{":
            brace += 1
            started = True
        elif ch == "}":
            brace -= 1
            if started and brace == 0:
                return i + 1
    raise RuntimeError("block sonu bulunamadi")

# import bloguna net ekle
imp = re.search(r'import \(\n(.*?)\n\)', main, re.S)
if not imp:
    raise RuntimeError("import blogu bulunamadi")

imports = imp.group(1).splitlines()
if '\t"net"' not in imports:
    imports.append('\t"net"')
    imports = sorted(imports)
    new_import_block = "import (\n" + "\n".join(imports) + "\n)"
    main = main[:imp.start()] + new_import_block + main[imp.end():]

# gatewayPort sonrasina helper ekle
if "func gatewayBindAddr() string {" not in main:
    marker = "func gatewayPort() string {"
    idx = main.find(marker)
    if idx == -1:
        raise RuntimeError("gatewayPort fonksiyonu bulunamadi")

    end_idx = find_block_end(main, idx)
    helper = """

func gatewayBindAddr() string {
\tbindAddr := strings.TrimSpace(os.Getenv("GATEWAY_BIND_ADDR"))
\tif bindAddr == "" {
\t\treturn "127.0.0.1"
\t}
\treturn bindAddr
}

func gatewayListenAddr() string {
\treturn net.JoinHostPort(gatewayBindAddr(), gatewayPort())
}
"""
    main = main[:end_idx] + helper + main[end_idx:]

# ListenAndServe degisimi
main, count = re.subn(
    r'err := http\.ListenAndServe\(":"\s*\+\s*port,\s*handler\)',
    'listenAddr := gatewayListenAddr()\n\terr := http.ListenAndServe(listenAddr, handler)',
    main,
    count=1,
)
if count == 0:
    main, count = re.subn(
        r'err := http\.ListenAndServe\(":"\s*\+\s*port,\s*([A-Za-z0-9_]+)\)',
        r'listenAddr := gatewayListenAddr()\n\terr := http.ListenAndServe(listenAddr, \1)',
        main,
        count=1,
    )
if count == 0:
    raise RuntimeError('ListenAndServe(":"+port, ...) kalibi bulunamadi')

# log mesaji
main = main.replace("running on :%s", "running on %s")

main_path.write_text(main)

# test ekle
if "func TestGatewayListenAddrDefaultsToLocalhost(t *testing.T)" not in test:
    addition = """

func TestGatewayListenAddrDefaultsToLocalhost(t *testing.T) {
\tt.Setenv("GATEWAY_BIND_ADDR", "")
\tt.Setenv("GATEWAY_PORT", "")
\tgot := gatewayListenAddr()
\twant := "127.0.0.1:9010"
\tif got != want {
\t\tt.Fatalf("beklenen %s, gelen %s", want, got)
\t}
}

func TestGatewayListenAddrUsesEnvValues(t *testing.T) {
\tt.Setenv("GATEWAY_BIND_ADDR", "127.0.0.1")
\tt.Setenv("GATEWAY_PORT", "9901")
\tgot := gatewayListenAddr()
\twant := "127.0.0.1:9901"
\tif got != want {
\t\tt.Fatalf("beklenen %s, gelen %s", want, got)
\t}
}
"""
    test = test.rstrip() + addition + "\n"
    test_path.write_text(test)

# env icine bind addr yaz
lines = env.splitlines()
found = False
new_lines = []
for line in lines:
    if line.startswith("GATEWAY_BIND_ADDR="):
        new_lines.append("GATEWAY_BIND_ADDR=127.0.0.1")
        found = True
    else:
        new_lines.append(line)

if not found:
    if new_lines and new_lines[-1].strip() != "":
        new_lines.append("")
    new_lines.append("GATEWAY_BIND_ADDR=127.0.0.1")

env_path.write_text("\n".join(new_lines) + "\n")
PY

{
  echo "===== STEP 1 - YEDEK ====="
  echo "OK ✅ backup dizini: $BACKUP_DIR"
  echo

  echo "===== STEP 2 - KOD KONTROL ====="
  grep -n "func gatewayBindAddr" "$MAIN_GO"
  grep -n "func gatewayListenAddr" "$MAIN_GO"
  grep -n "ListenAndServe" "$MAIN_GO" | tail -n 3
  grep -n "GATEWAY_BIND_ADDR" "$COMMON_ENV"
  echo

  echo "===== STEP 3 - GOFMT ====="
  gofmt -w "$MAIN_GO" "$MAIN_TEST"
  echo "OK ✅ gofmt tamam"
  echo

  echo "===== STEP 4 - TEST ====="
  go test ./cmd/api-gateway -v
  echo "OK ✅ cmd/api-gateway test tamam"
  echo

  echo "===== STEP 5 - BUILD ====="
  go build -o pix2pi-api-gateway ./cmd/api-gateway
  echo "OK ✅ gateway binary rebuild tamam"
  echo

  echo "===== STEP 6 - RESTART ====="
  systemctl restart pix2pi-api-gateway
  sleep 2
  systemctl status pix2pi-api-gateway --no-pager | sed -n '1,20p'
  echo "OK ✅ gateway restart tamam"
  echo

  echo "===== STEP 7 - BIND DOGRULAMA ====="
  ss -lntp | grep -E '(:9010[[:space:]]|:9010$)' || true
  echo

  echo "===== STEP 8 - CANLI HTTP ====="
  echo "--- local health ---"
  curl -i --max-time 5 http://127.0.0.1:9010/health/live || true
  echo
  echo "--- public health ---"
  curl -k -i --max-time 10 https://pix2pi.com.tr/health/live || true
  echo
  echo "--- public api me ---"
  curl -k -i --max-time 10 https://pix2pi.com.tr/api/me || true
  echo

  echo "===== STEP 9 - KARAR ====="
  SS_LINE="$(ss -lntp 2>/dev/null | grep -E '(:9010[[:space:]]|:9010$)' | head -n 1 || true)"
  echo "DINLEME_SATIRI=$SS_LINE"

  if echo "$SS_LINE" | grep -Eq '127\.0\.0\.1:9010'; then
    echo "OK ✅ 9010 localhost bind oldu"
  elif echo "$SS_LINE" | grep -Eq '\*:9010|0\.0\.0\.0:9010|\[::\]:9010'; then
    echo "HATA ❌ 9010 hala public bind"
  else
    echo "WARN ⚠️ 9010 bind satiri net degil"
  fi

  echo
  echo "===== STEP 10 - SON 30 LOG ====="
  journalctl -u pix2pi-api-gateway.service -n 30 --no-pager || true
} | tee "$TXT_REPORT"

cp "$TXT_REPORT" "$LATEST_REPORT"

echo
echo "OK ✅ rapor hazir: $TXT_REPORT"
echo "OK ✅ latest rapor: $LATEST_REPORT"
echo "OK ✅ GW-EDGE-2 bitti"
