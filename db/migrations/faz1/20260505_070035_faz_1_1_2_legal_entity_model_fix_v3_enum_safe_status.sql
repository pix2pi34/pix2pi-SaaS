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

CREATE TABLE IF NOT EXISTS org.legal_entities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  legal_entity_id uuid,
  branch_id uuid,
  business_code text,
  legal_name text,
  trade_name text,
  tax_number text,
  tax_office text,
  mersis_no text,
  phone text,
  email text,
  address_line text,
  district text,
  city text,
  country_code text DEFAULT 'TR',
  postal_code text,
  status text,
  metadata jsonb DEFAULT '{}'::jsonb,
  audit_metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS legal_name text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS trade_name text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS tax_number text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS tax_office text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS mersis_no text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS address_line text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS district text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS country_code text DEFAULT 'TR';
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS postal_code text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS status text;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.legal_entities ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.legal_entities SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.legal_entities SET business_code='LEGAL_ENTITY_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.legal_entities SET legal_entity_id=id WHERE legal_entity_id IS NULL;
UPDATE org.legal_entities SET country_code='TR' WHERE country_code IS NULL OR btrim(country_code)='';
UPDATE org.legal_entities SET status=:'legal_entity_status' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.legal_entities SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.legal_entities SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.legal_entities SET created_at=now() WHERE created_at IS NULL;
UPDATE org.legal_entities SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='legal_entities'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.legal_entities ADD CONSTRAINT pk_org_legal_entities PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_id_tenant_id_fk
  ON org.legal_entities(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_tenant_business_code
  ON org.legal_entities(tenant_id, business_code)
  WHERE deleted_at IS NULL AND tenant_id IS NOT NULL AND business_code IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_tenant_tax_number
  ON org.legal_entities(tenant_id, tax_number)
  WHERE deleted_at IS NULL AND tenant_id IS NOT NULL AND tax_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_legal_entities_tenant_id
  ON org.legal_entities(tenant_id);

CREATE INDEX IF NOT EXISTS idx_org_legal_entities_legal_name
  ON org.legal_entities(legal_name);

CREATE INDEX IF NOT EXISTS idx_org_legal_entities_status
  ON org.legal_entities(status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entities_required_company_fields'
      AND conrelid='org.legal_entities'::regclass
  ) THEN
    ALTER TABLE org.legal_entities
      ADD CONSTRAINT ck_org_legal_entities_required_company_fields
      CHECK (
        tenant_id IS NOT NULL
        AND id IS NOT NULL
        AND business_code IS NOT NULL AND btrim(business_code) <> ''
        AND legal_name IS NOT NULL AND btrim(legal_name) <> ''
        AND tax_number IS NOT NULL AND btrim(tax_number) <> ''
        AND tax_office IS NOT NULL AND btrim(tax_office) <> ''
        AND address_line IS NOT NULL AND btrim(address_line) <> ''
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entities_status'
      AND conrelid='org.legal_entities'::regclass
  ) THEN
    ALTER TABLE org.legal_entities
      ADD CONSTRAINT ck_org_legal_entities_status
      CHECK (status IS NOT NULL) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entities_country_code'
      AND conrelid='org.legal_entities'::regclass
  ) THEN
    ALTER TABLE org.legal_entities
      ADD CONSTRAINT ck_org_legal_entities_country_code
      CHECK (country_code ~ '^[A-Z]{2}$') NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entities_tax_number_format'
      AND conrelid='org.legal_entities'::regclass
  ) THEN
    ALTER TABLE org.legal_entities
      ADD CONSTRAINT ck_org_legal_entities_tax_number_format
      CHECK (tax_number IS NULL OR tax_number ~ '^[0-9A-Z_-]{5,32}$') NOT VALID;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_org_legal_entities_set_updated_at ON org.legal_entities;
CREATE TRIGGER trg_org_legal_entities_set_updated_at
BEFORE UPDATE ON org.legal_entities
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

