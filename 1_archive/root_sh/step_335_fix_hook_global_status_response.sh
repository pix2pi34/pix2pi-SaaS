#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== BACKUP ==="
cp cmd/service-watchdog/service_watchdog_main.go cmd/service-watchdog/service_watchdog_main.go.bak_step_335_fix

echo
echo "=== PATCH ==="

python3 - <<'PY'
from pathlib import Path
import re

p = Path("cmd/service-watchdog/service_watchdog_main.go")
s = p.read_text()

if '"global_status"' in s:
    print("OK_ALREADY_PATCHED")
    raise SystemExit(0)

if 'calculateGlobalStatus(services)' not in s:
    s = s.replace(
        'resp := map[string]any{',
        'globalStatus := calculateGlobalStatus(services)\n\n\tresp := map[string]any{',
        1
    )

pattern = r'(\t\t"services":\s*services,\n)(\t\t"updated_at":\s*time\.Now\(\)\.Format\(time\.RFC3339\),)'
repl = r'\1\t\t"global_status": globalStatus,\n\2'

new_s, count = re.subn(pattern, repl, s, count=1)

if count != 1:
    raise SystemExit("PATCH_YERI_HALA_BULUNAMADI")

p.write_text(new_s)
print("OK_PATCH_APPLIED")
PY

echo "OK ✅ patch uygulandi"

echo
echo "=== BUILD ==="
go build -o bin/service-watchdog ./cmd/service-watchdog

echo
echo "=== RESTART ==="
systemctl restart pix2pi-watchdog
sleep 2

echo
echo "=== TEST ==="
curl -s http://127.0.0.1:8090/status

echo
echo "OK ✅ step_335 fix tamam"
