CREATE SCHEMA IF NOT EXISTS erp_party;

CREATE TABLE IF NOT EXISTS erp_party.parties (
  party_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  party_code TEXT NOT NULL,
  party_type TEXT NOT NULL CHECK (party_type IN ('customer','supplier','both')),
  display_name TEXT NOT NULL,
  tax_identity TEXT NOT NULL DEFAULT '',
  tax_office TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  address_line TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  country TEXT NOT NULL DEFAULT 'TR',
  opening_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
  current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active',
  created_by_user_id TEXT NOT NULL,
  updated_by_user_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, party_code)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_party_tenant_country_tax
  ON erp_party.parties(tenant_id, country, lower(tax_identity))
  WHERE tax_identity <> '';

CREATE TABLE IF NOT EXISTS erp_party.party_movements (
  movement_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  party_id TEXT NOT NULL,
  movement_type TEXT NOT NULL,
  movement_direction TEXT NOT NULL CHECK (movement_direction IN ('debit','credit')),
  amount NUMERIC(18,2) NOT NULL CHECK (amount >= 0),
  balance_after NUMERIC(18,2) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  source_ref TEXT NOT NULL DEFAULT '',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_erp_party_movements_tenant_party
  ON erp_party.party_movements(tenant_id, party_id, created_at DESC);

CREATE TABLE IF NOT EXISTS erp_party.party_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  party_id TEXT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_erp_party_audit_tenant
  ON erp_party.party_audit_events(tenant_id, event_type, decision, created_at DESC);
