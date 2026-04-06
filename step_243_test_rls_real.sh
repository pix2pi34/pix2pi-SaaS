#!/bin/bash
set -e

echo "=== tenant-001 ==="
PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
SELECT tenant_id, aggregate_id FROM snapshots;
COMMIT;
SQLEOF

echo
echo "=== tenant-test ==="
PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-test';
SELECT tenant_id, aggregate_id FROM snapshots;
COMMIT;
SQLEOF

echo
echo "=== HACK TEST ==="
PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
VALUES ('tenant-hack','stock','X',1,'{}',NOW());
COMMIT;
SQLEOF
