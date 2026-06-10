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

CREATE TABLE IF NOT EXISTS platform.plugin_lifecycles (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  plugin_lifecycle_id TEXT NOT NULL,
  plugin_key TEXT NOT NULL,
  plugin_name TEXT NOT NULL,
  provider_key TEXT NOT NULL,
  category TEXT NOT NULL,
  lifecycle_status TEXT NOT NULL DEFAULT 'DRAFT',
  lifecycle_stage TEXT NOT NULL DEFAULT 'FOUNDATION',
  distribution_mode TEXT NOT NULL DEFAULT 'PRIVATE',
  default_plugin_version_id TEXT,
  owner_team TEXT,
  entitlement_key TEXT,
  marketplace_app_key TEXT,
  sandbox_only BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at TIMESTAMPTZ,
  deprecated_at TIMESTAMPTZ,
  retired_at TIMESTAMPTZ,
  CONSTRAINT plugin_lifecycles_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT plugin_lifecycles_id_chk CHECK (length(trim(plugin_lifecycle_id)) > 0),
  CONSTRAINT plugin_lifecycles_key_chk CHECK (length(trim(plugin_key)) > 0),
  CONSTRAINT plugin_lifecycles_name_chk CHECK (length(trim(plugin_name)) > 0),
  CONSTRAINT plugin_lifecycles_provider_chk CHECK (length(trim(provider_key)) > 0),
  CONSTRAINT plugin_lifecycles_status_chk CHECK (
    lifecycle_status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'DEPRECATED', 'RETIRED')
  ),
  CONSTRAINT plugin_lifecycles_stage_chk CHECK (
    lifecycle_stage IN ('FOUNDATION', 'DRY_RUN', 'SANDBOX', 'PILOT', 'PRODUCTION', 'RETIRED')
  ),
  CONSTRAINT plugin_lifecycles_distribution_chk CHECK (
    distribution_mode IN ('PRIVATE', 'TENANT_SCOPED', 'MARKETPLACE', 'INTERNAL')
  ),
  CONSTRAINT plugin_lifecycles_tenant_lifecycle_uq UNIQUE (tenant_id, plugin_lifecycle_id),
  CONSTRAINT plugin_lifecycles_tenant_plugin_key_uq UNIQUE (tenant_id, plugin_key)
);

CREATE TABLE IF NOT EXISTS platform.plugin_versions (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  plugin_lifecycle_id BIGINT NOT NULL REFERENCES platform.plugin_lifecycles(id) ON DELETE CASCADE,
  plugin_version_id TEXT NOT NULL,
  plugin_key TEXT NOT NULL,
  version_label TEXT NOT NULL,
  semver_major INTEGER NOT NULL DEFAULT 0,
  semver_minor INTEGER NOT NULL DEFAULT 0,
  semver_patch INTEGER NOT NULL DEFAULT 0,
  release_channel TEXT NOT NULL DEFAULT 'DEV',
  version_status TEXT NOT NULL DEFAULT 'DRAFT',
  artifact_ref TEXT,
  manifest_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  migration_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  compatibility_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  required_capabilities TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  breaking_change BOOLEAN NOT NULL DEFAULT false,
  created_by TEXT NOT NULL DEFAULT 'system',
  approved_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  deprecated_at TIMESTAMPTZ,
  CONSTRAINT plugin_versions_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT plugin_versions_id_chk CHECK (length(trim(plugin_version_id)) > 0),
  CONSTRAINT plugin_versions_key_chk CHECK (length(trim(plugin_key)) > 0),
  CONSTRAINT plugin_versions_label_chk CHECK (length(trim(version_label)) > 0),
  CONSTRAINT plugin_versions_semver_major_chk CHECK (semver_major >= 0),
  CONSTRAINT plugin_versions_semver_minor_chk CHECK (semver_minor >= 0),
  CONSTRAINT plugin_versions_semver_patch_chk CHECK (semver_patch >= 0),
  CONSTRAINT plugin_versions_release_channel_chk CHECK (
    release_channel IN ('DEV', 'ALPHA', 'BETA', 'RC', 'STABLE', 'LTS')
  ),
  CONSTRAINT plugin_versions_status_chk CHECK (
    version_status IN ('DRAFT', 'APPROVED', 'PUBLISHED', 'DEPRECATED', 'REVOKED')
  ),
  CONSTRAINT plugin_versions_tenant_version_uq UNIQUE (tenant_id, plugin_version_id),
  CONSTRAINT plugin_versions_tenant_plugin_version_label_uq UNIQUE (tenant_id, plugin_key, version_label)
);

