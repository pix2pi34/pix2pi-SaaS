#!/bin/bash
set -e

FILE="/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go"

echo "=== STEP 355 / JSON NORMALIZE ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. struct fix..."

sed -i 's/Name string/Name string `json:"name"`/g' $FILE
sed -i 's/Status string/Status string `json:"status"`/g' $FILE
sed -i 's/CheckedAt string/CheckedAt string `json:"checked_at"`/g' $FILE

sed -i 's/Services \[\]/Services []/g' $FILE
sed -i 's/Services \[\]Service/Services []Service `json:"services"`/g' $FILE
sed -i 's/UpdatedAt string/UpdatedAt string `json:"updated_at"`/g' $FILE

echo "OK ✅ struct normalized"

echo
echo "3. rebuild..."

cd /pix2pi/pix2pi-SaaS
go build -o watchdog ./cmd/service-watchdog/

echo "OK ✅ build"

echo
echo "4. restart..."

pkill watchdog || true
./watchdog &

sleep 2

echo "OK ✅ restarted"

echo
echo "5. test..."

curl -s http://127.0.0.1:8090/status | jq .

echo
echo "OK ✅ step 355 tamam"
