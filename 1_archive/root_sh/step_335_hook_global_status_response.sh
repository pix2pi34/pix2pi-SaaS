#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== BACKUP ==="
cp cmd/service-watchdog/service_watchdog_main.go cmd/service-watchdog/service_watchdog_main.go.bak_step_335

echo
echo "=== PATCH STATUS RESPONSE ==="

python3 - <<'PY'
from pathlib import Path

p = Path("cmd/service-watchdog/service_watchdog_main.go")
s = p.read_text()

old = '''resp := map[string]any{
\t\t"services": services,
\t\t"updated_at": time.Now().Format(time.RFC3339),
\t}'''

new = '''globalStatus := calculateGlobalStatus(services)

\tresp := map[string]any{
\t\t"services": services,
\t\t"global_status": globalStatus,
\t\t"updated_at": time.Now().Format(time.RFC3339),
\t}'''

if old not in s:
    raise SystemExit("PATCH NOKTASI BULUNAMADI")

s = s.replace(old, new, 1)
p.write_text(s)
PY

echo "OK ✅ response hook eklendi"

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
echo "OK ✅ step_335 tamam"
