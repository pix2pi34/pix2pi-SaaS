BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;
CREATE SCHEMA IF NOT EXISTS inventory;

CREATE OR REPLACE FUNCTION org.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION inventory.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_id_tenant_id_fk
  ON org.legal_entities(id, tenant_id);

DO $$
BEGIN
  IF to_regclass('org.branches') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='tenant_id'
     ) THEN
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS ux_org_branches_id_tenant_id_fk ON org.branches(id, tenant_id)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS org.business_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  business_code text NOT NULL,
  location_code text NOT NULL,
  location_name text NOT NULL,
  location_type text NOT NULL,
  ownership_type text NOT NULL DEFAULT 'COMPANY_OWNED',
  operation_type text NOT NULL DEFAULT 'COMPANY_OPERATED',
  inventory_enabled boolean NOT NULL DEFAULT false,
  sales_enabled boolean NOT NULL DEFAULT false,
  purchasing_enabled boolean NOT NULL DEFAULT false,
  is_default boolean NOT NULL DEFAULT false,
  address_line text,
  district text,
  city text,
  country_code text NOT NULL DEFAULT 'TR',
  postal_code text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  capacity_profile jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'ACTIVE',
  lifecycle_reason text,
  location_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS location_code text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS location_name text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS location_type text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS ownership_type text DEFAULT 'COMPANY_OWNED';
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS operation_type text DEFAULT 'COMPANY_OPERATED';
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS inventory_enabled boolean DEFAULT false;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS sales_enabled boolean DEFAULT false;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS purchasing_enabled boolean DEFAULT false;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS is_default boolean DEFAULT false;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS address_line text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS district text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS country_code text DEFAULT 'TR';
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS postal_code text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS latitude numeric(10,7);
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS longitude numeric(10,7);
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS capacity_profile jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS location_audit_ref text;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.business_locations ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.business_locations SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.business_locations SET business_code='LOC_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.business_locations SET location_code=business_code WHERE location_code IS NULL OR btrim(location_code::text)='';
UPDATE org.business_locations SET location_name=location_code WHERE location_name IS NULL OR btrim(location_name::text)='';
UPDATE org.business_locations SET location_type='OTHER' WHERE location_type IS NULL OR btrim(location_type::text)='';
UPDATE org.business_locations SET ownership_type='COMPANY_OWNED' WHERE ownership_type IS NULL OR btrim(ownership_type::text)='';
UPDATE org.business_locations SET operation_type='COMPANY_OPERATED' WHERE operation_type IS NULL OR btrim(operation_type::text)='';
UPDATE org.business_locations SET inventory_enabled=false WHERE inventory_enabled IS NULL;
UPDATE org.business_locations SET sales_enabled=false WHERE sales_enabled IS NULL;
UPDATE org.business_locations SET purchasing_enabled=false WHERE purchasing_enabled IS NULL;
UPDATE org.business_locations SET is_default=false WHERE is_default IS NULL;
UPDATE org.business_locations SET country_code='TR' WHERE country_code IS NULL OR btrim(country_code::text)='';
UPDATE org.business_locations SET capacity_profile='{}'::jsonb WHERE capacity_profile IS NULL;
UPDATE org.business_locations SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.business_locations SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.business_locations SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.business_locations SET created_at=now() WHERE created_at IS NULL;
UPDATE org.business_locations SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='business_locations'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.business_locations ADD CONSTRAINT pk_org_business_locations PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_id_tenant_id_fk
  ON org.business_locations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_tenant_business_code
  ON org.business_locations(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_tenant_location_code
  ON org.business_locations(tenant_id, location_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_org_business_locations_tenant_id ON org.business_locations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_legal_entity_id ON org.business_locations(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_branch_id ON org.business_locations(branch_id);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_location_type ON org.business_locations(location_type);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_ownership_operation ON org.business_locations(ownership_type, operation_type);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_inventory_enabled ON org.business_locations(inventory_enabled);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_status ON org.business_locations(status);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_city_district ON org.business_locations(city, district);
CREATE INDEX IF NOT EXISTS idx_org_business_locations_audit_ref ON org.business_locations(location_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_business_locations_legal_entity_tenant'
      AND conrelid='org.business_locations'::regclass
  ) THEN
    ALTER TABLE org.business_locations
      ADD CONSTRAINT fk_org_business_locations_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF to_regclass('org.branches') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='tenant_id'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname='fk_org_business_locations_branch_tenant'
         AND conrelid='org.business_locations'::regclass
     ) THEN
    ALTER TABLE org.business_locations
      ADD CONSTRAINT fk_org_business_locations_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_required_fields;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND location_code IS NOT NULL AND btrim(location_code::text) <> ''
    AND location_name IS NOT NULL AND btrim(location_name::text) <> ''
    AND location_type IS NOT NULL AND btrim(location_type::text) <> ''
    AND ownership_type IS NOT NULL AND btrim(ownership_type::text) <> ''
    AND operation_type IS NOT NULL AND btrim(operation_type::text) <> ''
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_location_type;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_location_type
  CHECK (
    location_type IN (
      'STORE',
      'FACILITY',
      'WAREHOUSE',
      'DARK_STORE',
      'PICKUP_POINT',
      'OFFICE',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_ownership_type;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_ownership_type
  CHECK (
    ownership_type IN (
      'COMPANY_OWNED',
      'FRANCHISE_OWNED',
      'PARTNER_OWNED',
      'LEASED',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_operation_type;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_operation_type
  CHECK (
    operation_type IN (
      'COMPANY_OPERATED',
      'FRANCHISE_OPERATED',
      'PARTNER_OPERATED',
      'THIRD_PARTY_OPERATED',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_status;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','CLOSED')
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_inventory_location_type;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_inventory_location_type
  CHECK (
    inventory_enabled = false
    OR location_type IN ('STORE','FACILITY','WAREHOUSE','DARK_STORE')
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_geo_range;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_geo_range
  CHECK (
    (latitude IS NULL OR (latitude >= -90 AND latitude <= 90))
    AND (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))
  ) NOT VALID;

ALTER TABLE org.business_locations DROP CONSTRAINT IF EXISTS ck_org_business_locations_audit_for_closed;
ALTER TABLE org.business_locations
  ADD CONSTRAINT ck_org_business_locations_audit_for_closed
  CHECK (
    status <> 'CLOSED'
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND location_audit_ref IS NOT NULL
      AND btrim(location_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_business_locations_set_updated_at ON org.business_locations;
CREATE TRIGGER trg_org_business_locations_set_updated_at
BEFORE UPDATE ON org.business_locations
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.business_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.business_locations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_business_locations_tenant_rw ON org.business_locations;
CREATE POLICY allow_org_business_locations_tenant_rw
ON org.business_locations
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

CREATE TABLE IF NOT EXISTS inventory.location_inventory_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  location_id uuid NOT NULL,
  inventory_scope text NOT NULL DEFAULT 'ON_HAND_STOCK',
  stock_tracking_enabled boolean NOT NULL DEFAULT true,
  reservation_enabled boolean NOT NULL DEFAULT false,
  default_stock_account_code text,
  default_cogs_account_code text,
  status text NOT NULL DEFAULT 'ACTIVE',
  relation_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS location_id uuid;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS inventory_scope text DEFAULT 'ON_HAND_STOCK';
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS stock_tracking_enabled boolean DEFAULT true;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS reservation_enabled boolean DEFAULT false;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS default_stock_account_code text;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS default_cogs_account_code text;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS relation_audit_ref text;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE inventory.location_inventory_links ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE inventory.location_inventory_links SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE inventory.location_inventory_links SET inventory_scope='ON_HAND_STOCK' WHERE inventory_scope IS NULL OR btrim(inventory_scope::text)='';
UPDATE inventory.location_inventory_links SET stock_tracking_enabled=true WHERE stock_tracking_enabled IS NULL;
UPDATE inventory.location_inventory_links SET reservation_enabled=false WHERE reservation_enabled IS NULL;
UPDATE inventory.location_inventory_links SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE inventory.location_inventory_links SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE inventory.location_inventory_links SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE inventory.location_inventory_links SET created_at=now() WHERE created_at IS NULL;
UPDATE inventory.location_inventory_links SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='inventory'
      AND table_name='location_inventory_links'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE inventory.location_inventory_links ADD CONSTRAINT pk_inventory_location_inventory_links PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_inventory_location_links_location_scope
  ON inventory.location_inventory_links(tenant_id, location_id, inventory_scope)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inventory_location_links_tenant_id ON inventory.location_inventory_links(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location_links_legal_entity_id ON inventory.location_inventory_links(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location_links_branch_id ON inventory.location_inventory_links(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location_links_location_id ON inventory.location_inventory_links(location_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location_links_status ON inventory.location_inventory_links(status);
CREATE INDEX IF NOT EXISTS idx_inventory_location_links_audit_ref ON inventory.location_inventory_links(relation_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_inventory_location_links_location_tenant'
      AND conrelid='inventory.location_inventory_links'::regclass
  ) THEN
    ALTER TABLE inventory.location_inventory_links
      ADD CONSTRAINT fk_inventory_location_links_location_tenant
      FOREIGN KEY (location_id, tenant_id)
      REFERENCES org.business_locations(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_inventory_location_links_legal_entity_tenant'
      AND conrelid='inventory.location_inventory_links'::regclass
  ) THEN
    ALTER TABLE inventory.location_inventory_links
      ADD CONSTRAINT fk_inventory_location_links_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF to_regclass('org.branches') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='tenant_id'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname='fk_inventory_location_links_branch_tenant'
         AND conrelid='inventory.location_inventory_links'::regclass
     ) THEN
    ALTER TABLE inventory.location_inventory_links
      ADD CONSTRAINT fk_inventory_location_links_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE inventory.location_inventory_links DROP CONSTRAINT IF EXISTS ck_inventory_location_links_required_fields;
ALTER TABLE inventory.location_inventory_links
  ADD CONSTRAINT ck_inventory_location_links_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND location_id IS NOT NULL
    AND inventory_scope IS NOT NULL
    AND btrim(inventory_scope::text) <> ''
    AND status IS NOT NULL
    AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE inventory.location_inventory_links DROP CONSTRAINT IF EXISTS ck_inventory_location_links_scope;
ALTER TABLE inventory.location_inventory_links
  ADD CONSTRAINT ck_inventory_location_links_scope
  CHECK (
    inventory_scope IN (
      'ON_HAND_STOCK',
      'RESERVATION',
      'IN_TRANSIT',
      'DAMAGED',
      'RETURNED',
      'CONSIGNMENT'
    )
  ) NOT VALID;

ALTER TABLE inventory.location_inventory_links DROP CONSTRAINT IF EXISTS ck_inventory_location_links_status;
ALTER TABLE inventory.location_inventory_links
  ADD CONSTRAINT ck_inventory_location_links_status
  CHECK (
    status IN ('ACTIVE','INACTIVE','SUSPENDED','CLOSED')
  ) NOT VALID;

ALTER TABLE inventory.location_inventory_links DROP CONSTRAINT IF EXISTS ck_inventory_location_links_stock_account_format;
ALTER TABLE inventory.location_inventory_links
  ADD CONSTRAINT ck_inventory_location_links_stock_account_format
  CHECK (
    default_stock_account_code IS NULL
    OR default_stock_account_code ~ '^[0-9]{3}(\\.[0-9]{1,4})?$'
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_inventory_location_links_set_updated_at ON inventory.location_inventory_links;
CREATE TRIGGER trg_inventory_location_links_set_updated_at
BEFORE UPDATE ON inventory.location_inventory_links
FOR EACH ROW
EXECUTE FUNCTION inventory.set_updated_at();

ALTER TABLE inventory.location_inventory_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory.location_inventory_links FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_inventory_location_links_tenant_rw ON inventory.location_inventory_links;
CREATE POLICY allow_inventory_location_links_tenant_rw
ON inventory.location_inventory_links
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
      'business_locations',
      'organization_location',
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
          AND c.table_name='business_locations'
      ),
      jsonb_build_object('phase','FAZ_1_3_4','source','store_facility_warehouse_locations'),
      now()
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
      'inventory',
      'location_inventory_links',
      'inventory_location_relation',
      'RELATION_TABLE',
      'ACTIVE',
      true,
      true,
      true,
      false,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='inventory'
          AND c.table_name='location_inventory_links'
      ),
      jsonb_build_object('phase','FAZ_1_3_4','source','store_facility_warehouse_inventory_relation'),
      now()
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
GRANT USAGE ON SCHEMA inventory TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON org.business_locations TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON inventory.location_inventory_links TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;
GRANT EXECUTE ON FUNCTION inventory.set_updated_at() TO PUBLIC;

COMMIT;
