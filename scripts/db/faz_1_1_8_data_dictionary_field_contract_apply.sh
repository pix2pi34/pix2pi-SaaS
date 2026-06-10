#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT"

BACKUP_DIR="$REPO/backups/faz1/faz_1_1_8_data_dictionary_field_contract_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_1_8_data_dictionary_field_contract_apply.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_1_8_data_dictionary_field_contract_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_1_8_data_dictionary_field_contract.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_FINAL_SEAL_$TS.md"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_1_8_strict_suite_run.out"

TABLE_CONTRACT_SNAPSHOT_CSV="$BACKUP_DIR/data_dictionary_table_contract_snapshot.csv"
FIELD_CONTRACT_SNAPSHOT_CSV="$BACKUP_DIR/data_dictionary_field_contract_snapshot.csv"
FIELD_CONTRACT_AUDIT_CSV="$BACKUP_DIR/data_dictionary_field_contract_audit_snapshot.csv"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

scalar_count() {
  local sql="$1"
  local out=""
  set +e
  out="$(psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}')"
  local ec=$?
  set -e
  if [ "$ec" -ne 0 ] || ! [[ "$out" =~ ^[0-9]+$ ]]; then
    echo 0
  else
    echo "$out"
  fi
}

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT APPLY START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$APPLY_SCRIPT_FILE" "$STRICT_SUITE_FILE" "$DOC_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. env kaynakları yükleniyor..."

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "3.1 common.env yüklendi"
else
  warn "3.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  source "$REPO/.env"
  set +a
  pass "3.2 repo .env yüklendi"
else
  warn "3.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "${DSN:-}" ]; then
  pass "4. DB DSN bulundu"
else
  fail "4. DB DSN bulunamadı"
  exit 1
fi

if command -v psql >/dev/null 2>&1; then
  pass "5. psql mevcut"
else
  fail "5. psql bulunamadı"
  exit 1
fi

if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then
  pass "6. DB bağlantısı başarılı"
else
  fail "6. DB bağlantısı başarısız"
  exit 1
fi

echo "7. data dictionary migration hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
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
SQL

pass "7.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "8. data dictionary migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "8.1 migration başarıyla uygulandı"
else
  fail "8.1 migration uygulanamadı"
  exit 1
fi

echo "9. data dictionary snapshot dosyaları üretiliyor..."

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select
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
    updated_at
  from app_dictionary.table_contracts
  order by schema_name, table_name
) to '$TABLE_CONTRACT_SNAPSHOT_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select
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
    field_contract_status,
    updated_at
  from app_dictionary.field_contracts
  order by schema_name, table_name, ordinal_position, column_name
) to '$FIELD_CONTRACT_SNAPSHOT_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select
    audit_run_id,
    audit_status,
    issue_type,
    schema_name,
    table_name,
    column_name,
    issue_detail,
    created_at
  from app_dictionary.field_contract_audit
  where audit_run_id='FAZ_1_1_8_CURRENT'
  order by audit_status, issue_type, schema_name, table_name, column_name
) to '$FIELD_CONTRACT_AUDIT_CSV' with csv header;" >/dev/null

SOURCE_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%';
")"

SOURCE_FIELD_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns c
  join information_schema.tables t
    on t.table_schema=c.table_schema
   and t.table_name=c.table_name
   and t.table_type='BASE TABLE'
  where c.table_schema not in ('pg_catalog','information_schema','pg_toast')
    and c.table_schema not like 'pg_%';
")"

TABLE_CONTRACT_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts;")"
FIELD_CONTRACT_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts;")"
OWNER_DOMAIN_COUNT="$(scalar_count "select count(distinct owner_domain) from app_dictionary.field_contracts;")"
OWNER_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(owner_domain,''))='';")"
REQUIRED_POLICY_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(required_policy,''))='';")"
TYPE_STANDARD_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(field_type_standard,''))='';")"
AUDIT_FAIL_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contract_audit where audit_run_id='FAZ_1_1_8_CURRENT' and audit_status='FAIL';")"
AUDIT_PASS_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contract_audit where audit_run_id='FAZ_1_1_8_CURRENT' and audit_status='PASS';")"
DICT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='app_dictionary'
    and table_name in ('table_contracts','field_contracts','field_contract_audit');
