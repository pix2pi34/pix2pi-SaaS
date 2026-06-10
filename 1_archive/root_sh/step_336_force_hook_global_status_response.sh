#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== BACKUP ==="
cp cmd/service-watchdog/service_watchdog_main.go cmd/service-watchdog/service_watchdog_main.go.bak_step_336_force

echo
echo "=== PATCH ==="

python3 - <<'PY'
from pathlib import Path

p = Path("cmd/service-watchdog/service_watchdog_main.go")
s = p.read_text()

if '"global_status"' in s:
    print("OK_ALREADY_PATCHED")
    raise SystemExit(0)

if 'calculateGlobalStatus(services)' not in s:
    marker = 'services := collectStatuses()'
    if marker in s:
        s = s.replace(
            marker,
            marker + '\n\tglobalStatus := calculateGlobalStatus(services)',
            1
        )
    else:
        marker = 'services := collectServiceStatuses()'
        if marker in s:
            s = s.replace(
                marker,
                marker + '\n\tglobalStatus := calculateGlobalStatus(services)',
                1
            )
        else:
            raise SystemExit("SERVICES_MARKER_BULUNAMADI")

needle = '"updated_at":'
idx = s.find(needle)
if idx == -1:
    raise SystemExit("UPDATED_AT_BULUNAMADI")

line_start = s.rfind('\n', 0, idx) + 1
indent = s[line_start:idx]

insert = indent + '"global_status": globalStatus,\n'
s = s[:line_start] + insert + s[line_start:]

p.write_text(s)
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
echo "OK ✅ step_336 force fix tamam"
