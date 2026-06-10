CREATE SCHEMA IF NOT EXISTS controlled_release;

CREATE TABLE IF NOT EXISTS controlled_release.customer_access_activations (
  activation_id TEXT PRIMARY KEY,
  decision_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  access_status TEXT NOT NULL,
  access_mode TEXT NOT NULL,
  panel_enabled BOOLEAN NOT NULL DEFAULT false,
  pos_enabled BOOLEAN NOT NULL DEFAULT false,
  marketplace_enabled BOOLEAN NOT NULL DEFAULT false,
  localization_enabled BOOLEAN NOT NULL DEFAULT false,
  data_mutation_scope TEXT NOT NULL,
  activation_window_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  activation_window_end TIMESTAMPTZ NOT NULL,
  activated_by TEXT NOT NULL,
  activated_at TIMESTAMPTZ NULL,
  deactivated_at TIMESTAMPTZ NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS controlled_release.customer_access_activation_scopes (
  scope_id TEXT PRIMARY KEY,
  activation_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  surface TEXT NOT NULL,
  route_path TEXT NOT NULL,
  action_scope TEXT NOT NULL,
  scope_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS controlled_release.customer_access_activation_audit_events (
  event_id TEXT PRIMARY KEY,
  activation_id TEXT NOT NULL,
  decision_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_access_activations_tenant
  ON controlled_release.customer_access_activations(tenant_id, access_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_customer_access_activation_scopes_activation
  ON controlled_release.customer_access_activation_scopes(activation_id, surface, scope_status);

CREATE INDEX IF NOT EXISTS idx_customer_access_activation_audit
  ON controlled_release.customer_access_activation_audit_events(activation_id, event_type, created_at DESC);
