BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS app_dictionary;

CREATE OR REPLACE FUNCTION app_dictionary.derive_owner_domain(schema_name text, table_name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN schema_name IN ('auth','security','app_security') THEN 'security_access'
    WHEN schema_name = 'audit' THEN 'audit'
    WHEN schema_name IN ('ops','monitoring','observability') THEN 'ops'
    WHEN schema_name IN ('reporting','read_model','analytics') THEN 'reporting'
    WHEN schema_name IN ('core','org','public') THEN 'core_model'
    WHEN schema_name IN ('erp','finance','accounting','inventory','sales','purchase') THEN 'erp_domain'
    WHEN schema_name = 'app_dictionary' THEN 'data_governance'
    WHEN table_name ILIKE '%payment%' THEN 'payment'
    WHEN table_name ILIKE '%integration%' THEN 'integration'
    WHEN table_name ILIKE '%tenant%' THEN 'tenant_platform'
    ELSE 'business_domain'
  END;
$$;

CREATE OR REPLACE FUNCTION app_dictionary.derive_field_type_standard(data_type text, udt_name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN udt_name='uuid' THEN 'UUID'
    WHEN udt_name='jsonb' THEN 'JSONB'
    WHEN udt_name='json' THEN 'JSON'
    WHEN data_type='timestamp with time zone' THEN 'TIMESTAMPTZ'
    WHEN data_type='timestamp without time zone' THEN 'TIMESTAMP'
    WHEN data_type='date' THEN 'DATE'
    WHEN data_type='boolean' THEN 'BOOLEAN'
    WHEN data_type IN ('integer','smallint','bigint') THEN upper(data_type)
    WHEN data_type IN ('numeric','decimal','double precision','real') THEN 'NUMERIC'
    WHEN data_type IN ('text','character varying','character','citext') THEN 'TEXT'
    WHEN data_type='ARRAY' THEN 'ARRAY'
    WHEN data_type='USER-DEFINED' THEN upper(coalesce(udt_name, 'USER_DEFINED'))
    ELSE upper(coalesce(data_type, 'UNKNOWN'))
  END;
$$;

CREATE OR REPLACE FUNCTION app_dictionary.derive_required_policy(column_name text, is_nullable text, column_default text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN column_name IN ('id','tenant_id','business_code','created_at','updated_at') THEN 'REQUIRED_STANDARD'
    WHEN column_name IN ('legal_entity_id','branch_id','created_by','updated_by','deleted_at') THEN 'OPTIONAL_CONTEXTUAL'
    WHEN column_name IN ('audit_metadata','metadata') THEN 'SYSTEM_DEFAULT'
    WHEN is_nullable='NO' THEN 'REQUIRED_DB'
    WHEN column_default IS NOT NULL THEN 'SYSTEM_DEFAULT'
    ELSE 'OPTIONAL'
  END;
$$;

CREATE TABLE IF NOT EXISTS app_dictionary.table_contracts (
  table_contract_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schema_name text NOT NULL,
  table_name text NOT NULL,
  owner_domain text NOT NULL,
  table_kind text NOT NULL DEFAULT 'BASE_TABLE',
  lifecycle_status text NOT NULL DEFAULT 'ACTIVE',
  has_tenant_id boolean NOT NULL DEFAULT false,
  has_legal_entity_id boolean NOT NULL DEFAULT false,
  has_branch_id boolean NOT NULL DEFAULT false,
  has_business_code boolean NOT NULL DEFAULT false,
  field_count integer NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_app_dictionary_table_contracts_schema_table UNIQUE (schema_name, table_name),
  CONSTRAINT ck_app_dictionary_table_contracts_lifecycle CHECK (lifecycle_status IN ('ACTIVE','DEPRECATED','IGNORED'))
);

CREATE TABLE IF NOT EXISTS app_dictionary.field_contracts (
  field_contract_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schema_name text NOT NULL,
  table_name text NOT NULL,
  column_name text NOT NULL,
  owner_domain text NOT NULL,
  ordinal_position integer NOT NULL,
  data_type_raw text NOT NULL,
  udt_name text,
  field_type_standard text NOT NULL,
  nullable_db boolean NOT NULL,
  required_policy text NOT NULL,
  column_default text,
  max_length integer,
  numeric_precision integer,
  numeric_scale integer,
  is_identity text,
  field_contract_status text NOT NULL DEFAULT 'ACTIVE',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_app_dictionary_field_contracts_schema_table_column UNIQUE (schema_name, table_name, column_name),
  CONSTRAINT ck_app_dictionary_field_contracts_status CHECK (field_contract_status IN ('ACTIVE','DEPRECATED','IGNORED')),
  CONSTRAINT ck_app_dictionary_required_policy CHECK (required_policy IN ('REQUIRED_STANDARD','REQUIRED_DB','OPTIONAL_CONTEXTUAL','SYSTEM_DEFAULT','OPTIONAL')),
  CONSTRAINT ck_app_dictionary_field_type_not_empty CHECK (btrim(field_type_standard) <> '')
);

CREATE TABLE IF NOT EXISTS app_dictionary.field_contract_audit (
  field_contract_audit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_run_id text NOT NULL,
  audit_status text NOT NULL,
  issue_type text NOT NULL,
  schema_name text,
  table_name text,
  column_name text,
  issue_detail text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_app_dictionary_field_contract_audit_status CHECK (audit_status IN ('PASS','WARN','FAIL'))
);

CREATE INDEX IF NOT EXISTS idx_app_dictionary_table_contracts_owner_domain
  ON app_dictionary.table_contracts(owner_domain);

CREATE INDEX IF NOT EXISTS idx_app_dictionary_field_contracts_owner_domain
  ON app_dictionary.field_contracts(owner_domain);

CREATE INDEX IF NOT EXISTS idx_app_dictionary_field_contracts_type_standard
  ON app_dictionary.field_contracts(field_type_standard);

CREATE INDEX IF NOT EXISTS idx_app_dictionary_field_contracts_required_policy
  ON app_dictionary.field_contracts(required_policy);

CREATE INDEX IF NOT EXISTS idx_app_dictionary_field_contract_audit_run
  ON app_dictionary.field_contract_audit(audit_run_id, audit_status);

WITH source_tables AS (
  SELECT
    t.table_schema,
    t.table_name,
    app_dictionary.derive_owner_domain(t.table_schema, t.table_name) AS owner_domain,
    EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema=t.table_schema AND c.table_name=t.table_name AND c.column_name='tenant_id'
    ) AS has_tenant_id,
    EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema=t.table_schema AND c.table_name=t.table_name AND c.column_name='legal_entity_id'
    ) AS has_legal_entity_id,
    EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema=t.table_schema AND c.table_name=t.table_name AND c.column_name='branch_id'
    ) AS has_branch_id,
    EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema=t.table_schema AND c.table_name=t.table_name AND c.column_name='business_code'
    ) AS has_business_code,
    (
      SELECT count(*)::int FROM information_schema.columns c
      WHERE c.table_schema=t.table_schema AND c.table_name=t.table_name
    ) AS field_count
  FROM information_schema.tables t
  WHERE t.table_type='BASE TABLE'
    AND t.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND t.table_schema NOT LIKE 'pg_%'
)
INSERT INTO app_dictionary.table_contracts (
  schema_name,
  table_name,
  owner_domain,
  table_kind,
  lifecycle_status,
  has_tenant_id,
  has_legal_entity_id,
  has_branch_id,
  has_business_code,
  field_count,
  metadata,
  updated_at
)
SELECT
  table_schema,
  table_name,
  owner_domain,
  'BASE_TABLE',
  'ACTIVE',
  has_tenant_id,
  has_legal_entity_id,
  has_branch_id,
  has_business_code,
  field_count,
  jsonb_build_object(
    'source', 'information_schema',
    'phase', 'FAZ_1_1_8',
    'contract_version', 'v1'
  ),
  now()
