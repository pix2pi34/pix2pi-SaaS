#!/bin/bash
set -e

echo "=== FIXED TEST 3: cross-tenant insert bloklanmali ==="

cikti=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi 2>&1 <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
VALUES ('tenant-hack','stock','HACK-VERIFY',1,'{}',NOW());
COMMIT;
SQLEOF
)

echo "$cikti"

if echo "$cikti" | grep -qi "row-level security"; then
  echo "OK ✅ cross-tenant insert ENGELLENDI"
else
  echo "HATA ❌ RLS calismiyor"
  exit 1
fi
