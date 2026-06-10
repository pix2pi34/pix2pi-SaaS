BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS app_schema;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS erp;
CREATE SCHEMA IF NOT EXISTS ops;
CREATE SCHEMA IF NOT EXISTS reporting;

CREATE OR REPLACE FUNCTION app_schema.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TABLE IF NOT EXISTS app_schema.schema_boundary_map (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  boundary_code text NOT NULL,
  boundary_name_tr text NOT NULL,
  boundary_name_en text NOT NULL,
  purpose text NOT NULL,
  canonical_schemas text[] NOT NULL DEFAULT ARRAY[]::text[],
  accepted_schema_patterns text[] NOT NULL DEFAULT ARRAY[]::text[],
  write_owner text NOT NULL,
  read_owner text NOT NULL,
  migration_path text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_app_schema_boundary_map_boundary_code
  ON app_schema.schema_boundary_map(boundary_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_app_schema_boundary_map_status
  ON app_schema.schema_boundary_map(status);

CREATE INDEX IF NOT EXISTS idx_app_schema_boundary_map_write_owner
  ON app_schema.schema_boundary_map(write_owner);

ALTER TABLE app_schema.schema_boundary_map DROP CONSTRAINT IF EXISTS ck_app_schema_boundary_map_required_fields;
ALTER TABLE app_schema.schema_boundary_map
  ADD CONSTRAINT ck_app_schema_boundary_map_required_fields
  CHECK (
    boundary_code IS NOT NULL AND btrim(boundary_code) <> ''
    AND boundary_name_tr IS NOT NULL AND btrim(boundary_name_tr) <> ''
    AND boundary_name_en IS NOT NULL AND btrim(boundary_name_en) <> ''
    AND purpose IS NOT NULL AND btrim(purpose) <> ''
    AND array_length(canonical_schemas, 1) IS NOT NULL
    AND write_owner IS NOT NULL AND btrim(write_owner) <> ''
    AND read_owner IS NOT NULL AND btrim(read_owner) <> ''
    AND migration_path IS NOT NULL AND btrim(migration_path) <> ''
    AND status IS NOT NULL AND btrim(status) <> ''
  ) NOT VALID;

ALTER TABLE app_schema.schema_boundary_map DROP CONSTRAINT IF EXISTS ck_app_schema_boundary_map_status;
ALTER TABLE app_schema.schema_boundary_map
  ADD CONSTRAINT ck_app_schema_boundary_map_status
  CHECK (status IN ('ACTIVE','PLANNED','DEPRECATED')) NOT VALID;

DROP TRIGGER IF EXISTS trg_app_schema_boundary_map_set_updated_at ON app_schema.schema_boundary_map;
CREATE TRIGGER trg_app_schema_boundary_map_set_updated_at
BEFORE UPDATE ON app_schema.schema_boundary_map
FOR EACH ROW
EXECUTE FUNCTION app_schema.set_updated_at();

INSERT INTO app_schema.schema_boundary_map (
  boundary_code,
  boundary_name_tr,
  boundary_name_en,
  purpose,
  canonical_schemas,
  accepted_schema_patterns,
  write_owner,
  read_owner,
  migration_path,
  status,
  metadata
)
VALUES
(
  'AUTH',
  'Kimlik / Yetki Schema Alanı',
  'Authentication / Authorization Schema Boundary',
  'Kullanıcı, rol, permission, user scope, super-admin ve break-glass güvenlik modellerini taşır.',
  ARRAY['auth','security','app_security'],
  ARRAY['auth.%','security.%','app_security.%'],
  'identity-security-platform',
  'api-gateway-and-authorized-services',
  'db/migrations/faz1/security',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','auth_schema')
),
(
  'TENANT',
  'Tenant / Organizasyon Schema Alanı',
  'Tenant / Organization Schema Boundary',
  'Tenant, legal entity, branch ve tenant scoped business modellerini taşır.',
  ARRAY['platform','org','tenant_*'],
  ARRAY['platform.%','org.%','tenant_*.%'],
  'tenant-core-platform',
  'tenant-aware-services',
  'db/migrations/faz1',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','tenant_schema')
),
(
  'ERP',
  'ERP / Domain Schema Alanı',
  'ERP / Domain Schema Boundary',
  'ERP çekirdek domainleri, muhasebe, stok, satış, ürün ve operasyonel iş tablolarını taşır.',
  ARRAY['erp','accounting','inventory','sales','purchase','product','catalog','org'],
  ARRAY['erp.%','accounting.%','inventory.%','sales.%','purchase.%','product.%','catalog.%','org.%'],
  'erp-domain-platform',
  'erp-services-and-reporting-readers',
  'db/migrations/faz1/db',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','erp_schema')
),
(
  'OPS',
  'Operasyon / Gözlemlenebilirlik Schema Alanı',
  'Operations / Observability Schema Boundary',
  'Audit, ops, security alert, incident, observability ve runtime control kayıtlarını taşır.',
  ARRAY['ops','audit','observability','app_security','security'],
  ARRAY['ops.%','audit.%','observability.%','app_security.%','security.%'],
  'sre-security-platform',
  'ops-console-and-admin-services',
  'db/migrations/faz1/ops',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','ops_schema')
),
(
  'REPORTING',
  'Raporlama / Read Model Schema Alanı',
  'Reporting / Read Model Schema Boundary',
  'Read model, reporting store, analytics ve raporlama için optimize edilmiş verileri taşır.',
  ARRAY['reporting','read_model','analytics'],
  ARRAY['reporting.%','read_model.%','analytics.%'],
  'reporting-platform',
  'reporting-api-and-dashboard',
  'db/migrations/faz1/reporting',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','reporting_schema')
),
(
  'MIGRATION_PATH',
  'Migration Path / Değişiklik Yönetimi',
  'Migration Path / Change Management Boundary',
  'DB değişikliklerinin faz bazlı migration dosyaları, rollback kanıtları ve evidence pathleriyle yönetilmesini standartlaştırır.',
  ARRAY['db/migrations','db/migrations/faz1','docs/faz1/evidence','backups/faz1'],
  ARRAY['db/migrations/%','docs/faz1/evidence/%','backups/faz1/%'],
  'platform-migration-owner',
  'release-and-audit-process',
  'db/migrations/faz1',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','migration_path')
)
ON CONFLICT (boundary_code) WHERE deleted_at IS NULL
DO UPDATE SET
  boundary_name_tr=EXCLUDED.boundary_name_tr,
  boundary_name_en=EXCLUDED.boundary_name_en,
  purpose=EXCLUDED.purpose,
  canonical_schemas=EXCLUDED.canonical_schemas,
  accepted_schema_patterns=EXCLUDED.accepted_schema_patterns,
  write_owner=EXCLUDED.write_owner,
  read_owner=EXCLUDED.read_owner,
  migration_path=EXCLUDED.migration_path,
  status=EXCLUDED.status,
  metadata=EXCLUDED.metadata,
  updated_at=now();

GRANT USAGE ON SCHEMA app_schema TO PUBLIC;
GRANT SELECT ON app_schema.schema_boundary_map TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_schema.set_updated_at() TO PUBLIC;

COMMIT;
