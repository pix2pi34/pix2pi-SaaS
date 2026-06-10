#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/backups/gateway_edge_bind_fix/$STAMP"
REPORT_DIR="$ROOT/reports"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

MAIN_GO="cmd/api-gateway/api_gateway_main.go"
MAIN_TEST="cmd/api-gateway/api_gateway_main_test.go"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"

TXT_REPORT="$REPORT_DIR/gw_edge_2_fix_${STAMP}.txt"
LATEST_REPORT="$REPORT_DIR/gw_edge_2_fix_latest.txt"

echo "===== STEP 1 - ON KONTROL ====="
test -f "$MAIN_GO"
test -f "$MAIN_TEST"
test -f "$ENV_FILE"
echo "OK ✅ gerekli dosyalar bulundu"

echo
echo "===== STEP 2 - YEDEK ====="
cp "$MAIN_GO" "$BACKUP_DIR/api_gateway_main.go.bak"
cp "$MAIN_TEST" "$BACKUP_DIR/api_gateway_main_test.go.bak"
cp "$ENV_FILE" "$BACKUP_DIR/common.env.bak"
echo "OK ✅ yedekler alindi: $BACKUP_DIR"

echo
echo "===== STEP 3 - PATCH ====="
python3 <<'PY'
from pathlib import Path
import re

main_path = Path("/root/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go")
test_path = Path("/root/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main_test.go")
env_path = Path("/opt/pix2pi/orchestrator/env/common.env")

main = main_path.read_text()
test = test_path.read_text()
env = env_path.read_text()

# 1) import bloguna net ekle
m = re.search(r'import\s*\((.*?)\n\)', main, re.S)
if not m:
    raise RuntimeError("import blogu bulunamadi")

import_block = m.group(1)
if '"net"' not in import_block:
    new_block = import_block + '\n\t"net"'
    main = main[:m.start(1)] + new_block + main[m.end(1):]

# 2) helper fonksiyonlarini ekle
helper_code = '''

func gatewayBindAddr() string {
\tbindAddr := strings.TrimSpace(os.Getenv("GATEWAY_BIND_ADDR"))
\tif bindAddr == "" {
\t\treturn "127.0.0.1"
\t}
\treturn bindAddr
}

func gatewayListenAddrFromPort(port string) string {
\tcleanPort := strings.TrimSpace(port)
\tif cleanPort == "" {
\t\tcleanPort = "9010"
\t}
\treturn net.JoinHostPort(gatewayBindAddr(), cleanPort)
}
'''

if "func gatewayBindAddr() string {" not in main:
    main = main.replace("func main() {", helper_code + "\nfunc main() {", 1)

# 3) ListenAndServe satirini localhost bind olacak sekilde degistir
patterns = [
    (
        r'err\s*:=\s*http\.ListenAndServe\(\s*":"\s*\+\s*port\s*,\s*handler\s*\)',
        'listenAddr := gatewayListenAddrFromPort(port)\n\terr := http.ListenAndServe(listenAddr, handler)'
    ),
    (
        r'err\s*:=\s*http\.ListenAndServe\(\s*":"\s*\+\s*port\s*,\s*rootHandler\s*\)',
        'listenAddr := gatewayListenAddrFromPort(port)\n\terr := http.ListenAndServe(listenAddr, rootHandler)'
    ),
    (
        r'err\s*:=\s*http\.ListenAndServe\(\s*":"\s*\+\s*port\s*,\s*mux\s*\)',
        'listenAddr := gatewayListenAddrFromPort(port)\n\terr := http.ListenAndServe(listenAddr, mux)'
    ),
]

replaced = False
for pattern, repl in patterns:
    new_main, count = re.subn(pattern, repl, main, count=1)
    if count == 1:
        main = new_main
        replaced = True
        break

if not replaced:
    raise RuntimeError('http.ListenAndServe(":"+port, ...) kalibi bulunamadi')

# 4) log ciktisini daha net yap
main = main.replace("running on :%s", "running on %s")
main = main.replace("running on :%v", "running on %v")

