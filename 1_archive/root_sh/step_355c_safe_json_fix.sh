#!/bin/bash
set -e

FILE="/root/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go"
BIN="/root/pix2pi/pix2pi-SaaS/bin/service-watchdog"

echo "=== STEP 355C / SAFE JSON FIX ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. json tag ekleniyor..."

sed -i 's/Name[[:space:]]\+string/Name string `json:"name"`/g' "$FILE"
sed -i 's/Status[[:space:]]\+string/Status string `json:"status"`/g' "$FILE"
sed -i 's/Method[[:space:]]\+string/Method string `json:"method"`/g' "$FILE"
sed -i 's/Detail[[:space:]]\+string/Detail string `json:"detail"`/g' "$FILE"
sed -i 's/ResponseMS[[:space:]]\+int64/ResponseMS int64 `json:"response_ms"`/g' "$FILE"
sed -i 's/CheckedAt[[:space:]]\+string/CheckedAt string `json:"checked_at"`/g' "$FILE"

sed -i 's/Services[[:space:]]\+\[\]ServiceStatus/Services []ServiceStatus `json:"services"`/g' "$FILE"
sed -i 's/UpdatedAt[[:space:]]\+string/UpdatedAt string `json:"updated_at"`/g' "$FILE"
sed -i 's/GlobalStatus[[:space:]]\+string/GlobalStatus string `json:"global_status"`/g' "$FILE"

echo "OK ✅ json tag eklendi"

echo
echo "3. build..."

cd /root/pix2pi/pix2pi-SaaS
go build -o "$BIN" ./cmd/service-watchdog

echo "OK ✅ build tamam"

echo
echo "4. restart..."

pkill service-watchdog || true
"$BIN" &

sleep 2

echo "OK ✅ restart"

echo
echo "5. test..."

curl -s http://127.0.0.1:8090/status | head -c 500
echo

echo
echo "OK ✅ step 355C tamam"