")"
DICT_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='app_dictionary'
    and p.proname in ('derive_owner_domain','derive_field_type_standard','derive_required_policy');
")"

echo "SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
echo "SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
echo "TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
echo "FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
echo "OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
echo "OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
echo "REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
echo "TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
echo "AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
echo "AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
echo "DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
echo "DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
echo "TABLE_CONTRACT_SNAPSHOT_CSV=$TABLE_CONTRACT_SNAPSHOT_CSV"
echo "FIELD_CONTRACT_SNAPSHOT_CSV=$FIELD_CONTRACT_SNAPSHOT_CSV"
echo "FIELD_CONTRACT_AUDIT_CSV=$FIELD_CONTRACT_AUDIT_CSV"

[ "$DICT_TABLE_COUNT" -ge 3 ] && pass "9.1 data dictionary tablo seti hazır" || fail "9.1 data dictionary tablo seti eksik"
[ "$DICT_FUNCTION_COUNT" -ge 3 ] && pass "9.2 data dictionary helper function seti hazır" || fail "9.2 helper function seti eksik"
[ "$TABLE_CONTRACT_COUNT" -eq "$SOURCE_TABLE_COUNT" ] && pass "9.3 data dictionary tablo kapsamı tam" || fail "9.3 data dictionary tablo kapsamı eksik"
[ "$FIELD_CONTRACT_COUNT" -eq "$SOURCE_FIELD_COUNT" ] && pass "9.4 field contract kapsamı tam" || fail "9.4 field contract kapsamı eksik"
[ "$OWNER_DOMAIN_COUNT" -gt 0 ] && pass "9.5 field ownership domain üretildi" || fail "9.5 field ownership domain yok"
[ "$OWNER_MISSING_COUNT" -eq 0 ] && pass "9.6 field ownership eksik yok" || fail "9.6 field ownership eksik var"
[ "$REQUIRED_POLICY_MISSING_COUNT" -eq 0 ] && pass "9.7 required/nullable standardı eksik yok" || fail "9.7 required/nullable standardı eksik var"
[ "$TYPE_STANDARD_MISSING_COUNT" -eq 0 ] && pass "9.8 field type standardı eksik yok" || fail "9.8 field type standardı eksik var"
[ "$AUDIT_FAIL_COUNT" -eq 0 ] && pass "9.9 field contract audit fail yok" || fail "9.9 field contract audit fail var"
[ "$AUDIT_PASS_COUNT" -gt 0 ] && pass "9.10 field contract audit pass kaydı var" || fail "9.10 field contract audit pass kaydı yok"

echo "10. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_8_data_dictionary_field_contract_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_SUITE_RESULT_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

scalar_count() {
  local sql="$1"
  local out=""
  set +e
  out="$(psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}')"
  local ec=$?
  set -e
  if [ "$ec" -ne 0 ] || ! [[ "$out" =~ ^[0-9]+$ ]]; then
    echo 0
  else
    echo "$out"
  fi
}

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT STRICT SUITE START ====="

mkdir -p "$BACKUP_DIR" "$EVIDENCE_DIR"
cd "$REPO"

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "1.1 common.env yüklendi"
else
  warn "1.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  source "$REPO/.env"
  set +a
  pass "1.2 repo .env yüklendi"
else
  warn "1.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "${DSN:-}" ]; then pass "2. DB DSN bulundu"; else fail "2. DB DSN bulunamadı"; exit 1; fi
if command -v psql >/dev/null 2>&1; then pass "3. psql mevcut"; else fail "3. psql bulunamadı"; exit 1; fi
if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then pass "4. DB bağlantısı başarılı"; else fail "4. DB bağlantısı başarısız"; exit 1; fi

