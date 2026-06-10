BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;
CREATE SCHEMA IF NOT EXISTS franchise;

CREATE OR REPLACE FUNCTION org.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_id_tenant_id_fk
  ON org.legal_entities(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_id_tenant_id_fk
  ON org.business_locations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_franchise_agreements_id_tenant_id_fk
  ON franchise.agreements(id, tenant_id);

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

CREATE TABLE IF NOT EXISTS org.location_operation_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  location_id uuid NOT NULL,
  franchise_agreement_id uuid,
  business_code text NOT NULL,
  operation_profile_code text NOT NULL,
  business_model text NOT NULL,
  ownership_type text NOT NULL,
  operation_type text NOT NULL,
  reporting_effect text NOT NULL,
  permission_effect text NOT NULL,
  revenue_owner_entity_id uuid NOT NULL,
  operator_entity_id uuid NOT NULL,
  inventory_owner_entity_id uuid NOT NULL,
  accounting_responsibility text NOT NULL DEFAULT 'LEGAL_ENTITY_BOOKS',
  inventory_responsibility text NOT NULL DEFAULT 'LOCATION_OPERATOR',
  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',
  lifecycle_reason text,
  operation_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS location_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS franchise_agreement_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operation_profile_code text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS business_model text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS ownership_type text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operation_type text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS reporting_effect text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS permission_effect text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS revenue_owner_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operator_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS inventory_owner_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS accounting_responsibility text DEFAULT 'LEGAL_ENTITY_BOOKS';
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS inventory_responsibility text DEFAULT 'LOCATION_OPERATOR';
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operation_audit_ref text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.location_operation_profiles SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.location_operation_profiles SET business_code='OP_PROFILE_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.location_operation_profiles SET operation_profile_code=business_code WHERE operation_profile_code IS NULL OR btrim(operation_profile_code::text)='';
UPDATE org.location_operation_profiles SET business_model='COMPANY_BRANCH' WHERE business_model IS NULL OR btrim(business_model::text)='';
UPDATE org.location_operation_profiles SET ownership_type='COMPANY_OWNED' WHERE ownership_type IS NULL OR btrim(ownership_type::text)='';
UPDATE org.location_operation_profiles SET operation_type='COMPANY_OPERATED' WHERE operation_type IS NULL OR btrim(operation_type::text)='';
UPDATE org.location_operation_profiles SET reporting_effect='CONSOLIDATED' WHERE reporting_effect IS NULL OR btrim(reporting_effect::text)='';
UPDATE org.location_operation_profiles SET permission_effect='INTERNAL_FULL_SCOPE' WHERE permission_effect IS NULL OR btrim(permission_effect::text)='';
UPDATE org.location_operation_profiles SET accounting_responsibility='LEGAL_ENTITY_BOOKS' WHERE accounting_responsibility IS NULL OR btrim(accounting_responsibility::text)='';
UPDATE org.location_operation_profiles SET inventory_responsibility='LOCATION_OPERATOR' WHERE inventory_responsibility IS NULL OR btrim(inventory_responsibility::text)='';
UPDATE org.location_operation_profiles SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.location_operation_profiles SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.location_operation_profiles SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.location_operation_profiles SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.location_operation_profiles SET created_at=now() WHERE created_at IS NULL;
UPDATE org.location_operation_profiles SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='location_operation_profiles'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.location_operation_profiles ADD CONSTRAINT pk_org_location_operation_profiles PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_id_tenant_id_fk
  ON org.location_operation_profiles(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_tenant_business_code
  ON org.location_operation_profiles(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_tenant_profile_code
  ON org.location_operation_profiles(tenant_id, operation_profile_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_active_location
  ON org.location_operation_profiles(tenant_id, location_id)
  WHERE deleted_at IS NULL
    AND status='ACTIVE'
    AND effective_to IS NULL;

CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_tenant_id ON org.location_operation_profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_legal_entity_id ON org.location_operation_profiles(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_branch_id ON org.location_operation_profiles(branch_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_location_id ON org.location_operation_profiles(location_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_franchise_agreement_id ON org.location_operation_profiles(franchise_agreement_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_business_model ON org.location_operation_profiles(business_model);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_ownership_operation ON org.location_operation_profiles(ownership_type, operation_type);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_reporting_effect ON org.location_operation_profiles(reporting_effect);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_permission_effect ON org.location_operation_profiles(permission_effect);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_status ON org.location_operation_profiles(status);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_effective_dates ON org.location_operation_profiles(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_audit_ref ON org.location_operation_profiles(operation_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_legal_entity_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_location_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_location_tenant
      FOREIGN KEY (location_id, tenant_id)
      REFERENCES org.business_locations(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_revenue_owner_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_revenue_owner_tenant
      FOREIGN KEY (revenue_owner_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_operator_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_operator_tenant
      FOREIGN KEY (operator_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_inventory_owner_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_inventory_owner_tenant
      FOREIGN KEY (inventory_owner_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_franchise_agreement_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_franchise_agreement_tenant
      FOREIGN KEY (franchise_agreement_id, tenant_id)
      REFERENCES franchise.agreements(id, tenant_id)
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
       WHERE conname='fk_org_location_operation_profiles_branch_tenant'
         AND conrelid='org.location_operation_profiles'::regclass
     ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_required_fields;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND location_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND operation_profile_code IS NOT NULL AND btrim(operation_profile_code::text) <> ''
    AND business_model IS NOT NULL AND btrim(business_model::text) <> ''
    AND ownership_type IS NOT NULL AND btrim(ownership_type::text) <> ''
    AND operation_type IS NOT NULL AND btrim(operation_type::text) <> ''
    AND reporting_effect IS NOT NULL AND btrim(reporting_effect::text) <> ''
    AND permission_effect IS NOT NULL AND btrim(permission_effect::text) <> ''
    AND revenue_owner_entity_id IS NOT NULL
    AND operator_entity_id IS NOT NULL
    AND inventory_owner_entity_id IS NOT NULL
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_business_model;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_business_model
  CHECK (
    business_model IN (
      'COMPANY_BRANCH',
      'FRANCHISE_STORE',
      'PARTNER_STORE',
      'HYBRID_OPERATION',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_ownership_type;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_ownership_type
  CHECK (
    ownership_type IN (
      'COMPANY_OWNED',
      'FRANCHISE_OWNED',
      'PARTNER_OWNED',
      'LEASED',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_operation_type;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_operation_type
  CHECK (
    operation_type IN (
      'COMPANY_OPERATED',
      'FRANCHISE_OPERATED',
      'PARTNER_OPERATED',
      'THIRD_PARTY_OPERATED',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_reporting_effect;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_reporting_effect
  CHECK (
    reporting_effect IN (
      'CONSOLIDATED',
      'FRANCHISE_REVENUE_SHARE',
      'FRANCHISE_SEPARATE_BOOKS',
      'PARTNER_SETTLEMENT',
      'EXTERNAL_OPERATOR',
      'EXCLUDED'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_permission_effect;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_permission_effect
  CHECK (
    permission_effect IN (
      'INTERNAL_FULL_SCOPE',
      'FRANCHISE_OPERATOR_SCOPE',
      'PARTNER_LIMITED_SCOPE',
      'READ_ONLY',
      'NO_ACCESS'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_responsibility;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_responsibility
  CHECK (
    accounting_responsibility IN (
      'LEGAL_ENTITY_BOOKS',
      'FRANCHISEE_BOOKS',
      'PARTNER_BOOKS',
      'EXTERNAL_BOOKS'
    )
    AND inventory_responsibility IN (
      'LOCATION_OPERATOR',
      'LEGAL_ENTITY',
      'FRANCHISEE',
      'PARTNER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_status;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','CLOSED')
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_effective_dates;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_company_branch_rule;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_company_branch_rule
  CHECK (
    business_model <> 'COMPANY_BRANCH'
    OR (
      ownership_type='COMPANY_OWNED'
      AND operation_type='COMPANY_OPERATED'
      AND reporting_effect='CONSOLIDATED'
      AND permission_effect='INTERNAL_FULL_SCOPE'
      AND franchise_agreement_id IS NULL
      AND accounting_responsibility='LEGAL_ENTITY_BOOKS'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_franchise_store_rule;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_franchise_store_rule
  CHECK (
    business_model <> 'FRANCHISE_STORE'
    OR (
      ownership_type IN ('FRANCHISE_OWNED','LEASED','COMPANY_OWNED')
      AND operation_type='FRANCHISE_OPERATED'
      AND reporting_effect IN ('FRANCHISE_REVENUE_SHARE','FRANCHISE_SEPARATE_BOOKS')
      AND permission_effect='FRANCHISE_OPERATOR_SCOPE'
      AND franchise_agreement_id IS NOT NULL
      AND accounting_responsibility IN ('FRANCHISEE_BOOKS','LEGAL_ENTITY_BOOKS')
      AND inventory_responsibility IN ('LOCATION_OPERATOR','FRANCHISEE')
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_partner_rule;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_partner_rule
  CHECK (
    business_model <> 'PARTNER_STORE'
    OR (
      ownership_type='PARTNER_OWNED'
      AND operation_type IN ('PARTNER_OPERATED','THIRD_PARTY_OPERATED')
      AND reporting_effect IN ('PARTNER_SETTLEMENT','EXTERNAL_OPERATOR')
      AND permission_effect='PARTNER_LIMITED_SCOPE'
      AND accounting_responsibility IN ('PARTNER_BOOKS','EXTERNAL_BOOKS')
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_audit_for_closed;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_audit_for_closed
  CHECK (
    status <> 'CLOSED'
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND operation_audit_ref IS NOT NULL
      AND btrim(operation_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_location_operation_profiles_set_updated_at ON org.location_operation_profiles;
CREATE TRIGGER trg_org_location_operation_profiles_set_updated_at
BEFORE UPDATE ON org.location_operation_profiles
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.location_operation_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.location_operation_profiles FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_location_operation_profiles_tenant_rw ON org.location_operation_profiles;
CREATE POLICY allow_org_location_operation_profiles_tenant_rw
ON org.location_operation_profiles
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
      'location_operation_profiles',
      'organization_operation_model',
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
          AND c.table_name='location_operation_profiles'
      ),
      jsonb_build_object(
        'phase','FAZ_1_3_5',
        'source','company_owned_vs_franchise_operated',
        'business_models', jsonb_build_array('COMPANY_BRANCH','FRANCHISE_STORE','PARTNER_STORE','HYBRID_OPERATION')
      ),
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
GRANT SELECT, INSERT, UPDATE ON org.location_operation_profiles TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
