#!/bin/bash

echo "=== STEP 409 / FIX API GATEWAY ==="

echo "1. backup..."
cp /opt/pix2pi/orchestrator/bin/run_api_gateway.sh /opt/pix2pi/orchestrator/bin/run_api_gateway.sh.bak_$(date +%s)
echo "OK ✅ backup"

echo "2. binary build..."
cd ~/pix2pi/pix2pi-SaaS
go build -o pix2pi-api-gateway cmd/api-gateway/api_gateway_main.go

if [ $? -ne 0 ]; then
  echo "❌ BUILD FAIL"
  exit 1
fi

echo "OK ✅ build"

echo "3. binary kopyalanıyor..."
cp pix2pi-api-gateway /opt/pix2pi/orchestrator/bin/
chmod +x /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway

echo "OK ✅ binary ready"

echo "4. run script fix..."

cat <<'INNER' > /opt/pix2pi/orchestrator/bin/run_api_gateway.sh
#!/bin/bash
exec /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway
INNER

chmod +x /opt/pix2pi/orchestrator/bin/run_api_gateway.sh

echo "OK ✅ run script fixed"

echo "5. daemon reload..."
systemctl daemon-reexec
systemctl daemon-reload

echo "6. restart service..."
systemctl restart pix2pi-api-gateway

sleep 2

echo "7. status check..."
systemctl status pix2pi-api-gateway | head -20

echo "8. port check..."
ss -tulnp | grep 9010 || echo "❌ port yok"

echo "=== STEP 409 TAMAM ==="
