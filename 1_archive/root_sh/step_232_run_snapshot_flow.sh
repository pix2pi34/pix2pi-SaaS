#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

pkill -f stock_service || true

nohup go run ./cmd/stock-service >/tmp/pix2pi_stock_service.log 2>&1 &
sleep 2
cat /tmp/pix2pi_stock_service.log

curl -s -X POST http://127.0.0.1:9012/replay \
-H "Content-Type: application/json" \
-d '{"subject":"pix2pi.sale.created","data":"{\"event\":\"sale.created\",\"sale_id\":\"S-SNAP-1\",\"tenant_id\":\"tenant-001\",\"amount\":1300}"}'

echo
echo "---- SNAPSHOT ----"
PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -c "SELECT tenant_id, aggregate_type, aggregate_id, version, state FROM snapshots ORDER BY id DESC LIMIT 3;"

echo "OK ✅ snapshot flow bitti"
