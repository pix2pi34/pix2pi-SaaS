CREATE SCHEMA IF NOT EXISTS tenant_settings;

ALTER TABLE tenant_onboarding.business_onboardings
  ADD COLUMN IF NOT EXISTS tax_office TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS default_currency TEXT NOT NULL DEFAULT 'TRY',
  ADD COLUMN IF NOT EXISTS settings_revision INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE tenant_onboarding.tenant_configs
  ADD COLUMN IF NOT EXISTS business_name TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS tax_identity TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS tax_office TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS address_line TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS city TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS country TEXT NOT NULL DEFAULT 'TR',
  ADD COLUMN IF NOT EXISTS sector TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS default_currency TEXT NOT NULL DEFAULT 'TRY',
  ADD COLUMN IF NOT EXISTS settings_revision INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE tenant_onboarding.tenant_branches
  ADD COLUMN IF NOT EXISTS branch_name TEXT NOT NULL DEFAULT 'Merkez Şube',
  ADD COLUMN IF NOT EXISTS address_line TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS city TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE tenant_onboarding.tenant_registers
  ADD COLUMN IF NOT EXISTS register_code TEXT NOT NULL DEFAULT 'KASA-001',
  ADD COLUMN IF NOT EXISTS register_name TEXT NOT NULL DEFAULT 'Ana Kasa',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TABLE IF NOT EXISTS tenant_settings.business_settings_audit_events (
  event_id TEXT PRIMARY KEY,
  settings_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant_settings.business_settings_update_snapshots (
  snapshot_id TEXT PRIMARY KEY,
  settings_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  snapshot_code TEXT NOT NULL,
  snapshot_status TEXT NOT NULL,
  business_name TEXT NOT NULL DEFAULT '',
  tax_identity TEXT NOT NULL DEFAULT '',
  default_language TEXT NOT NULL DEFAULT '',
  default_currency TEXT NOT NULL DEFAULT '',
  branch_count INTEGER NOT NULL DEFAULT 0,
  register_count INTEGER NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_settings_audit_tenant
  ON tenant_settings.business_settings_audit_events(tenant_id, event_type, decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_business_settings_snapshot_run
  ON tenant_settings.business_settings_update_snapshots(settings_run_id, tenant_id, snapshot_code);
