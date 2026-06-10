BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;

CREATE OR REPLACE FUNCTION platform.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS platform.mission_control_action_logs (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  mission_control_action_log_id TEXT NOT NULL,
  action_type TEXT NOT NULL,
  action_status TEXT NOT NULL DEFAULT 'REQUESTED',
  target_type TEXT NOT NULL,
  target_ref TEXT NOT NULL,
  target_service_key TEXT,
  target_instance_ref TEXT,
  operator_ref TEXT,
  actor_type TEXT NOT NULL DEFAULT 'SYSTEM',
  decision TEXT NOT NULL DEFAULT 'AUDIT_ONLY',
  priority INTEGER NOT NULL DEFAULT 100,
  request_id TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  idempotency_key TEXT,
  action_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  result_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  CONSTRAINT mission_control_action_logs_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT mission_control_action_logs_id_chk CHECK (length(trim(mission_control_action_log_id)) > 0),
  CONSTRAINT mission_control_action_logs_action_type_chk CHECK (length(trim(action_type)) > 0),
  CONSTRAINT mission_control_action_logs_target_type_chk CHECK (
    target_type IN ('SERVICE', 'INSTANCE', 'TENANT', 'JOB', 'WEBHOOK', 'PLUGIN', 'WORKFLOW', 'SYSTEM')
  ),
  CONSTRAINT mission_control_action_logs_actor_type_chk CHECK (
    actor_type IN ('SYSTEM', 'SERVICE', 'WORKER', 'OPERATOR', 'USER')
  ),
  CONSTRAINT mission_control_action_logs_status_chk CHECK (
    action_status IN ('REQUESTED', 'APPROVED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELED', 'DENIED')
  ),
  CONSTRAINT mission_control_action_logs_decision_chk CHECK (
    decision IN ('ALLOW', 'DENY', 'REQUIRE_APPROVAL', 'AUDIT_ONLY')
  ),
  CONSTRAINT mission_control_action_logs_priority_chk CHECK (priority >= 0),
  CONSTRAINT mission_control_action_logs_tenant_action_uq UNIQUE (tenant_id, mission_control_action_log_id)
);

CREATE TABLE IF NOT EXISTS platform.incident_logs (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  incident_log_id TEXT NOT NULL,
  incident_key TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'SEV3',
  incident_status TEXT NOT NULL DEFAULT 'OPEN',
  source_type TEXT NOT NULL,
  source_ref TEXT NOT NULL,
  service_key TEXT,
  service_instance_ref TEXT,
  affected_tenant_id TEXT,
  title TEXT NOT NULL,
  description TEXT,
  owner_ref TEXT,
  detected_by TEXT NOT NULL DEFAULT 'system',
  acknowledged_by TEXT,
  resolved_by TEXT,
  closed_by TEXT,
  request_id TEXT,
  correlation_id TEXT,
  impact_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  detection_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  root_cause_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  remediation_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  CONSTRAINT incident_logs_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT incident_logs_id_chk CHECK (length(trim(incident_log_id)) > 0),
  CONSTRAINT incident_logs_key_chk CHECK (length(trim(incident_key)) > 0),
  CONSTRAINT incident_logs_title_chk CHECK (length(trim(title)) > 0),
  CONSTRAINT incident_logs_severity_chk CHECK (
    severity IN ('SEV0', 'SEV1', 'SEV2', 'SEV3', 'SEV4')
  ),
  CONSTRAINT incident_logs_status_chk CHECK (
    incident_status IN ('OPEN', 'ACKNOWLEDGED', 'MITIGATING', 'RESOLVED', 'CLOSED', 'CANCELED')
  ),
  CONSTRAINT incident_logs_source_type_chk CHECK (
    source_type IN ('SERVICE', 'INSTANCE', 'DB', 'EVENT_BUS', 'WEBHOOK', 'JOB', 'PLUGIN', 'WORKFLOW', 'SECURITY', 'SYSTEM')
  ),
  CONSTRAINT incident_logs_tenant_incident_uq UNIQUE (tenant_id, incident_log_id),
  CONSTRAINT incident_logs_tenant_incident_key_uq UNIQUE (tenant_id, incident_key)
);