CREATE TABLE IF NOT EXISTS org.legal_entity_addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  legal_entity_id uuid,
  branch_id uuid,
  business_code text,
  address_type text DEFAULT 'PRIMARY',
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

ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS address_type text DEFAULT 'PRIMARY';
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS address_line text;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS district text;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS country_code text DEFAULT 'TR';
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS postal_code text;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS is_primary boolean DEFAULT true;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS status text;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.legal_entity_addresses ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.legal_entity_addresses SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.legal_entity_addresses SET business_code='LEGAL_ENTITY_ADDRESS_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.legal_entity_addresses SET country_code='TR' WHERE country_code IS NULL OR btrim(country_code)='';
UPDATE org.legal_entity_addresses SET address_type='PRIMARY' WHERE address_type IS NULL OR btrim(address_type)='';
UPDATE org.legal_entity_addresses SET status=:'legal_entity_address_status' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.legal_entity_addresses SET is_primary=true WHERE is_primary IS NULL;
UPDATE org.legal_entity_addresses SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.legal_entity_addresses SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.legal_entity_addresses SET created_at=now() WHERE created_at IS NULL;
UPDATE org.legal_entity_addresses SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='legal_entity_addresses'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.legal_entity_addresses ADD CONSTRAINT pk_org_legal_entity_addresses PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entity_addresses_tenant_business_code
  ON org.legal_entity_addresses(tenant_id, business_code)
  WHERE deleted_at IS NULL AND tenant_id IS NOT NULL AND business_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_legal_entity_addresses_tenant_id
  ON org.legal_entity_addresses(tenant_id);

CREATE INDEX IF NOT EXISTS idx_org_legal_entity_addresses_legal_entity_id
  ON org.legal_entity_addresses(legal_entity_id);

CREATE INDEX IF NOT EXISTS idx_org_legal_entity_addresses_status
  ON org.legal_entity_addresses(status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_legal_entity_addresses_legal_entity_tenant'
      AND conrelid='org.legal_entity_addresses'::regclass
  ) THEN
    ALTER TABLE org.legal_entity_addresses
      ADD CONSTRAINT fk_org_legal_entity_addresses_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entity_addresses_required_fields'
      AND conrelid='org.legal_entity_addresses'::regclass
  ) THEN
    ALTER TABLE org.legal_entity_addresses
      ADD CONSTRAINT ck_org_legal_entity_addresses_required_fields
      CHECK (
        tenant_id IS NOT NULL
        AND legal_entity_id IS NOT NULL
        AND business_code IS NOT NULL AND btrim(business_code) <> ''
        AND address_line IS NOT NULL AND btrim(address_line) <> ''
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entity_addresses_status'
      AND conrelid='org.legal_entity_addresses'::regclass
  ) THEN
    ALTER TABLE org.legal_entity_addresses
      ADD CONSTRAINT ck_org_legal_entity_addresses_status
      CHECK (status IS NOT NULL) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='ck_org_legal_entity_addresses_address_type'
      AND conrelid='org.legal_entity_addresses'::regclass
  ) THEN
    ALTER TABLE org.legal_entity_addresses
      ADD CONSTRAINT ck_org_legal_entity_addresses_address_type
      CHECK (address_type IN ('PRIMARY','BILLING','SHIPPING','REGISTERED','OTHER')) NOT VALID;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_org_legal_entity_addresses_set_updated_at ON org.legal_entity_addresses;
CREATE TRIGGER trg_org_legal_entity_addresses_set_updated_at
BEFORE UPDATE ON org.legal_entity_addresses
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.legal_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.legal_entities FORCE ROW LEVEL SECURITY;
ALTER TABLE org.legal_entity_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.legal_entity_addresses FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_legal_entities_tenant_rw ON org.legal_entities;
CREATE POLICY allow_org_legal_entities_tenant_rw
ON org.legal_entities
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

DROP POLICY IF EXISTS allow_org_legal_entity_addresses_tenant_rw ON org.legal_entity_addresses;
CREATE POLICY allow_org_legal_entity_addresses_tenant_rw
ON org.legal_entity_addresses
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
      jsonb_build_object('phase','FAZ_1_1_2_FIX_V3','source','legal_entity_model'),
      now()
    FROM (VALUES ('legal_entities'), ('legal_entity_addresses')) AS t(table_name)
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
GRANT SELECT, INSERT, UPDATE ON org.legal_entities TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON org.legal_entity_addresses TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
