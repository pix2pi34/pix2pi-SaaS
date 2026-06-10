CREATE SCHEMA IF NOT EXISTS tenant_onboarding;

CREATE TABLE IF NOT EXISTS tenant_onboarding.business_onboardings (
  onboarding_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL UNIQUE,
  requested_by_user_id TEXT NOT NULL,
  business_name TEXT NOT NULL,
  tax_identity TEXT NOT NULL,
  address_line TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'TR',
  sector TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  default_currency TEXT NOT NULL,
  default_language TEXT NOT NULL,
  initial_role TEXT NOT NULL,
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ NULL,
  correlation_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT business_onboardings_tax_unique UNIQUE(country, tax_identity)
);

CREATE TABLE IF NOT EXISTS tenant_onboarding.tenant_configs (
  tenant_id TEXT PRIMARY KEY,
  tenant_slug TEXT NOT NULL UNIQUE,
  tenant_domain TEXT NOT NULL,
  environment TEXT NOT NULL,
  status TEXT NOT NULL,
  default_language TEXT NOT NULL,
  default_currency TEXT NOT NULL,
  default_timezone TEXT NOT NULL,
  default_plan TEXT NOT NULL,
  opened_by_user_id TEXT NOT NULL,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  correlation_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant_onboarding.tenant_branches (
  branch_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'TR',
  default_currency TEXT NOT NULL,
  default_language TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, branch_name)
);

CREATE TABLE IF NOT EXISTS tenant_onboarding.tenant_registers (
  register_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  branch_id TEXT NOT NULL,
  register_code TEXT NOT NULL,
  register_name TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, branch_id, register_code)
);

CREATE TABLE IF NOT EXISTS tenant_onboarding.tenant_user_roles (
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  role_code TEXT NOT NULL,
  assigned_by_user_id TEXT NOT NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(tenant_id, user_id, role_code)
);

CREATE TABLE IF NOT EXISTS tenant_onboarding.tenant_opening_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NULL,
  event_type TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_onboardings_requested_by
  ON tenant_onboarding.business_onboardings(requested_by_user_id);

CREATE INDEX IF NOT EXISTS idx_tenant_configs_status
  ON tenant_onboarding.tenant_configs(status, environment);

CREATE INDEX IF NOT EXISTS idx_tenant_opening_audit_tenant
  ON tenant_onboarding.tenant_opening_audit_events(tenant_id, created_at DESC);