CREATE TABLE IF NOT EXISTS platform.maintenance_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  maintenance_state_id TEXT NOT NULL,
  maintenance_key TEXT NOT NULL,
  maintenance_type TEXT NOT NULL,
  maintenance_status TEXT NOT NULL DEFAULT 'SCHEDULED',
  target_type TEXT NOT NULL,
  target_ref TEXT NOT NULL,
  service_key TEXT,
  service_instance_ref TEXT,
  reason TEXT NOT NULL,
  approval_status TEXT NOT NULL DEFAULT 'NOT_REQUIRED',
  approved_by TEXT,
  created_by TEXT NOT NULL DEFAULT 'system',
  started_by TEXT,
  completed_by TEXT,
  canceled_by TEXT,
  notification_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  maintenance_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  result_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  window_start_at TIMESTAMPTZ NOT NULL,
  window_end_at TIMESTAMPTZ NOT NULL,
  approved_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  CONSTRAINT maintenance_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT maintenance_states_id_chk CHECK (length(trim(maintenance_state_id)) > 0),
  CONSTRAINT maintenance_states_key_chk CHECK (length(trim(maintenance_key)) > 0),
  CONSTRAINT maintenance_states_reason_chk CHECK (length(trim(reason)) > 0),
  CONSTRAINT maintenance_states_type_chk CHECK (
    maintenance_type IN ('DEPLOY', 'DB_MIGRATION', 'BACKUP', 'RESTORE', 'NETWORK', 'SECURITY', 'SYSTEM')
  ),
  CONSTRAINT maintenance_states_status_chk CHECK (
    maintenance_status IN ('SCHEDULED', 'APPROVED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELED')
  ),
  CONSTRAINT maintenance_states_target_type_chk CHECK (
    target_type IN ('SERVICE', 'INSTANCE', 'TENANT', 'DB', 'EVENT_BUS', 'EDGE', 'SYSTEM')
  ),
  CONSTRAINT maintenance_states_approval_status_chk CHECK (
    approval_status IN ('NOT_REQUIRED', 'PENDING', 'APPROVED', 'REJECTED')
  ),
  CONSTRAINT maintenance_states_window_chk CHECK (window_end_at > window_start_at),
  CONSTRAINT maintenance_states_tenant_state_uq UNIQUE (tenant_id, maintenance_state_id),
  CONSTRAINT maintenance_states_tenant_key_uq UNIQUE (tenant_id, maintenance_key)
);

CREATE TABLE IF NOT EXISTS platform.quarantine_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  quarantine_state_id TEXT NOT NULL,
  quarantine_key TEXT NOT NULL,
  quarantine_type TEXT NOT NULL,
  quarantine_status TEXT NOT NULL DEFAULT 'ACTIVE',
  target_type TEXT NOT NULL,
  target_ref TEXT NOT NULL,
  service_key TEXT,
  service_instance_ref TEXT,
  severity TEXT NOT NULL DEFAULT 'HIGH',
  reason_code TEXT NOT NULL,
  reason TEXT NOT NULL,
  isolated_by TEXT NOT NULL DEFAULT 'system',
  released_by TEXT,
  release_reason TEXT,
  request_id TEXT,
  correlation_id TEXT,
  evidence_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  isolation_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  release_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  isolated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  released_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  CONSTRAINT quarantine_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT quarantine_states_id_chk CHECK (length(trim(quarantine_state_id)) > 0),
  CONSTRAINT quarantine_states_key_chk CHECK (length(trim(quarantine_key)) > 0),
  CONSTRAINT quarantine_states_reason_code_chk CHECK (length(trim(reason_code)) > 0),
  CONSTRAINT quarantine_states_reason_chk CHECK (length(trim(reason)) > 0),
  CONSTRAINT quarantine_states_type_chk CHECK (
    quarantine_type IN ('SECURITY', 'HEALTH', 'BACKLOG', 'TENANT_RISK', 'PLUGIN_RISK', 'WEBHOOK_RISK', 'SYSTEM')
  ),
  CONSTRAINT quarantine_states_status_chk CHECK (
    quarantine_status IN ('ACTIVE', 'RELEASE_REQUESTED', 'RELEASED', 'EXPIRED', 'CANCELED')
  ),
  CONSTRAINT quarantine_states_target_type_chk CHECK (
    target_type IN ('SERVICE', 'INSTANCE', 'TENANT', 'API_KEY', 'PLUGIN', 'WEBHOOK', 'JOB', 'SYSTEM')
  ),
  CONSTRAINT quarantine_states_severity_chk CHECK (
    severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
  ),
  CONSTRAINT quarantine_states_tenant_state_uq UNIQUE (tenant_id, quarantine_state_id),
  CONSTRAINT quarantine_states_tenant_key_uq UNIQUE (tenant_id, quarantine_key)
);