CREATE TABLE IF NOT EXISTS platform.tenant_plugin_installs (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  tenant_plugin_install_id TEXT NOT NULL,
  plugin_lifecycle_id BIGINT NOT NULL REFERENCES platform.plugin_lifecycles(id) ON DELETE RESTRICT,
  plugin_version_id BIGINT NOT NULL REFERENCES platform.plugin_versions(id) ON DELETE RESTRICT,
  plugin_key TEXT NOT NULL,
  app_id TEXT,
  install_status TEXT NOT NULL DEFAULT 'INSTALLED',
  install_mode TEXT NOT NULL DEFAULT 'DRY_RUN',
  config_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  secret_ref_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  entitlement_key TEXT,
  enabled_by_default BOOLEAN NOT NULL DEFAULT false,
  installed_by TEXT NOT NULL DEFAULT 'system',
  suspended_by TEXT,
  uninstalled_by TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  installed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  suspended_at TIMESTAMPTZ,
  uninstalled_at TIMESTAMPTZ,
  last_configured_at TIMESTAMPTZ,
  CONSTRAINT tenant_plugin_installs_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT tenant_plugin_installs_id_chk CHECK (length(trim(tenant_plugin_install_id)) > 0),
  CONSTRAINT tenant_plugin_installs_plugin_key_chk CHECK (length(trim(plugin_key)) > 0),
  CONSTRAINT tenant_plugin_installs_status_chk CHECK (
    install_status IN ('INSTALLED', 'ENABLED', 'DISABLED', 'SUSPENDED', 'UNINSTALLED', 'FAILED')
  ),
  CONSTRAINT tenant_plugin_installs_mode_chk CHECK (
    install_mode IN ('DRY_RUN', 'SANDBOX', 'PILOT', 'PRODUCTION')
  ),
  CONSTRAINT tenant_plugin_installs_tenant_install_uq UNIQUE (tenant_id, tenant_plugin_install_id),
  CONSTRAINT tenant_plugin_installs_tenant_plugin_uq UNIQUE (tenant_id, plugin_key)
);

CREATE TABLE IF NOT EXISTS platform.plugin_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  plugin_state_id TEXT NOT NULL,
  tenant_plugin_install_id BIGINT NOT NULL REFERENCES platform.tenant_plugin_installs(id) ON DELETE CASCADE,
  plugin_lifecycle_id BIGINT NOT NULL REFERENCES platform.plugin_lifecycles(id) ON DELETE RESTRICT,
  plugin_version_id BIGINT NOT NULL REFERENCES platform.plugin_versions(id) ON DELETE RESTRICT,
  plugin_key TEXT NOT NULL,
  runtime_status TEXT NOT NULL DEFAULT 'STOPPED',
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN',
  config_hash TEXT,
  worker_ref TEXT,
  last_heartbeat_at TIMESTAMPTZ,
  last_started_at TIMESTAMPTZ,
  last_stopped_at TIMESTAMPTZ,
  last_error_at TIMESTAMPTZ,
  last_error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  state_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metrics_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT plugin_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT plugin_states_id_chk CHECK (length(trim(plugin_state_id)) > 0),
  CONSTRAINT plugin_states_plugin_key_chk CHECK (length(trim(plugin_key)) > 0),
  CONSTRAINT plugin_states_runtime_status_chk CHECK (
    runtime_status IN ('STARTING', 'RUNNING', 'STOPPED', 'DEGRADED', 'FAILED', 'QUARANTINED')
  ),
  CONSTRAINT plugin_states_health_status_chk CHECK (
    health_status IN ('UNKNOWN', 'HEALTHY', 'DEGRADED', 'UNHEALTHY', 'DOWN')
  ),
  CONSTRAINT plugin_states_tenant_state_uq UNIQUE (tenant_id, plugin_state_id),
  CONSTRAINT plugin_states_tenant_install_uq UNIQUE (tenant_id, tenant_plugin_install_id)
);

