#!/bin/bash
set -e

echo "=== tenant-001 goruntuleme ==="
PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
SELECT tenant_id, aggregate_type, aggregate_id, version
FROM snapshots
ORDER BY id DESC;
COMMIT;
SQLEOF

echo
echo "=== tenant-test goruntuleme ==="
PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-test';
SELECT tenant_id, aggregate_type, aggregate_id, version
FROM snapshots
ORDER BY id DESC;
COMMIT;
SQLEOF

echo
echo "=== tenant-001 baska tenant insert denemesi ==="
PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
VALUES (
  'tenant-hack',
  'stock',
  'HACK-1',
  1,
  '{"event":"hack"}',
  NOW()
);
COMMIT;
SQLEOF