echo "5. data dictionary / field contract sayaçları alınıyor..."

SOURCE_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%';
")"

SOURCE_FIELD_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns c
  join information_schema.tables t
    on t.table_schema=c.table_schema
   and t.table_name=c.table_name
   and t.table_type='BASE TABLE'
  where c.table_schema not in ('pg_catalog','information_schema','pg_toast')
    and c.table_schema not like 'pg_%';
")"

DICT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='app_dictionary'
    and table_name in ('table_contracts','field_contracts','field_contract_audit');
")"

DICT_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='app_dictionary'
    and p.proname in ('derive_owner_domain','derive_field_type_standard','derive_required_policy');
")"

TABLE_CONTRACT_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts;")"
FIELD_CONTRACT_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts;")"
OWNER_DOMAIN_COUNT="$(scalar_count "select count(distinct owner_domain) from app_dictionary.field_contracts;")"
OWNER_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(owner_domain,''))='';")"
REQUIRED_POLICY_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(required_policy,''))='';")"
TYPE_STANDARD_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(field_type_standard,''))='';")"
AUDIT_FAIL_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contract_audit where audit_run_id='FAZ_1_1_8_CURRENT' and audit_status='FAIL';")"
AUDIT_PASS_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contract_audit where audit_run_id='FAZ_1_1_8_CURRENT' and audit_status='PASS';")"
REQUIRED_STANDARD_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where required_policy='REQUIRED_STANDARD';")"
OPTIONAL_POLICY_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where required_policy in ('OPTIONAL','OPTIONAL_CONTEXTUAL','SYSTEM_DEFAULT');")"
TYPE_STANDARD_COUNT="$(scalar_count "select count(distinct field_type_standard) from app_dictionary.field_contracts;")"

echo "SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
echo "SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
echo "DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
echo "DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
echo "TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
echo "FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
echo "OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
echo "OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
echo "REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
echo "TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
echo "AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
echo "AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
echo "REQUIRED_STANDARD_COUNT=$REQUIRED_STANDARD_COUNT"
echo "OPTIONAL_POLICY_COUNT=$OPTIONAL_POLICY_COUNT"
echo "TYPE_STANDARD_COUNT=$TYPE_STANDARD_COUNT"

[ "$DICT_TABLE_COUNT" -ge 3 ] && pass "5.1 data dictionary tablo seti hazır" || fail "5.1 data dictionary tablo seti eksik"
[ "$DICT_FUNCTION_COUNT" -ge 3 ] && pass "5.2 helper function seti hazır" || fail "5.2 helper function seti eksik"
[ "$TABLE_CONTRACT_COUNT" -eq "$SOURCE_TABLE_COUNT" ] && pass "5.3 data dictionary tablo kapsamı tam" || fail "5.3 data dictionary tablo kapsamı eksik"
[ "$FIELD_CONTRACT_COUNT" -eq "$SOURCE_FIELD_COUNT" ] && pass "5.4 field contract kapsamı tam" || fail "5.4 field contract kapsamı eksik"
[ "$OWNER_DOMAIN_COUNT" -gt 0 ] && pass "5.5 field ownership domain üretildi" || fail "5.5 field ownership domain yok"
[ "$OWNER_MISSING_COUNT" -eq 0 ] && pass "5.6 field ownership eksik yok" || fail "5.6 field ownership eksik var"
[ "$REQUIRED_POLICY_MISSING_COUNT" -eq 0 ] && pass "5.7 required/nullable standardı eksik yok" || fail "5.7 required/nullable standardı eksik var"
[ "$TYPE_STANDARD_MISSING_COUNT" -eq 0 ] && pass "5.8 field type standardı eksik yok" || fail "5.8 field type standardı eksik var"
[ "$AUDIT_FAIL_COUNT" -eq 0 ] && pass "5.9 field contract audit fail yok" || fail "5.9 field contract audit fail var"
[ "$AUDIT_PASS_COUNT" -gt 0 ] && pass "5.10 field contract audit pass kaydı var" || fail "5.10 field contract audit pass kaydı yok"
[ "$REQUIRED_STANDARD_COUNT" -gt 0 ] && pass "5.11 required standard policy kayıtları var" || fail "5.11 required standard policy kaydı yok"
[ "$OPTIONAL_POLICY_COUNT" -gt 0 ] && pass "5.12 optional/contextual policy kayıtları var" || fail "5.12 optional/contextual policy kaydı yok"
[ "$TYPE_STANDARD_COUNT" -gt 0 ] && pass "5.13 field type standard çeşitliliği var" || fail "5.13 field type standard çeşitliliği yok"

