CREATE SCHEMA IF NOT EXISTS controlled_release;

CREATE TABLE IF NOT EXISTS controlled_release.go_live_decisions (
  decision_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  decision_scope TEXT NOT NULL,
  decision_status TEXT NOT NULL,
  decision_result TEXT NOT NULL,
  access_mode TEXT NOT NULL,
  public_launch_allowed BOOLEAN NOT NULL DEFAULT false,
  controlled_usage_allowed BOOLEAN NOT NULL DEFAULT false,
  data_mutation_scope TEXT NOT NULL,
  rollback_ready BOOLEAN NOT NULL DEFAULT false,
  approved_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  decided_at TIMESTAMPTZ NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS controlled_release.go_live_gate_checks (
  gate_id TEXT PRIMARY KEY,
  decision_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  gate_code TEXT NOT NULL,
  gate_name TEXT NOT NULL,
  gate_status TEXT NOT NULL,
  evidence_ref TEXT NULL,
  evidence_detail JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS controlled_release.go_live_risk_register (
  risk_id TEXT PRIMARY KEY,
  decision_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  risk_code TEXT NOT NULL,
  severity TEXT NOT NULL,
  risk_status TEXT NOT NULL,
  mitigation TEXT NOT NULL,
  owner TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS controlled_release.go_live_decision_audit_events (
  event_id TEXT PRIMARY KEY,
  decision_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision_result TEXT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_go_live_gate_checks_decision
  ON controlled_release.go_live_gate_checks(decision_id, gate_status);

CREATE INDEX IF NOT EXISTS idx_go_live_risk_register_decision
  ON controlled_release.go_live_risk_register(decision_id, severity, risk_status);