FROM source_tables
ON CONFLICT (schema_name, table_name) DO UPDATE SET
  owner_domain=EXCLUDED.owner_domain,
  table_kind=EXCLUDED.table_kind,
  lifecycle_status=EXCLUDED.lifecycle_status,
  has_tenant_id=EXCLUDED.has_tenant_id,
  has_legal_entity_id=EXCLUDED.has_legal_entity_id,
  has_branch_id=EXCLUDED.has_branch_id,
  has_business_code=EXCLUDED.has_business_code,
  field_count=EXCLUDED.field_count,
  metadata=EXCLUDED.metadata,
  updated_at=now();

WITH source_fields AS (
  SELECT
    c.table_schema,
    c.table_name,
    c.column_name,
    app_dictionary.derive_owner_domain(c.table_schema, c.table_name) AS owner_domain,
    c.ordinal_position,
    c.data_type,
    c.udt_name,
    app_dictionary.derive_field_type_standard(c.data_type, c.udt_name) AS field_type_standard,
    (c.is_nullable='YES') AS nullable_db,
    app_dictionary.derive_required_policy(c.column_name, c.is_nullable, c.column_default) AS required_policy,
    c.column_default,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_identity
  FROM information_schema.columns c
  JOIN information_schema.tables t
    ON t.table_schema=c.table_schema
   AND t.table_name=c.table_name
   AND t.table_type='BASE TABLE'
  WHERE c.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND c.table_schema NOT LIKE 'pg_%'
)
INSERT INTO app_dictionary.field_contracts (
  schema_name,
  table_name,
  column_name,
  owner_domain,
  ordinal_position,
  data_type_raw,
  udt_name,
  field_type_standard,
  nullable_db,
  required_policy,
  column_default,
  max_length,
  numeric_precision,
  numeric_scale,
  is_identity,
  field_contract_status,
  metadata,
  updated_at
)
SELECT
  table_schema,
  table_name,
  column_name,
  owner_domain,
  ordinal_position,
  data_type,
  udt_name,
  field_type_standard,
  nullable_db,
  required_policy,
  column_default,
  character_maximum_length,
  numeric_precision,
  numeric_scale,
  is_identity,
  'ACTIVE',
  jsonb_build_object(
    'source', 'information_schema',
    'phase', 'FAZ_1_1_8',
    'contract_version', 'v1'
  ),
  now()
