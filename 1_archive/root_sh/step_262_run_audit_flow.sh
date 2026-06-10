#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

pkill -f accounting_service || true

nohup go run ./cmd/accounting-service >/tmp/pix2pi_accounting.log 2>&1 &
sleep 2
cat /tmp/pix2pi_accounting.log

curl -s -X POST http://127.0.0.1:9012/replay \
-H "Content-Type: application/json" \
-d '{"subject":"pix2pi.sale.created","data":"{\"event\":\"sale.created\",\"sale_id\":\"S-AUDIT-REAL-1\",\"tenant_id\":\"tenant-001\",\"amount\":1700}"}'

echo
echo "---- AUDIT LOG ----"
PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -c "SELECT tenant_id, actor_id, action, entity_id, status FROM audit_logs ORDER BY id DESC LIMIT 5;"

echo "OK ✅ audit flow bitti"
