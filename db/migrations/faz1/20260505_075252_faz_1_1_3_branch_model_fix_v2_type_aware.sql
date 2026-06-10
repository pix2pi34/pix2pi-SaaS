BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;

CREATE OR REPLACE FUNCTION org.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TABLE IF NOT EXISTS org.branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  legal_entity_id uuid,
  branch_id uuid,
  business_code text,
  branch_code text,
  branch_name text,
  branch_type text,
  phone text,
  email text,
  address_line text,
  district text,
  city text,
  country_code text DEFAULT 'TR',
  postal_code text,
  scope_key text,
  is_default boolean DEFAULT false,
  status text,
  metadata jsonb DEFAULT '{}'::jsonb,
  audit_metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS branch_code text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS branch_name text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS branch_type text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS address_line text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS district text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS country_code text DEFAULT 'TR';
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS postal_code text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS scope_key text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS is_default boolean DEFAULT false;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS status text;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.branches ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.branches SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.branches SET branch_id=id WHERE branch_id IS NULL;
UPDATE org.branches SET business_code='BRANCH_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.branches SET branch_code=business_code WHERE branch_code IS NULL OR btrim(branch_code)='';
UPDATE org.branches SET branch_type=:'branch_type' WHERE branch_type IS NULL OR btrim(branch_type::text)='';
UPDATE org.branches SET country_code='TR' WHERE country_code IS NULL OR btrim(country_code)='';
UPDATE org.branches SET scope_key='branch:' || id::text WHERE scope_key IS NULL OR btrim(scope_key)='';
UPDATE org.branches SET is_default=false WHERE is_default IS NULL;
UPDATE org.branches SET status=:'branch_status' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.branches SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.branches SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.branches SET created_at=now() WHERE created_at IS NULL;
UPDATE org.branches SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='branches'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.branches ADD CONSTRAINT pk_org_branches PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_branches_id_tenant_id_fk
  ON org.branches(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_branches_tenant_business_code
  ON org.branches(tenant_id, business_code)
  WHERE deleted_at IS NULL AND tenant_id IS NOT NULL AND business_code IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_branches_tenant_branch_code
  ON org.branches(tenant_id, branch_code)
  WHERE deleted_at IS NULL AND tenant_id IS NOT NULL AND branch_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_branches_tenant_id ON org.branches(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_branches_legal_entity_id ON org.branches(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_branches_scope_key ON org.branches(scope_key);
CREATE INDEX IF NOT EXISTS idx_org_branches_status ON org.branches(status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_branches_legal_entity_tenant'
      AND conrelid='org.branches'::regclass
  ) THEN
    ALTER TABLE org.branches
      ADD CONSTRAINT fk_org_branches_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  DROP CONSTRAINT IF EXISTS ck_org_branches_required_fields;
  ALTER TABLE org.branches
    ADD CONSTRAINT ck_org_branches_required_fields
    CHECK (
      tenant_id IS NOT NULL
      AND legal_entity_id IS NOT NULL
      AND id IS NOT NULL
      AND branch_id IS NOT NULL
      AND business_code IS NOT NULL AND btrim(business_code) <> ''
      AND branch_code IS NOT NULL AND btrim(branch_code) <> ''
      AND branch_name IS NOT NULL AND btrim(branch_name) <> ''
      AND address_line IS NOT NULL AND btrim(address_line) <> ''
      AND scope_key IS NOT NULL AND btrim(scope_key) <> ''
    ) NOT VALID;

  DROP CONSTRAINT IF EXISTS ck_org_branches_branch_type;
  ALTER TABLE org.branches
    ADD CONSTRAINT ck_org_branches_branch_type
    CHECK (branch_type IS NOT NULL AND btrim(branch_type::text) <> '') NOT VALID;

  DROP CONSTRAINT IF EXISTS ck_org_branches_status;
  ALTER TABLE org.branches
    ADD CONSTRAINT ck_org_branches_status
    CHECK (status IS NOT NULL AND btrim(status::text) <> '') NOT VALID;
END $$;

DROP TRIGGER IF EXISTS trg_org_branches_set_updated_at ON org.branches;
CREATE TRIGGER trg_org_branches_set_updated_at
BEFORE UPDATE ON org.branches
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

CREATE TABLE IF NOT EXISTS org.branch_addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  legal_entity_id uuid,
  branch_id uuid,
  business_code text,
  address_type text,
  address_line text,
  district text,
  city text,
  country_code text DEFAULT 'TR',
  postal_code text,
  is_primary boolean DEFAULT true,
  status text,
  metadata jsonb DEFAULT '{}'::jsonb,
  audit_metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS address_type text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS address_line text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS district text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS country_code text DEFAULT 'TR';
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS postal_code text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS is_primary boolean DEFAULT true;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS status text;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.branch_addresses ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.branch_addresses SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.branch_addresses SET business_code='BRANCH_ADDRESS_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.branch_addresses SET address_type=:'branch_address_type' WHERE address_type IS NULL OR btrim(address_type::text)='';
UPDATE org.branch_addresses SET country_code='TR' WHERE country_code IS NULL OR btrim(country_code)='';
UPDATE org.branch_addresses SET is_primary=true WHERE is_primary IS NULL;
UPDATE org.branch_addresses SET status=:'branch_address_status' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.branch_addresses SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.branch_addresses SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.branch_addresses SET created_at=now() WHERE created_at IS NULL;
UPDATE org.branch_addresses SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='branch_addresses'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.branch_addresses ADD CONSTRAINT pk_org_branch_addresses PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_branch_addresses_tenant_business_code
  ON org.branch_addresses(tenant_id, business_code)
  WHERE deleted_at IS NULL AND tenant_id IS NOT NULL AND business_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_branch_addresses_tenant_id ON org.branch_addresses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_branch_addresses_legal_entity_id ON org.branch_addresses(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_branch_addresses_branch_id ON org.branch_addresses(branch_id);
CREATE INDEX IF NOT EXISTS idx_org_branch_addresses_status ON org.branch_addresses(status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_branch_addresses_branch_tenant'
      AND conrelid='org.branch_addresses'::regclass
  ) THEN
    ALTER TABLE org.branch_addresses
      ADD CONSTRAINT fk_org_branch_addresses_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_branch_addresses_legal_entity_tenant'
      AND conrelid='org.branch_addresses'::regclass
  ) THEN
    ALTER TABLE org.branch_addresses
      ADD CONSTRAINT fk_org_branch_addresses_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  DROP CONSTRAINT IF EXISTS ck_org_branch_addresses_required_fields;
  ALTER TABLE org.branch_addresses
    ADD CONSTRAINT ck_org_branch_addresses_required_fields
    CHECK (
      tenant_id IS NOT NULL
      AND legal_entity_id IS NOT NULL
      AND branch_id IS NOT NULL
      AND business_code IS NOT NULL AND btrim(business_code) <> ''
      AND address_line IS NOT NULL AND btrim(address_line) <> ''
    ) NOT VALID;

  DROP CONSTRAINT IF EXISTS ck_org_branch_addresses_address_type;
  ALTER TABLE org.branch_addresses
    ADD CONSTRAINT ck_org_branch_addresses_address_type
    CHECK (address_type IS NOT NULL AND btrim(address_type::text) <> '') NOT VALID;

  DROP CONSTRAINT IF EXISTS ck_org_branch_addresses_status;
  ALTER TABLE org.branch_addresses
    ADD CONSTRAINT ck_org_branch_addresses_status
    CHECK (status IS NOT NULL AND btrim(status::text) <> '') NOT VALID;
END $$;

DROP TRIGGER IF EXISTS trg_org_branch_addresses_set_updated_at ON org.branch_addresses;
CREATE TRIGGER trg_org_branch_addresses_set_updated_at
BEFORE UPDATE ON org.branch_addresses
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.branches FORCE ROW LEVEL SECURITY;
ALTER TABLE org.branch_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.branch_addresses FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_branches_tenant_rw ON org.branches;
CREATE POLICY allow_org_branches_tenant_rw
ON org.branches
FOR ALL
USING (
  tenant_id::text = current_setting('app.tenant_id', true)
  OR tenant_id::text = current_setting('app.current_tenant_id', true)
  OR current_setting('app.bypass_tenant_rls', true) = 'on'
)
WITH CHECK (
  tenant_id::text = current_setting('app.tenant_id', true)
  OR tenant_id::text = current_setting('app.current_tenant_id', true)
  OR current_setting('app.bypass_tenant_rls', true) = 'on'
);

DROP POLICY IF EXISTS allow_org_branch_addresses_tenant_rw ON org.branch_addresses;
CREATE POLICY allow_org_branch_addresses_tenant_rw
ON org.branch_addresses
FOR ALL
USING (
  tenant_id::text = current_setting('app.tenant_id', true)
  OR tenant_id::text = current_setting('app.current_tenant_id', true)
  OR current_setting('app.bypass_tenant_rls', true) = 'on'
)
WITH CHECK (
  tenant_id::text = current_setting('app.tenant_id', true)
  OR tenant_id::text = current_setting('app.current_tenant_id', true)
  OR current_setting('app.bypass_tenant_rls', true) = 'on'
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='app_dictionary'
      AND table_name='table_contracts'
  ) THEN
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
      'org',
      t.table_name,
      'core_model',
      'BASE_TABLE',
      'ACTIVE',
      true,
      true,
      true,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='org'
          AND c.table_name=t.table_name
      ),
      jsonb_build_object('phase','FAZ_1_1_3_FIX_V2','source','branch_model'),
      now()
    FROM (VALUES ('branches'), ('branch_addresses')) AS t(table_name)
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
  END IF;
END $$;

GRANT USAGE ON SCHEMA org TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON org.branches TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON org.branch_addresses TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