FROM source_fields
ON CONFLICT (schema_name, table_name, column_name) DO UPDATE SET
  owner_domain=EXCLUDED.owner_domain,
  ordinal_position=EXCLUDED.ordinal_position,
  data_type_raw=EXCLUDED.data_type_raw,
  udt_name=EXCLUDED.udt_name,
  field_type_standard=EXCLUDED.field_type_standard,
  nullable_db=EXCLUDED.nullable_db,
  required_policy=EXCLUDED.required_policy,
  column_default=EXCLUDED.column_default,
  max_length=EXCLUDED.max_length,
  numeric_precision=EXCLUDED.numeric_precision,
  numeric_scale=EXCLUDED.numeric_scale,
  is_identity=EXCLUDED.is_identity,
  field_contract_status=EXCLUDED.field_contract_status,
  metadata=EXCLUDED.metadata,
  updated_at=now();

DELETE FROM app_dictionary.field_contract_audit
WHERE audit_run_id='FAZ_1_1_8_CURRENT';

INSERT INTO app_dictionary.field_contract_audit (
  audit_run_id,
  audit_status,
  issue_type,
  schema_name,
  table_name,
  column_name,
  issue_detail,
  metadata
)
SELECT
  'FAZ_1_1_8_CURRENT',
  'FAIL',
  'MISSING_TABLE_CONTRACT',
  t.table_schema,
  t.table_name,
  NULL,
  'Base table does not have table contract',
  '{}'::jsonb