# 5) test ekle
test_code = '''

func TestGatewayListenAddrFromPortDefaultBind(t *testing.T) {
\tt.Setenv("GATEWAY_BIND_ADDR", "")
\tgot := gatewayListenAddrFromPort("9010")
\twant := "127.0.0.1:9010"
\tif got != want {
\t\tt.Fatalf("beklenen %s, gelen %s", want, got)
\t}
}

func TestGatewayListenAddrFromPortUsesEnvBind(t *testing.T) {
\tt.Setenv("GATEWAY_BIND_ADDR", "127.0.0.1")
\tgot := gatewayListenAddrFromPort("9901")
\twant := "127.0.0.1:9901"
\tif got != want {
\t\tt.Fatalf("beklenen %s, gelen %s", want, got)
\t}
}
'''

if "func TestGatewayListenAddrFromPortDefaultBind(t *testing.T)" not in test:
    test = test.rstrip() + "\n" + test_code + "\n"

# 6) env dosyasina bind addr ekle/guncelle
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

env = "\n".join(new_lines) + "\n"

main_path.write_text(main)
test_path.write_text(test)
env_path.write_text(env)
PY

echo "OK ✅ patch uygulandi"

echo
echo "===== STEP 4 - KOD KANITI ====="
grep -n "func gatewayBindAddr" "$MAIN_GO"
grep -n "func gatewayListenAddrFromPort" "$MAIN_GO"
grep -n "ListenAndServe" "$MAIN_GO" | tail -n 5
grep -n "GATEWAY_BIND_ADDR" "$ENV_FILE"
echo "OK ✅ kod kaniti alindi"

echo
echo "===== STEP 5 - GOFMT ====="
gofmt -w "$MAIN_GO" "$MAIN_TEST"
echo "OK ✅ gofmt tamam"

echo
echo "===== STEP 6 - TEST ====="
go test ./cmd/api-gateway -v
echo "OK ✅ cmd/api-gateway test tamam"

echo
echo "===== STEP 7 - BUILD ====="
go build -o pix2pi-api-gateway ./cmd/api-gateway
echo "OK ✅ gateway build tamam"

echo
echo "===== STEP 8 - RESTART ====="
systemctl restart pix2pi-api-gateway
sleep 2
systemctl status pix2pi-api-gateway --no-pager | sed -n '1,20p'
echo "OK ✅ gateway restart tamam"

echo
echo "===== STEP 9 - BIND KONTROL ====="
ss -lntp | grep -E '(:9010[[:space:]]|:9010$)' || true

echo
echo "===== STEP 10 - CANLI TEST ====="
echo "--- LOCAL /health/live ---"
curl -i --max-time 5 http://127.0.0.1:9010/health/live || true
echo
echo "--- PUBLIC /health/live ---"
curl -k -i --max-time 10 https://pix2pi.com.tr/health/live || true
echo
echo "--- PUBLIC /api/me ---"
curl -k -i --max-time 10 https://pix2pi.com.tr/api/me || true

echo
echo "===== STEP 11 - RAPOR ====="
{
  echo "GW EDGE 2 FIX REPORT"
  echo "Tarih: $(date)"
  echo
  echo "[STEP 4]"
  grep -n "func gatewayBindAddr" "$MAIN_GO" || true
  grep -n "func gatewayListenAddrFromPort" "$MAIN_GO" || true
  grep -n "ListenAndServe" "$MAIN_GO" | tail -n 5 || true
  grep -n "GATEWAY_BIND_ADDR" "$ENV_FILE" || true
  echo
  echo "[STEP 9]"
  ss -lntp | grep -E '(:9010[[:space:]]|:9010$)' || true
  echo
  echo "[STEP 10 local]"
  curl -i --max-time 5 http://127.0.0.1:9010/health/live || true
  echo
  echo "[STEP 10 public health]"
  curl -k -i --max-time 10 https://pix2pi.com.tr/health/live || true
  echo
  echo "[STEP 10 public api me]"
  curl -k -i --max-time 10 https://pix2pi.com.tr/api/me || true
} > "$TXT_REPORT"

cp "$TXT_REPORT" "$LATEST_REPORT"
echo "OK ✅ rapor yazildi: $TXT_REPORT"
echo "OK ✅ latest rapor: $LATEST_REPORT"
echo "OK ✅ GW-EDGE-2-FIX bitti"