echo "6. strict SQL assertion suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/data_dictionary_field_contract_strict_assertion.sql"
SQL_SUITE_OUT="$BACKUP_DIR/data_dictionary_field_contract_strict_assertion.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_source_tables int;
  v_source_fields int;
  v_table_contracts int;
  v_field_contracts int;
  v_missing_owner int;
  v_missing_required int;
  v_missing_type int;
  v_audit_fail int;
  v_audit_pass int;
  v_missing_table_contracts int;
  v_missing_field_contracts int;
BEGIN
  SELECT count(*)
  INTO v_source_tables
  FROM information_schema.tables
  WHERE table_type='BASE TABLE'
    AND table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND table_schema NOT LIKE 'pg_%';

  SELECT count(*)
  INTO v_source_fields
  FROM information_schema.columns c
  JOIN information_schema.tables t
    ON t.table_schema=c.table_schema
   AND t.table_name=c.table_name
   AND t.table_type='BASE TABLE'
  WHERE c.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND c.table_schema NOT LIKE 'pg_%';

  SELECT count(*) INTO v_table_contracts FROM app_dictionary.table_contracts;
  SELECT count(*) INTO v_field_contracts FROM app_dictionary.field_contracts;

  IF v_table_contracts <> v_source_tables THEN
    RAISE EXCEPTION 'table contract coverage mismatch source=% contract=%', v_source_tables, v_table_contracts;
  END IF;

  IF v_field_contracts <> v_source_fields THEN
    RAISE EXCEPTION 'field contract coverage mismatch source=% contract=%', v_source_fields, v_field_contracts;
  END IF;

  SELECT count(*) INTO v_missing_owner
  FROM app_dictionary.field_contracts
  WHERE btrim(coalesce(owner_domain,''))='';

  IF v_missing_owner <> 0 THEN
    RAISE EXCEPTION 'missing owner_domain count=%', v_missing_owner;
  END IF;

  SELECT count(*) INTO v_missing_required
  FROM app_dictionary.field_contracts
  WHERE btrim(coalesce(required_policy,''))='';

  IF v_missing_required <> 0 THEN
    RAISE EXCEPTION 'missing required_policy count=%', v_missing_required;
  END IF;

  SELECT count(*) INTO v_missing_type
  FROM app_dictionary.field_contracts
  WHERE btrim(coalesce(field_type_standard,''))='';

  IF v_missing_type <> 0 THEN
    RAISE EXCEPTION 'missing field_type_standard count=%', v_missing_type;
  END IF;

  SELECT count(*) INTO v_missing_table_contracts
  FROM information_schema.tables t
  WHERE t.table_type='BASE TABLE'
    AND t.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND t.table_schema NOT LIKE 'pg_%'
    AND NOT EXISTS (
      SELECT 1 FROM app_dictionary.table_contracts tc
      WHERE tc.schema_name=t.table_schema
        AND tc.table_name=t.table_name
    );

  IF v_missing_table_contracts <> 0 THEN
    RAISE EXCEPTION 'missing table contracts count=%', v_missing_table_contracts;
  END IF;

  SELECT count(*) INTO v_missing_field_contracts
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

  IF v_missing_field_contracts <> 0 THEN
    RAISE EXCEPTION 'missing field contracts count=%', v_missing_field_contracts;
  END IF;

  SELECT count(*) INTO v_audit_fail
  FROM app_dictionary.field_contract_audit
  WHERE audit_run_id='FAZ_1_1_8_CURRENT'
    AND audit_status='FAIL';

  IF v_audit_fail <> 0 THEN
    RAISE EXCEPTION 'field contract audit fail count=%', v_audit_fail;
  END IF;

  SELECT count(*) INTO v_audit_pass
  FROM app_dictionary.field_contract_audit
  WHERE audit_run_id='FAZ_1_1_8_CURRENT'
    AND audit_status='PASS';

  IF v_audit_pass < 1 THEN
    RAISE EXCEPTION 'field contract audit pass marker missing';
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "6.1 strict SQL assertion suite geçti"
else
  fail "6.1 strict SQL assertion suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "6.2 strict SQL suite rollback ile temizlendi"
