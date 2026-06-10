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

CREATE TABLE IF NOT EXISTS platform.service_instances (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  service_instance_id TEXT NOT NULL,
  service_key TEXT NOT NULL,
  service_name TEXT NOT NULL,
  service_type TEXT NOT NULL DEFAULT 'API',
  environment TEXT NOT NULL DEFAULT 'PRODUCTION',
  instance_ref TEXT NOT NULL,
  host_name TEXT,
  ip_address INET,
  port INTEGER,
  protocol TEXT NOT NULL DEFAULT 'HTTP',
  base_url TEXT,
  version_label TEXT,
  deployment_ref TEXT,
  node_ref TEXT,
  region TEXT,
  zone TEXT,
  runtime_status TEXT NOT NULL DEFAULT 'REGISTERED',
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN',
  registration_source TEXT NOT NULL DEFAULT 'SYSTEM',
  last_seen_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  stopped_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_instances_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT service_instances_id_chk CHECK (length(trim(service_instance_id)) > 0),
  CONSTRAINT service_instances_service_key_chk CHECK (length(trim(service_key)) > 0),
  CONSTRAINT service_instances_service_name_chk CHECK (length(trim(service_name)) > 0),
  CONSTRAINT service_instances_instance_ref_chk CHECK (length(trim(instance_ref)) > 0),
  CONSTRAINT service_instances_type_chk CHECK (
    service_type IN ('API', 'WORKER', 'SCHEDULER', 'GATEWAY', 'PLUGIN', 'DATABASE', 'EVENT_BUS', 'SYSTEM')
  ),
  CONSTRAINT service_instances_environment_chk CHECK (
    environment IN ('DEVELOPMENT', 'STAGING', 'SANDBOX', 'PRODUCTION')
  ),
  CONSTRAINT service_instances_protocol_chk CHECK (
    protocol IN ('HTTP', 'HTTPS', 'GRPC', 'TCP', 'UDP', 'INTERNAL')
  ),
  CONSTRAINT service_instances_port_chk CHECK (
    port IS NULL OR (port > 0 AND port <= 65535)
  ),
  CONSTRAINT service_instances_runtime_status_chk CHECK (
    runtime_status IN ('REGISTERED', 'STARTING', 'RUNNING', 'STOPPING', 'STOPPED', 'FAILED', 'DRAINING', 'QUARANTINED', 'STALE')
  ),
  CONSTRAINT service_instances_health_status_chk CHECK (
    health_status IN ('UNKNOWN', 'HEALTHY', 'DEGRADED', 'UNHEALTHY', 'DOWN')
  ),
  CONSTRAINT service_instances_registration_source_chk CHECK (
    registration_source IN ('SYSTEM', 'DISCOVERY', 'MANUAL', 'DEPLOY', 'HEARTBEAT')
  ),
  CONSTRAINT service_instances_tenant_instance_uq UNIQUE (tenant_id, service_instance_id),
  CONSTRAINT service_instances_tenant_ref_uq UNIQUE (tenant_id, service_key, instance_ref)
);

CREATE TABLE IF NOT EXISTS platform.service_instance_heartbeats (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  service_heartbeat_id TEXT NOT NULL,
  service_instance_row_id BIGINT NOT NULL REFERENCES platform.service_instances(id) ON DELETE CASCADE,
  service_instance_id TEXT NOT NULL,
  service_key TEXT NOT NULL,
  heartbeat_status TEXT NOT NULL DEFAULT 'RECEIVED',
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN',
  observed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  latency_ms INTEGER,
  uptime_seconds BIGINT,
  cpu_usage_percent NUMERIC(6,2),
  memory_usage_bytes BIGINT,
  disk_usage_percent NUMERIC(6,2),
  backlog_count BIGINT,
  error_count BIGINT,
  heartbeat_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  request_id TEXT,
  correlation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_instance_heartbeats_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT service_instance_heartbeats_id_chk CHECK (length(trim(service_heartbeat_id)) > 0),
  CONSTRAINT service_instance_heartbeats_instance_id_chk CHECK (length(trim(service_instance_id)) > 0),
  CONSTRAINT service_instance_heartbeats_service_key_chk CHECK (length(trim(service_key)) > 0),
  CONSTRAINT service_instance_heartbeats_status_chk CHECK (
    heartbeat_status IN ('RECEIVED', 'LATE', 'MISSED', 'INVALID')
  ),
  CONSTRAINT service_instance_heartbeats_health_status_chk CHECK (
    health_status IN ('UNKNOWN', 'HEALTHY', 'DEGRADED', 'UNHEALTHY', 'DOWN')
  ),
  CONSTRAINT service_instance_heartbeats_latency_chk CHECK (latency_ms IS NULL OR latency_ms >= 0),
  CONSTRAINT service_instance_heartbeats_uptime_chk CHECK (uptime_seconds IS NULL OR uptime_seconds >= 0),
  CONSTRAINT service_instance_heartbeats_cpu_chk CHECK (
    cpu_usage_percent IS NULL OR (cpu_usage_percent >= 0 AND cpu_usage_percent <= 100)
  ),
  CONSTRAINT service_instance_heartbeats_memory_chk CHECK (memory_usage_bytes IS NULL OR memory_usage_bytes >= 0),
  CONSTRAINT service_instance_heartbeats_disk_chk CHECK (
    disk_usage_percent IS NULL OR (disk_usage_percent >= 0 AND disk_usage_percent <= 100)
  ),
  CONSTRAINT service_instance_heartbeats_backlog_chk CHECK (backlog_count IS NULL OR backlog_count >= 0),
  CONSTRAINT service_instance_heartbeats_error_count_chk CHECK (error_count IS NULL OR error_count >= 0),
  CONSTRAINT service_instance_heartbeats_tenant_heartbeat_uq UNIQUE (tenant_id, service_heartbeat_id)
);

