CREATE SCHEMA IF NOT EXISTS pilot_runtime;

CREATE TABLE IF NOT EXISTS pilot_runtime.pilot_customer_tenant_openings (
  opening_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  pilot_customer_code TEXT NOT NULL,
  pilot_customer_name TEXT NOT NULL,
  opening_status TEXT NOT NULL DEFAULT 'draft',
  access_status TEXT NOT NULL DEFAULT 'inactive',
  commercial_status TEXT NOT NULL DEFAULT 'pending',
  legal_status TEXT NOT NULL DEFAULT 'pending',
  owner_user_id TEXT NOT NULL DEFAULT '',
  plan_code TEXT NOT NULL DEFAULT '',
  subscription_id TEXT NOT NULL DEFAULT '',
  paid_invoice_id TEXT NOT NULL DEFAULT '',
  entitlement_status TEXT NOT NULL DEFAULT '',
  opened_by_user_id TEXT NOT NULL,
  opened_at TIMESTAMPTZ NULL,
  activated_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS pilot_runtime.pilot_tenant_legal_commercial_bindings (
  binding_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  opening_id TEXT NOT NULL,
  legal_status TEXT NOT NULL,
  kvkk_status TEXT NOT NULL,
  commercial_status TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  paid_invoice_id TEXT NOT NULL,
  entitlement_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS pilot_runtime.pilot_tenant_owner_bindings (
  owner_binding_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  opening_id TEXT NOT NULL,
  owner_user_id TEXT NOT NULL,
  owner_email TEXT NOT NULL DEFAULT '',
  owner_role_status TEXT NOT NULL,
  owner_access_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS pilot_runtime.pilot_tenant_access_activations (
  activation_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  opening_id TEXT NOT NULL,
  owner_user_id TEXT NOT NULL,
  activation_status TEXT NOT NULL,
  panel_access_status TEXT NOT NULL,
  pos_access_status TEXT NOT NULL,
  entitlement_ui_status TEXT NOT NULL,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS pilot_runtime.pilot_tenant_opening_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  opening_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pilot_openings_run
  ON pilot_runtime.pilot_customer_tenant_openings(run_id, tenant_id, opening_status);

CREATE INDEX IF NOT EXISTS idx_pilot_legal_commercial_run
  ON pilot_runtime.pilot_tenant_legal_commercial_bindings(run_id, tenant_id, commercial_status);

CREATE INDEX IF NOT EXISTS idx_pilot_owner_bindings_run
  ON pilot_runtime.pilot_tenant_owner_bindings(run_id, tenant_id, owner_access_status);

CREATE INDEX IF NOT EXISTS idx_pilot_access_activations_run
  ON pilot_runtime.pilot_tenant_access_activations(run_id, tenant_id, activation_status);

CREATE INDEX IF NOT EXISTS idx_pilot_opening_audit_run
  ON pilot_runtime.pilot_tenant_opening_audit_events(run_id, event_type, decision);