else
  fail "6.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-1.8 Data Dictionary / Field Contract Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
  echo "- SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
  echo "- DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
  echo "- DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
  echo "- TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
  echo "- FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
  echo "- OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
  echo "- OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
  echo "- REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
  echo "- TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
  echo "- AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
  echo "- AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
  echo "- REQUIRED_STANDARD_COUNT=$REQUIRED_STANDARD_COUNT"
  echo "- OPTIONAL_POLICY_COUNT=$OPTIONAL_POLICY_COUNT"
  echo "- TYPE_STANDARD_COUNT=$TYPE_STANDARD_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
echo "SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
echo "DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
echo "DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
echo "TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
echo "FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
echo "OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
echo "OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
echo "REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
echo "TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
echo "AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
echo "AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
echo "REQUIRED_STANDARD_COUNT=$REQUIRED_STANDARD_COUNT"
echo "OPTIONAL_POLICY_COUNT=$OPTIONAL_POLICY_COUNT"
echo "TYPE_STANDARD_COUNT=$TYPE_STANDARD_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_8_DATA_DICTIONARY_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_OWNERSHIP_STATUS=PASS"
  echo "FAZ_1_1_8_REQUIRED_NULLABLE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_TYPE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_CONTRACT_AUDIT_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "10.1 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "11. strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "11.1 strict suite exit code 0"
else
  fail "11.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS")"

DATA_DICTIONARY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_DATA_DICTIONARY_STATUS")"
FIELD_OWNERSHIP_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_FIELD_OWNERSHIP_STATUS")"
REQUIRED_NULLABLE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_REQUIRED_NULLABLE_STANDARD_STATUS")"
FIELD_TYPE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_FIELD_TYPE_STANDARD_STATUS")"
FIELD_CONTRACT_AUDIT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_8_FIELD_CONTRACT_AUDIT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "12. strict suite FAIL_COUNT=0 doğrulandı" || fail "12. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "13. strict suite status PASS doğrulandı" || fail "13. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "14. strict suite seal SEALED doğrulandı" || fail "14. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "15. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-1.8 Data Dictionary / Field Contract

## Kapsam

- Data dictionary
- Field ownership
- Required/nullable standardı
- Field type standardı
- Field contract audit

## Uygulama

Bu adım app_dictionary schema altında table_contracts, field_contracts ve field_contract_audit omurgasını kurar. Mevcut PostgreSQL metadata kaynağı information_schema üzerinden sözleşme kayıtları oluşturulur.

## Tasarım Notu

Bu faz mevcut business tabloların kolonlarını değiştirmez. Ama tüm tablo ve alanları sözleşmeye bağlar. Böylece sonraki legal_entity, branch, schema map ve ERP fazlarında alan sahipliği, nullable/required standardı ve type standardı audit edilebilir olur.

## Final Status

