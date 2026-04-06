#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

cat <<'SQLEOF' > step_240_enable_rls_snapshots.sql
ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshots FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS snapshots_tenant_policy ON snapshots;

CREATE POLICY snapshots_tenant_policy
ON snapshots
USING (tenant_id = current_setting('app.current_tenant', true))
WITH CHECK (tenant_id = current_setting('app.current_tenant', true));
SQLEOF

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_240_enable_rls_snapshots.sql

echo "OK ✅ snapshots RLS aktif"