CREATE TABLE IF NOT EXISTS platform.plugin_compatibility_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  compatibility_state_id TEXT NOT NULL,
  plugin_lifecycle_id BIGINT NOT NULL REFERENCES platform.plugin_lifecycles(id) ON DELETE CASCADE,
  plugin_version_id BIGINT NOT NULL REFERENCES platform.plugin_versions(id) ON DELETE CASCADE,
  tenant_plugin_install_id BIGINT REFERENCES platform.tenant_plugin_installs(id) ON DELETE SET NULL,
  plugin_key TEXT NOT NULL,
  target_runtime TEXT NOT NULL,
  target_runtime_version TEXT NOT NULL,
  compatibility_status TEXT NOT NULL DEFAULT 'UNKNOWN',
  decision TEXT NOT NULL DEFAULT 'REVIEW_REQUIRED',
  checked_by TEXT NOT NULL DEFAULT 'system',
  check_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  blocker_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  warning_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  checked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  CONSTRAINT plugin_compatibility_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT plugin_compatibility_states_id_chk CHECK (length(trim(compatibility_state_id)) > 0),
  CONSTRAINT plugin_compatibility_states_plugin_key_chk CHECK (length(trim(plugin_key)) > 0),
  CONSTRAINT plugin_compatibility_states_runtime_chk CHECK (length(trim(target_runtime)) > 0),
  CONSTRAINT plugin_compatibility_states_runtime_version_chk CHECK (length(trim(target_runtime_version)) > 0),
  CONSTRAINT plugin_compatibility_states_status_chk CHECK (
    compatibility_status IN ('UNKNOWN', 'COMPATIBLE', 'PARTIAL', 'INCOMPATIBLE', 'BLOCKED')
  ),
  CONSTRAINT plugin_compatibility_states_decision_chk CHECK (
    decision IN ('ALLOW', 'WARN', 'DENY', 'REVIEW_REQUIRED')
  ),
  CONSTRAINT plugin_compatibility_states_tenant_state_uq UNIQUE (tenant_id, compatibility_state_id),
  CONSTRAINT plugin_compatibility_states_version_runtime_uq UNIQUE (
    tenant_id,
    plugin_version_id,
    target_runtime,
    target_runtime_version
  )
);

CREATE INDEX IF NOT EXISTS idx_plugin_lifecycles_tenant_status
  ON platform.plugin_lifecycles (tenant_id, lifecycle_status);

CREATE INDEX IF NOT EXISTS idx_plugin_lifecycles_tenant_stage
  ON platform.plugin_lifecycles (tenant_id, lifecycle_stage);

CREATE INDEX IF NOT EXISTS idx_plugin_lifecycles_provider_category
  ON platform.plugin_lifecycles (tenant_id, provider_key, category);

