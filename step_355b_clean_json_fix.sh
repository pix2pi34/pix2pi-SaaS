#!/bin/bash
set -e

FILE="/root/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go"
BIN="/root/pix2pi/pix2pi-SaaS/bin/service-watchdog"

echo "=== STEP 355B / CLEAN JSON FIX ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. struct rewrite (guaranteed)..."

cat <<'GOEOF' > /tmp/json_patch.go
package main

type ServiceStatus struct {
	Name       string `json:"name"`
	Status     string `json:"status"`
	Method     string `json:"method"`
	Detail     string `json:"detail"`
	ResponseMS int64  `json:"response_ms"`
	CheckedAt  string `json:"checked_at"`
}

type StatusResponse struct {
	GlobalStatus string          `json:"global_status"`
	UpdatedAt    string          `json:"updated_at"`
	Services     []ServiceStatus `json:"services"`
}
GOEOF

echo "OK ✅ struct hazir"

echo
echo "3. eski struct replace..."

# Eski struct bloklarını sil
sed -i '/type ServiceStatus {/,/}/d' "$FILE"
sed -i '/type StatusResponse {/,/}/d' "$FILE"

# Yeni struct başa ekle
cat /tmp/json_patch.go | cat - "$FILE" > /tmp/new.go
mv /tmp/new.go "$FILE"

echo "OK ✅ struct replace edildi"

echo
echo "4. build..."

cd /root/pix2pi/pix2pi-SaaS
go build -o "$BIN" ./cmd/service-watchdog

echo "OK ✅ build"

echo
echo "5. restart..."

pkill service-watchdog || true
"$BIN" &

sleep 2

echo "OK ✅ restart"

echo
echo "6. test..."

curl -s http://127.0.0.1:8090/status | head -c 500
echo

echo
echo "OK ✅ step 355B tamam"
