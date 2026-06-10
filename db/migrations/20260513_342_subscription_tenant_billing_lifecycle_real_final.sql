CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE IF NOT EXISTS commercial_runtime.tenant_subscriptions (
  subscription_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  assignment_id TEXT NOT NULL,
  subscription_status TEXT NOT NULL DEFAULT 'trial',
  billing_cycle TEXT NOT NULL DEFAULT 'monthly',
  currency TEXT NOT NULL DEFAULT 'TRY',
  recurring_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  trial_ends_at TIMESTAMPTZ NULL,
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end TIMESTAMPTZ NOT NULL DEFAULT now() + interval '30 days',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  canceled_at TIMESTAMPTZ NULL,
  cancel_reason TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.subscription_billing_periods (
  billing_period_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  period_key TEXT NOT NULL,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  period_status TEXT NOT NULL DEFAULT 'open',
  currency TEXT NOT NULL DEFAULT 'TRY',
  amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, subscription_id, period_key)
);

CREATE TABLE IF NOT EXISTS commercial_runtime.subscription_invoice_drafts (
  invoice_draft_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  billing_period_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  draft_status TEXT NOT NULL DEFAULT 'draft',
  currency TEXT NOT NULL DEFAULT 'TRY',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(tenant_id, billing_period_id)
);

CREATE TABLE IF NOT EXISTS commercial_runtime.subscription_lifecycle_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  subscription_id TEXT NULL,
  billing_period_id TEXT NULL,
  invoice_draft_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_tenant_status
  ON commercial_runtime.tenant_subscriptions(tenant_id, subscription_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_subscription_billing_periods_subscription
  ON commercial_runtime.subscription_billing_periods(tenant_id, subscription_id, period_key);

CREATE INDEX IF NOT EXISTS idx_subscription_invoice_drafts_subscription
  ON commercial_runtime.subscription_invoice_drafts(tenant_id, subscription_id, draft_status);

CREATE INDEX IF NOT EXISTS idx_subscription_lifecycle_audit_run
  ON commercial_runtime.subscription_lifecycle_audit_events(run_id, event_type, decision);