CREATE TABLE IF NOT EXISTS platform.operator_actions (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  operator_action_id TEXT NOT NULL,
  mission_control_action_log_id BIGINT REFERENCES platform.mission_control_action_logs(id) ON DELETE SET NULL,
  incident_log_id BIGINT REFERENCES platform.incident_logs(id) ON DELETE SET NULL,
  maintenance_state_id BIGINT REFERENCES platform.maintenance_states(id) ON DELETE SET NULL,
  quarantine_state_id BIGINT REFERENCES platform.quarantine_states(id) ON DELETE SET NULL,
  operator_ref TEXT NOT NULL,
  action_type TEXT NOT NULL,
  action_scope TEXT NOT NULL DEFAULT 'TENANT',
  target_type TEXT NOT NULL,
  target_ref TEXT NOT NULL,
  decision TEXT NOT NULL DEFAULT 'ALLOW',
  risk_level TEXT NOT NULL DEFAULT 'MEDIUM',
  action_status TEXT NOT NULL DEFAULT 'RECORDED',
  reason TEXT NOT NULL,
  approval_ref TEXT,
  break_glass_session_ref TEXT,
  request_id TEXT,
  correlation_id TEXT,
  idempotency_key TEXT,
  action_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  result_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  audit_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  performed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  CONSTRAINT operator_actions_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT operator_actions_id_chk CHECK (length(trim(operator_action_id)) > 0),
  CONSTRAINT operator_actions_operator_ref_chk CHECK (length(trim(operator_ref)) > 0),
  CONSTRAINT operator_actions_action_type_chk CHECK (length(trim(action_type)) > 0),
  CONSTRAINT operator_actions_reason_chk CHECK (length(trim(reason)) > 0),
  CONSTRAINT operator_actions_scope_chk CHECK (
    action_scope IN ('GLOBAL', 'TENANT', 'SERVICE', 'INSTANCE', 'INCIDENT', 'MAINTENANCE', 'QUARANTINE')
  ),
  CONSTRAINT operator_actions_target_type_chk CHECK (
    target_type IN ('SERVICE', 'INSTANCE', 'TENANT', 'INCIDENT', 'MAINTENANCE', 'QUARANTINE', 'JOB', 'WEBHOOK', 'PLUGIN', 'SYSTEM')
  ),
  CONSTRAINT operator_actions_decision_chk CHECK (
    decision IN ('ALLOW', 'DENY', 'REQUIRE_APPROVAL', 'AUDIT_ONLY')
  ),
  CONSTRAINT operator_actions_risk_level_chk CHECK (
    risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
  ),
  CONSTRAINT operator_actions_status_chk CHECK (
    action_status IN ('RECORDED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELED', 'DENIED')
  ),
  CONSTRAINT operator_actions_tenant_action_uq UNIQUE (tenant_id, operator_action_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_mission_control_action_logs_tenant_idempotency
  ON platform.mission_control_action_logs (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mission_control_action_logs_tenant_status
  ON platform.mission_control_action_logs (tenant_id, action_status);

CREATE INDEX IF NOT EXISTS idx_mission_control_action_logs_target
  ON platform.mission_control_action_logs (tenant_id, target_type, target_ref);

CREATE INDEX IF NOT EXISTS idx_mission_control_action_logs_operator
  ON platform.mission_control_action_logs (tenant_id, operator_ref)
  WHERE operator_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mission_control_action_logs_correlation
  ON platform.mission_control_action_logs (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mission_control_action_logs_created_at
  ON platform.mission_control_action_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_incident_logs_tenant_status
  ON platform.incident_logs (tenant_id, incident_status);

CREATE INDEX IF NOT EXISTS idx_incident_logs_tenant_severity
  ON platform.incident_logs (tenant_id, severity, incident_status);

CREATE INDEX IF NOT EXISTS idx_incident_logs_service
  ON platform.incident_logs (tenant_id, service_key, incident_status)
  WHERE service_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_incident_logs_detected_at
  ON platform.incident_logs (detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_incident_logs_correlation
  ON platform.incident_logs (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_incident_logs_affected_tenant
  ON platform.incident_logs (tenant_id, affected_tenant_id)
  WHERE affected_tenant_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_maintenance_states_tenant_status
  ON platform.maintenance_states (tenant_id, maintenance_status);

CREATE INDEX IF NOT EXISTS idx_maintenance_states_window
  ON platform.maintenance_states (tenant_id, window_start_at, window_end_at);

CREATE INDEX IF NOT EXISTS idx_maintenance_states_target
  ON platform.maintenance_states (tenant_id, target_type, target_ref);

CREATE INDEX IF NOT EXISTS idx_maintenance_states_service
  ON platform.maintenance_states (tenant_id, service_key)
  WHERE service_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_maintenance_states_approval
  ON platform.maintenance_states (tenant_id, approval_status);

CREATE INDEX IF NOT EXISTS idx_quarantine_states_tenant_status
  ON platform.quarantine_states (tenant_id, quarantine_status);

CREATE INDEX IF NOT EXISTS idx_quarantine_states_target
  ON platform.quarantine_states (tenant_id, target_type, target_ref);

CREATE INDEX IF NOT EXISTS idx_quarantine_states_service
  ON platform.quarantine_states (tenant_id, service_key)
  WHERE service_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_quarantine_states_severity
  ON platform.quarantine_states (tenant_id, severity, quarantine_status);

CREATE INDEX IF NOT EXISTS idx_quarantine_states_expires_at
  ON platform.quarantine_states (expires_at)
  WHERE expires_at IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_operator_actions_tenant_idempotency
  ON platform.operator_actions (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_operator_actions_operator
  ON platform.operator_actions (tenant_id, operator_ref, performed_at DESC);

CREATE INDEX IF NOT EXISTS idx_operator_actions_target
  ON platform.operator_actions (tenant_id, target_type, target_ref);

CREATE INDEX IF NOT EXISTS idx_operator_actions_status
  ON platform.operator_actions (tenant_id, action_status);

CREATE INDEX IF NOT EXISTS idx_operator_actions_risk
  ON platform.operator_actions (tenant_id, risk_level, performed_at DESC);

CREATE INDEX IF NOT EXISTS idx_operator_actions_incident
  ON platform.operator_actions (tenant_id, incident_log_id)
  WHERE incident_log_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_operator_actions_correlation
  ON platform.operator_actions (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

DROP TRIGGER IF EXISTS trg_mission_control_action_logs_updated_at ON platform.mission_control_action_logs;
CREATE TRIGGER trg_mission_control_action_logs_updated_at
BEFORE UPDATE ON platform.mission_control_action_logs
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_incident_logs_updated_at ON platform.incident_logs;
CREATE TRIGGER trg_incident_logs_updated_at
BEFORE UPDATE ON platform.incident_logs
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_maintenance_states_updated_at ON platform.maintenance_states;
CREATE TRIGGER trg_maintenance_states_updated_at
BEFORE UPDATE ON platform.maintenance_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_quarantine_states_updated_at ON platform.quarantine_states;
CREATE TRIGGER trg_quarantine_states_updated_at
BEFORE UPDATE ON platform.quarantine_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_operator_actions_updated_at ON platform.operator_actions;
CREATE TRIGGER trg_operator_actions_updated_at
BEFORE UPDATE ON platform.operator_actions
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.mission_control_action_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.incident_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.operator_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.maintenance_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.quarantine_states ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.mission_control_action_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.incident_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.operator_actions FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.maintenance_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.quarantine_states FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mission_control_action_logs_tenant_isolation ON platform.mission_control_action_logs;
CREATE POLICY mission_control_action_logs_tenant_isolation
ON platform.mission_control_action_logs
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS incident_logs_tenant_isolation ON platform.incident_logs;
CREATE POLICY incident_logs_tenant_isolation
ON platform.incident_logs
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS operator_actions_tenant_isolation ON platform.operator_actions;
CREATE POLICY operator_actions_tenant_isolation
ON platform.operator_actions
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS maintenance_states_tenant_isolation ON platform.maintenance_states;
CREATE POLICY maintenance_states_tenant_isolation
ON platform.maintenance_states
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS quarantine_states_tenant_isolation ON platform.quarantine_states;
CREATE POLICY quarantine_states_tenant_isolation
ON platform.quarantine_states
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

COMMENT ON TABLE platform.mission_control_action_logs IS 'FAZ 2-6.2 mission control action log persistence table.';
COMMENT ON TABLE platform.incident_logs IS 'FAZ 2-6.2 incident log persistence table.';
COMMENT ON TABLE platform.operator_actions IS 'FAZ 2-6.2 operator action persistence table.';
COMMENT ON TABLE platform.maintenance_states IS 'FAZ 2-6.2 maintenance state persistence table.';
COMMENT ON TABLE platform.quarantine_states IS 'FAZ 2-6.2 quarantine state persistence table.';

COMMIT;
