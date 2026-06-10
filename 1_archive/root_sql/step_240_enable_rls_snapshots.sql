ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshots FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS snapshots_tenant_policy ON snapshots;

CREATE POLICY snapshots_tenant_policy
ON snapshots
USING (tenant_id = current_setting('app.current_tenant', true))
WITH CHECK (tenant_id = current_setting('app.current_tenant', true));