FROM information_schema.tables t
WHERE t.table_type='BASE TABLE'
  AND t.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
  AND t.table_schema NOT LIKE 'pg_%'
  AND NOT EXISTS (
    SELECT 1 FROM app_dictionary.table_contracts tc
    WHERE tc.schema_name=t.table_schema
      AND tc.table_name=t.table_name
  );

INSERT INTO app_dictionary.field_contract_audit (
  audit_run_id,
  audit_status,
  issue_type,
  schema_name,
  table_name,
  column_name,
  issue_detail,
  metadata
)
SELECT
  'FAZ_1_1_8_CURRENT',
  'FAIL',
  'MISSING_FIELD_CONTRACT',
  c.table_schema,
  c.table_name,
  c.column_name,
  'Column does not have field contract',
  '{}'::jsonb
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema=c.table_schema
 AND t.table_name=c.table_name
 AND t.table_type='BASE TABLE'
WHERE c.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
  AND c.table_schema NOT LIKE 'pg_%'
  AND NOT EXISTS (
    SELECT 1 FROM app_dictionary.field_contracts fc
    WHERE fc.schema_name=c.table_schema
      AND fc.table_name=c.table_name
      AND fc.column_name=c.column_name
  );

INSERT INTO app_dictionary.field_contract_audit (
  audit_run_id,
  audit_status,
  issue_type,
  schema_name,
  table_name,
  column_name,
  issue_detail,
  metadata
)
SELECT
  'FAZ_1_1_8_CURRENT',
  'FAIL',
  'MISSING_OWNER_DOMAIN',
  schema_name,
  table_name,
  column_name,
  'Field owner_domain is empty',
  '{}'::jsonb
FROM app_dictionary.field_contracts
WHERE btrim(coalesce(owner_domain,''))='';

INSERT INTO app_dictionary.field_contract_audit (
  audit_run_id,
  audit_status,
  issue_type,
  schema_name,
  table_name,
  column_name,
  issue_detail,
  metadata
)
SELECT
  'FAZ_1_1_8_CURRENT',
  'FAIL',
  'MISSING_TYPE_STANDARD',
  schema_name,
  table_name,
  column_name,
  'Field type standard is empty',
  '{}'::jsonb
FROM app_dictionary.field_contracts
WHERE btrim(coalesce(field_type_standard,''))='';

INSERT INTO app_dictionary.field_contract_audit (
  audit_run_id,
  audit_status,
  issue_type,
  schema_name,
  table_name,
  column_name,
  issue_detail,
  metadata
)
SELECT
  'FAZ_1_1_8_CURRENT',
  'FAIL',
  'MISSING_REQUIRED_POLICY',
  schema_name,
  table_name,
  column_name,
  'Required/nullable policy is empty',
  '{}'::jsonb
FROM app_dictionary.field_contracts
WHERE btrim(coalesce(required_policy,''))='';

INSERT INTO app_dictionary.field_contract_audit (
  audit_run_id,
  audit_status,
  issue_type,
  issue_detail,
  metadata
)
VALUES (
  'FAZ_1_1_8_CURRENT',
  'PASS',
  'FIELD_CONTRACT_AUDIT_COMPLETED',
  'Data dictionary and field contract audit completed',
  jsonb_build_object('phase','FAZ_1_1_8','contract_version','v1')
);

GRANT USAGE ON SCHEMA app_dictionary TO PUBLIC;
GRANT SELECT ON app_dictionary.table_contracts TO PUBLIC;
GRANT SELECT ON app_dictionary.field_contracts TO PUBLIC;
GRANT SELECT ON app_dictionary.field_contract_audit TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_dictionary.derive_owner_domain(text,text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_dictionary.derive_field_type_standard(text,text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_dictionary.derive_required_policy(text,text,text) TO PUBLIC;

COMMIT;
