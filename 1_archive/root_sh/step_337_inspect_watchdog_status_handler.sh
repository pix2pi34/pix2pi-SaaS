#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== DOSYA VARLIK KONTROL ==="
ls -l cmd/service-watchdog/service_watchdog_main.go

echo
echo "=== /status GECEN SATIRLAR ==="
grep -n '"/status"\|/status' cmd/service-watchdog/service_watchdog_main.go || true

echo
echo "=== updated_at GECEN SATIRLAR ==="
grep -n 'updated_at' cmd/service-watchdog/service_watchdog_main.go || true

echo
echo "=== json encode / response GECEN SATIRLAR ==="
grep -n 'json.NewEncoder\|Encode(\|map\[string\]any\|map\[string\]interface{}\|WriteHeader\|Header().Set' cmd/service-watchdog/service_watchdog_main.go || true

echo
echo "=== ILK 260 SATIR ==="
nl -ba cmd/service-watchdog/service_watchdog_main.go | sed -n '1,260p'

echo
echo "OK ✅ inspect bitti"