CREATE TABLE IF NOT EXISTS platform.service_instance_metadata (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  service_metadata_id TEXT NOT NULL,
  service_instance_row_id BIGINT NOT NULL REFERENCES platform.service_instances(id) ON DELETE CASCADE,
  service_instance_id TEXT NOT NULL,
  service_key TEXT NOT NULL,
  metadata_key TEXT NOT NULL,
  metadata_type TEXT NOT NULL DEFAULT 'TEXT',
  metadata_value TEXT,
  metadata_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  visibility TEXT NOT NULL DEFAULT 'INTERNAL',
  is_sensitive BOOLEAN NOT NULL DEFAULT false,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_instance_metadata_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT service_instance_metadata_id_chk CHECK (length(trim(service_metadata_id)) > 0),
  CONSTRAINT service_instance_metadata_instance_id_chk CHECK (length(trim(service_instance_id)) > 0),
  CONSTRAINT service_instance_metadata_service_key_chk CHECK (length(trim(service_key)) > 0),
  CONSTRAINT service_instance_metadata_key_chk CHECK (length(trim(metadata_key)) > 0),
  CONSTRAINT service_instance_metadata_type_chk CHECK (
    metadata_type IN ('TEXT', 'NUMBER', 'BOOLEAN', 'JSON', 'URL', 'VERSION', 'CAPABILITY')
  ),
  CONSTRAINT service_instance_metadata_visibility_chk CHECK (
    visibility IN ('PRIVATE', 'INTERNAL', 'TENANT_VISIBLE', 'PUBLIC')
  ),
  CONSTRAINT service_instance_metadata_tenant_metadata_uq UNIQUE (tenant_id, service_metadata_id),
  CONSTRAINT service_instance_metadata_tenant_key_uq UNIQUE (tenant_id, service_instance_id, metadata_key)
);

CREATE TABLE IF NOT EXISTS platform.service_tenant_visibility (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  service_tenant_visibility_id TEXT NOT NULL,
  service_instance_row_id BIGINT NOT NULL REFERENCES platform.service_instances(id) ON DELETE CASCADE,
  service_instance_id TEXT NOT NULL,
  service_key TEXT NOT NULL,
  visible_tenant_id TEXT NOT NULL,
  visibility_status TEXT NOT NULL DEFAULT 'VISIBLE',
  access_mode TEXT NOT NULL DEFAULT 'INTERNAL',
  route_scope TEXT NOT NULL DEFAULT 'PRIVATE',
  allow_public BOOLEAN NOT NULL DEFAULT false,
  reason TEXT,
  effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  effective_until TIMESTAMPTZ,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_tenant_visibility_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT service_tenant_visibility_id_chk CHECK (length(trim(service_tenant_visibility_id)) > 0),
  CONSTRAINT service_tenant_visibility_instance_id_chk CHECK (length(trim(service_instance_id)) > 0),
  CONSTRAINT service_tenant_visibility_service_key_chk CHECK (length(trim(service_key)) > 0),
  CONSTRAINT service_tenant_visibility_visible_tenant_chk CHECK (length(trim(visible_tenant_id)) > 0),
  CONSTRAINT service_tenant_visibility_status_chk CHECK (
    visibility_status IN ('VISIBLE', 'HIDDEN', 'SUSPENDED', 'DENIED')
  ),
  CONSTRAINT service_tenant_visibility_access_mode_chk CHECK (
    access_mode IN ('PUBLIC', 'TENANT_ONLY', 'INTERNAL', 'ADMIN_ONLY')
  ),
  CONSTRAINT service_tenant_visibility_route_scope_chk CHECK (
    route_scope IN ('PUBLIC', 'PRIVATE', 'ADMIN', 'SYSTEM')
  ),
  CONSTRAINT service_tenant_visibility_window_chk CHECK (
    effective_until IS NULL OR effective_until > effective_from
  ),
  CONSTRAINT service_tenant_visibility_tenant_visibility_uq UNIQUE (tenant_id, service_tenant_visibility_id),
  CONSTRAINT service_tenant_visibility_tenant_service_visible_uq UNIQUE (tenant_id, service_instance_id, visible_tenant_id)
);