CREATE INDEX IF NOT EXISTS idx_plugin_lifecycles_marketplace_app
  ON platform.plugin_lifecycles (tenant_id, marketplace_app_key)
  WHERE marketplace_app_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plugin_lifecycles_updated_at
  ON platform.plugin_lifecycles (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_plugin_versions_lifecycle
  ON platform.plugin_versions (tenant_id, plugin_lifecycle_id, version_status);

CREATE INDEX IF NOT EXISTS idx_plugin_versions_plugin_key_channel
  ON platform.plugin_versions (tenant_id, plugin_key, release_channel, version_status);

CREATE INDEX IF NOT EXISTS idx_plugin_versions_semver
  ON platform.plugin_versions (tenant_id, plugin_key, semver_major DESC, semver_minor DESC, semver_patch DESC);

CREATE INDEX IF NOT EXISTS idx_plugin_versions_published_at
  ON platform.plugin_versions (published_at DESC)
  WHERE published_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plugin_versions_breaking_change
  ON platform.plugin_versions (tenant_id, breaking_change)
  WHERE breaking_change = true;

CREATE INDEX IF NOT EXISTS idx_tenant_plugin_installs_tenant_status
  ON platform.tenant_plugin_installs (tenant_id, install_status);

CREATE INDEX IF NOT EXISTS idx_tenant_plugin_installs_plugin_key
  ON platform.tenant_plugin_installs (tenant_id, plugin_key, install_status);

CREATE INDEX IF NOT EXISTS idx_tenant_plugin_installs_lifecycle
  ON platform.tenant_plugin_installs (tenant_id, plugin_lifecycle_id);

CREATE INDEX IF NOT EXISTS idx_tenant_plugin_installs_version
  ON platform.tenant_plugin_installs (tenant_id, plugin_version_id);

CREATE INDEX IF NOT EXISTS idx_tenant_plugin_installs_app
  ON platform.tenant_plugin_installs (tenant_id, app_id)
  WHERE app_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plugin_states_tenant_runtime
  ON platform.plugin_states (tenant_id, runtime_status);

CREATE INDEX IF NOT EXISTS idx_plugin_states_tenant_health
  ON platform.plugin_states (tenant_id, health_status);

CREATE INDEX IF NOT EXISTS idx_plugin_states_install
  ON platform.plugin_states (tenant_id, tenant_plugin_install_id);

CREATE INDEX IF NOT EXISTS idx_plugin_states_plugin_key
  ON platform.plugin_states (tenant_id, plugin_key);

CREATE INDEX IF NOT EXISTS idx_plugin_states_heartbeat
  ON platform.plugin_states (last_heartbeat_at DESC)
  WHERE last_heartbeat_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plugin_states_last_error
  ON platform.plugin_states (last_error_at DESC)
  WHERE last_error_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plugin_compatibility_states_version_runtime
  ON platform.plugin_compatibility_states (tenant_id, plugin_version_id, target_runtime, target_runtime_version);

CREATE INDEX IF NOT EXISTS idx_plugin_compatibility_states_status
  ON platform.plugin_compatibility_states (tenant_id, compatibility_status);

CREATE INDEX IF NOT EXISTS idx_plugin_compatibility_states_decision
  ON platform.plugin_compatibility_states (tenant_id, decision);

CREATE INDEX IF NOT EXISTS idx_plugin_compatibility_states_install
  ON platform.plugin_compatibility_states (tenant_id, tenant_plugin_install_id)
  WHERE tenant_plugin_install_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plugin_compatibility_states_expires_at
  ON platform.plugin_compatibility_states (expires_at)
  WHERE expires_at IS NOT NULL;

DROP TRIGGER IF EXISTS trg_plugin_lifecycles_updated_at ON platform.plugin_lifecycles;
CREATE TRIGGER trg_plugin_lifecycles_updated_at
BEFORE UPDATE ON platform.plugin_lifecycles
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_plugin_versions_updated_at ON platform.plugin_versions;
CREATE TRIGGER trg_plugin_versions_updated_at
BEFORE UPDATE ON platform.plugin_versions
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_tenant_plugin_installs_updated_at ON platform.tenant_plugin_installs;
CREATE TRIGGER trg_tenant_plugin_installs_updated_at
BEFORE UPDATE ON platform.tenant_plugin_installs
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_plugin_states_updated_at ON platform.plugin_states;
CREATE TRIGGER trg_plugin_states_updated_at
BEFORE UPDATE ON platform.plugin_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_plugin_compatibility_states_updated_at ON platform.plugin_compatibility_states;
CREATE TRIGGER trg_plugin_compatibility_states_updated_at
BEFORE UPDATE ON platform.plugin_compatibility_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.plugin_lifecycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.plugin_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.tenant_plugin_installs ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.plugin_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.plugin_compatibility_states ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.plugin_lifecycles FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.plugin_versions FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.tenant_plugin_installs FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.plugin_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.plugin_compatibility_states FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS plugin_lifecycles_tenant_isolation ON platform.plugin_lifecycles;
CREATE POLICY plugin_lifecycles_tenant_isolation
ON platform.plugin_lifecycles
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

DROP POLICY IF EXISTS plugin_versions_tenant_isolation ON platform.plugin_versions;
CREATE POLICY plugin_versions_tenant_isolation
ON platform.plugin_versions
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

DROP POLICY IF EXISTS tenant_plugin_installs_tenant_isolation ON platform.tenant_plugin_installs;
CREATE POLICY tenant_plugin_installs_tenant_isolation
ON platform.tenant_plugin_installs
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

DROP POLICY IF EXISTS plugin_states_tenant_isolation ON platform.plugin_states;
CREATE POLICY plugin_states_tenant_isolation
ON platform.plugin_states
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

DROP POLICY IF EXISTS plugin_compatibility_states_tenant_isolation ON platform.plugin_compatibility_states;
CREATE POLICY plugin_compatibility_states_tenant_isolation
ON platform.plugin_compatibility_states
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

COMMENT ON TABLE platform.plugin_lifecycles IS 'FAZ 2-6.9 plugin lifecycle persistence table.';
COMMENT ON TABLE platform.plugin_versions IS 'FAZ 2-6.9 plugin version persistence table.';
COMMENT ON TABLE platform.tenant_plugin_installs IS 'FAZ 2-6.9 tenant plugin install persistence table.';
COMMENT ON TABLE platform.plugin_states IS 'FAZ 2-6.9 plugin runtime state persistence table.';
COMMENT ON TABLE platform.plugin_compatibility_states IS 'FAZ 2-6.9 plugin compatibility state persistence table.';

COMMIT;