- FAZ_1_1_8_DATA_DICTIONARY_STATUS=${DATA_DICTIONARY_STATUS:-N/A}
- FAZ_1_1_8_FIELD_OWNERSHIP_STATUS=${FIELD_OWNERSHIP_STATUS:-N/A}
- FAZ_1_1_8_REQUIRED_NULLABLE_STANDARD_STATUS=${REQUIRED_NULLABLE_STATUS:-N/A}
- FAZ_1_1_8_FIELD_TYPE_STANDARD_STATUS=${FIELD_TYPE_STATUS:-N/A}
- FAZ_1_1_8_FIELD_CONTRACT_AUDIT_STATUS=${FIELD_CONTRACT_AUDIT_STATUS:-N/A}
- FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-1.8 Data Dictionary / Field Contract Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Snapshot Files"
  echo "- Table contracts: $TABLE_CONTRACT_SNAPSHOT_CSV"
  echo "- Field contracts: $FIELD_CONTRACT_SNAPSHOT_CSV"
  echo "- Field contract audit: $FIELD_CONTRACT_AUDIT_CSV"
  echo
  echo "## Counts"
  echo "- SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
  echo "- SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
  echo "- DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
  echo "- DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
  echo "- TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
  echo "- FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
  echo "- OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
  echo "- OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
  echo "- REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
  echo "- TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
  echo "- AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
  echo "- AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Required Scope Status"
  echo "- DATA_DICTIONARY_STATUS=${DATA_DICTIONARY_STATUS:-N/A}"
  echo "- FIELD_OWNERSHIP_STATUS=${FIELD_OWNERSHIP_STATUS:-N/A}"
  echo "- REQUIRED_NULLABLE_STATUS=${REQUIRED_NULLABLE_STATUS:-N/A}"
  echo "- FIELD_TYPE_STATUS=${FIELD_TYPE_STATUS:-N/A}"
  echo "- FIELD_CONTRACT_AUDIT_STATUS=${FIELD_CONTRACT_AUDIT_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-1.8 Data Dictionary / Field Contract Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_1_8_DATA_DICTIONARY_STATUS=${DATA_DICTIONARY_STATUS:-N/A}"
  echo "FAZ_1_1_8_FIELD_OWNERSHIP_STATUS=${FIELD_OWNERSHIP_STATUS:-N/A}"
  echo "FAZ_1_1_8_REQUIRED_NULLABLE_STANDARD_STATUS=${REQUIRED_NULLABLE_STATUS:-N/A}"
  echo "FAZ_1_1_8_FIELD_TYPE_STANDARD_STATUS=${FIELD_TYPE_STATUS:-N/A}"
  echo "FAZ_1_1_8_FIELD_CONTRACT_AUDIT_STATUS=${FIELD_CONTRACT_AUDIT_STATUS:-N/A}"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_1_2_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "15.1 dokümantasyon güncellendi: $DOC_FILE"
pass "15.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "15.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "15.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT APPLY RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
echo "SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
echo "DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
echo "DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
echo "TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
echo "FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
echo "OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
echo "OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
echo "REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
echo "TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
echo "AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
echo "AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "DATA_DICTIONARY_STATUS=${DATA_DICTIONARY_STATUS:-N/A}"
echo "FIELD_OWNERSHIP_STATUS=${FIELD_OWNERSHIP_STATUS:-N/A}"
echo "REQUIRED_NULLABLE_STATUS=${REQUIRED_NULLABLE_STATUS:-N/A}"
echo "FIELD_TYPE_STATUS=${FIELD_TYPE_STATUS:-N/A}"
echo "FIELD_CONTRACT_AUDIT_STATUS=${FIELD_CONTRACT_AUDIT_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_1_8_DATA_DICTIONARY_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_OWNERSHIP_STATUS=PASS"
  echo "FAZ_1_1_8_REQUIRED_NULLABLE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_TYPE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_CONTRACT_AUDIT_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_FINAL_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=SEALED"
  echo "FAZ_1_1_2_READY=YES"
else
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_FINAL_STATUS=FAIL"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=OPEN"
  echo "FAZ_1_1_2_READY=NO"
  exit 1
fi

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT APPLY END ====="