CREATE TABLE IF NOT EXISTS platform.service_stale_instance_markers (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  service_stale_instance_marker_id TEXT NOT NULL,
  service_instance_row_id BIGINT NOT NULL REFERENCES platform.service_instances(id) ON DELETE CASCADE,
  service_heartbeat_row_id BIGINT REFERENCES platform.service_instance_heartbeats(id) ON DELETE SET NULL,
  service_instance_id TEXT NOT NULL,
  service_key TEXT NOT NULL,
  stale_status TEXT NOT NULL DEFAULT 'ACTIVE',
  stale_reason TEXT NOT NULL,
  stale_threshold_seconds INTEGER NOT NULL DEFAULT 120,
  last_seen_at TIMESTAMPTZ,
  stale_detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  marked_by TEXT NOT NULL DEFAULT 'system',
  cleared_by TEXT,
  cleared_at TIMESTAMPTZ,
  marker_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_stale_instance_markers_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT service_stale_instance_markers_id_chk CHECK (length(trim(service_stale_instance_marker_id)) > 0),
  CONSTRAINT service_stale_instance_markers_instance_id_chk CHECK (length(trim(service_instance_id)) > 0),
  CONSTRAINT service_stale_instance_markers_service_key_chk CHECK (length(trim(service_key)) > 0),
  CONSTRAINT service_stale_instance_markers_reason_chk CHECK (length(trim(stale_reason)) > 0),
  CONSTRAINT service_stale_instance_markers_status_chk CHECK (
    stale_status IN ('ACTIVE', 'CLEARED', 'IGNORED', 'ESCALATED')
  ),
  CONSTRAINT service_stale_instance_markers_threshold_chk CHECK (stale_threshold_seconds > 0),
  CONSTRAINT service_stale_instance_markers_tenant_marker_uq UNIQUE (tenant_id, service_stale_instance_marker_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_service_stale_instance_markers_active_instance
  ON platform.service_stale_instance_markers (tenant_id, service_instance_id)
  WHERE stale_status IN ('ACTIVE', 'ESCALATED');

CREATE INDEX IF NOT EXISTS idx_service_instances_tenant_key_status
  ON platform.service_instances (tenant_id, service_key, runtime_status);

CREATE INDEX IF NOT EXISTS idx_service_instances_tenant_health
  ON platform.service_instances (tenant_id, health_status);

CREATE INDEX IF NOT EXISTS idx_service_instances_environment
  ON platform.service_instances (tenant_id, environment, service_type);

CREATE INDEX IF NOT EXISTS idx_service_instances_node
  ON platform.service_instances (tenant_id, node_ref)
  WHERE node_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_instances_region_zone
  ON platform.service_instances (tenant_id, region, zone)
  WHERE region IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_instances_last_seen
  ON platform.service_instances (last_seen_at DESC)
  WHERE last_seen_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_instances_updated_at
  ON platform.service_instances (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_service_instance_heartbeats_instance_observed
  ON platform.service_instance_heartbeats (tenant_id, service_instance_row_id, observed_at DESC);

CREATE INDEX IF NOT EXISTS idx_service_instance_heartbeats_service_observed
  ON platform.service_instance_heartbeats (tenant_id, service_key, observed_at DESC);

CREATE INDEX IF NOT EXISTS idx_service_instance_heartbeats_status
  ON platform.service_instance_heartbeats (tenant_id, heartbeat_status, observed_at DESC);

CREATE INDEX IF NOT EXISTS idx_service_instance_heartbeats_health
  ON platform.service_instance_heartbeats (tenant_id, health_status, observed_at DESC);

CREATE INDEX IF NOT EXISTS idx_service_instance_heartbeats_correlation
  ON platform.service_instance_heartbeats (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_instance_metadata_instance
  ON platform.service_instance_metadata (tenant_id, service_instance_row_id);

CREATE INDEX IF NOT EXISTS idx_service_instance_metadata_key
  ON platform.service_instance_metadata (tenant_id, metadata_key);

CREATE INDEX IF NOT EXISTS idx_service_instance_metadata_service_key
  ON platform.service_instance_metadata (tenant_id, service_key, metadata_key);

CREATE INDEX IF NOT EXISTS idx_service_instance_metadata_visibility
  ON platform.service_instance_metadata (tenant_id, visibility);

CREATE INDEX IF NOT EXISTS idx_service_instance_metadata_sensitive
  ON platform.service_instance_metadata (tenant_id, is_sensitive)
  WHERE is_sensitive = true;

CREATE INDEX IF NOT EXISTS idx_service_tenant_visibility_visible_tenant
  ON platform.service_tenant_visibility (tenant_id, visible_tenant_id, visibility_status);

CREATE INDEX IF NOT EXISTS idx_service_tenant_visibility_service
  ON platform.service_tenant_visibility (tenant_id, service_key, visibility_status);

CREATE INDEX IF NOT EXISTS idx_service_tenant_visibility_instance
  ON platform.service_tenant_visibility (tenant_id, service_instance_row_id);

CREATE INDEX IF NOT EXISTS idx_service_tenant_visibility_access_mode
  ON platform.service_tenant_visibility (tenant_id, access_mode, route_scope);

CREATE INDEX IF NOT EXISTS idx_service_tenant_visibility_effective_until
  ON platform.service_tenant_visibility (effective_until)
  WHERE effective_until IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_stale_instance_markers_status
  ON platform.service_stale_instance_markers (tenant_id, stale_status);

CREATE INDEX IF NOT EXISTS idx_service_stale_instance_markers_service
  ON platform.service_stale_instance_markers (tenant_id, service_key, stale_status);

CREATE INDEX IF NOT EXISTS idx_service_stale_instance_markers_instance
  ON platform.service_stale_instance_markers (tenant_id, service_instance_row_id);

CREATE INDEX IF NOT EXISTS idx_service_stale_instance_markers_detected
  ON platform.service_stale_instance_markers (stale_detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_service_stale_instance_markers_last_seen
  ON platform.service_stale_instance_markers (last_seen_at DESC)
  WHERE last_seen_at IS NOT NULL;

DROP TRIGGER IF EXISTS trg_service_instances_updated_at ON platform.service_instances;
CREATE TRIGGER trg_service_instances_updated_at
BEFORE UPDATE ON platform.service_instances
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_service_instance_heartbeats_updated_at ON platform.service_instance_heartbeats;
CREATE TRIGGER trg_service_instance_heartbeats_updated_at
BEFORE UPDATE ON platform.service_instance_heartbeats
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_service_instance_metadata_updated_at ON platform.service_instance_metadata;
CREATE TRIGGER trg_service_instance_metadata_updated_at
BEFORE UPDATE ON platform.service_instance_metadata
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_service_tenant_visibility_updated_at ON platform.service_tenant_visibility;
CREATE TRIGGER trg_service_tenant_visibility_updated_at
BEFORE UPDATE ON platform.service_tenant_visibility
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_service_stale_instance_markers_updated_at ON platform.service_stale_instance_markers;
CREATE TRIGGER trg_service_stale_instance_markers_updated_at
BEFORE UPDATE ON platform.service_stale_instance_markers
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.service_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.service_instance_heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.service_instance_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.service_tenant_visibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.service_stale_instance_markers ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.service_instances FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.service_instance_heartbeats FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.service_instance_metadata FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.service_tenant_visibility FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.service_stale_instance_markers FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS service_instances_tenant_isolation ON platform.service_instances;
CREATE POLICY service_instances_tenant_isolation
ON platform.service_instances
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

DROP POLICY IF EXISTS service_instance_heartbeats_tenant_isolation ON platform.service_instance_heartbeats;
CREATE POLICY service_instance_heartbeats_tenant_isolation
ON platform.service_instance_heartbeats
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

DROP POLICY IF EXISTS service_instance_metadata_tenant_isolation ON platform.service_instance_metadata;
CREATE POLICY service_instance_metadata_tenant_isolation
ON platform.service_instance_metadata
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

DROP POLICY IF EXISTS service_tenant_visibility_tenant_isolation ON platform.service_tenant_visibility;
CREATE POLICY service_tenant_visibility_tenant_isolation
ON platform.service_tenant_visibility
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

DROP POLICY IF EXISTS service_stale_instance_markers_tenant_isolation ON platform.service_stale_instance_markers;
CREATE POLICY service_stale_instance_markers_tenant_isolation
ON platform.service_stale_instance_markers
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

COMMENT ON TABLE platform.service_instances IS 'FAZ 2-6.1 service registry instance persistence table.';
COMMENT ON TABLE platform.service_instance_heartbeats IS 'FAZ 2-6.1 service registry heartbeat persistence table.';
COMMENT ON TABLE platform.service_instance_metadata IS 'FAZ 2-6.1 service registry metadata persistence table.';
COMMENT ON TABLE platform.service_tenant_visibility IS 'FAZ 2-6.1 service registry tenant visibility persistence table.';
COMMENT ON TABLE platform.service_stale_instance_markers IS 'FAZ 2-6.1 service registry stale instance marker persistence table.';

COMMIT;
