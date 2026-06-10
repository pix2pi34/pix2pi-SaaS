BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS franchise;

CREATE OR REPLACE FUNCTION franchise.set_updated_at()
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

CREATE TABLE IF NOT EXISTS franchise.agreements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  business_code text NOT NULL,
  agreement_number text NOT NULL,
  agreement_type text NOT NULL DEFAULT 'STANDARD_FRANCHISE',
  franchisor_entity_id uuid NOT NULL,
  franchisee_entity_id uuid NOT NULL,
  owner_entity_id uuid NOT NULL,
  operator_entity_id uuid NOT NULL,
  territory_code text,
  territory_name text,
  start_date date NOT NULL,
  end_date date,
  signed_at timestamptz,
  activated_at timestamptz,
  terminated_at timestamptz,
  status text NOT NULL DEFAULT 'active',
  agreement_lifecycle_status text NOT NULL DEFAULT 'DRAFT',
  lifecycle_reason text,
  agreement_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS agreement_number text;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS agreement_type text DEFAULT 'STANDARD_FRANCHISE';
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS franchisor_entity_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS franchisee_entity_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS owner_entity_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS operator_entity_id uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS territory_code text;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS territory_name text;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS start_date date;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS end_date date;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS signed_at timestamptz;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS activated_at timestamptz;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS terminated_at timestamptz;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS agreement_lifecycle_status text DEFAULT 'DRAFT';
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS agreement_audit_ref text;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE franchise.agreements ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE franchise.agreements SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE franchise.agreements SET business_code='FR_AGR_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE franchise.agreements SET agreement_number=business_code WHERE agreement_number IS NULL OR btrim(agreement_number::text)='';
UPDATE franchise.agreements SET agreement_type='STANDARD_FRANCHISE' WHERE agreement_type IS NULL OR btrim(agreement_type::text)='';
UPDATE franchise.agreements SET start_date=current_date WHERE start_date IS NULL;
UPDATE franchise.agreements SET agreement_lifecycle_status='DRAFT' WHERE agreement_lifecycle_status IS NULL OR btrim(agreement_lifecycle_status::text)='';
UPDATE franchise.agreements SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE franchise.agreements SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE franchise.agreements SET created_at=now() WHERE created_at IS NULL;
UPDATE franchise.agreements SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='status'
  ) THEN
    EXECUTE 'UPDATE franchise.agreements SET status = ''active'' WHERE status IS NULL';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE franchise.agreements ADD CONSTRAINT pk_franchise_agreements PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_franchise_agreements_id_tenant_id_fk
  ON franchise.agreements(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_franchise_agreements_tenant_business_code
  ON franchise.agreements(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_franchise_agreements_tenant_agreement_number
  ON franchise.agreements(tenant_id, agreement_number)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_franchise_agreements_tenant_id ON franchise.agreements(tenant_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_legal_entity_id ON franchise.agreements(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_branch_id ON franchise.agreements(branch_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_franchisor_entity_id ON franchise.agreements(franchisor_entity_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_franchisee_entity_id ON franchise.agreements(franchisee_entity_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_owner_entity_id ON franchise.agreements(owner_entity_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_operator_entity_id ON franchise.agreements(operator_entity_id);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_lifecycle_status ON franchise.agreements(agreement_lifecycle_status);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_start_end_date ON franchise.agreements(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_franchise_agreements_audit_ref ON franchise.agreements(agreement_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_franchise_agreements_legal_entity_tenant'
      AND conrelid='franchise.agreements'::regclass
  ) THEN
    ALTER TABLE franchise.agreements
      ADD CONSTRAINT fk_franchise_agreements_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_franchise_agreements_franchisor_tenant'
      AND conrelid='franchise.agreements'::regclass
  ) THEN
    ALTER TABLE franchise.agreements
      ADD CONSTRAINT fk_franchise_agreements_franchisor_tenant
      FOREIGN KEY (franchisor_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_franchise_agreements_franchisee_tenant'
      AND conrelid='franchise.agreements'::regclass
  ) THEN
    ALTER TABLE franchise.agreements
      ADD CONSTRAINT fk_franchise_agreements_franchisee_tenant
      FOREIGN KEY (franchisee_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_franchise_agreements_owner_tenant'
      AND conrelid='franchise.agreements'::regclass
  ) THEN
    ALTER TABLE franchise.agreements
      ADD CONSTRAINT fk_franchise_agreements_owner_tenant
      FOREIGN KEY (owner_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_franchise_agreements_operator_tenant'
      AND conrelid='franchise.agreements'::regclass
  ) THEN
    ALTER TABLE franchise.agreements
      ADD CONSTRAINT fk_franchise_agreements_operator_tenant
      FOREIGN KEY (operator_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_required_fields;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND agreement_number IS NOT NULL AND btrim(agreement_number::text) <> ''
    AND agreement_type IS NOT NULL AND btrim(agreement_type::text) <> ''
    AND franchisor_entity_id IS NOT NULL
    AND franchisee_entity_id IS NOT NULL
    AND owner_entity_id IS NOT NULL
    AND operator_entity_id IS NOT NULL
    AND start_date IS NOT NULL
    AND agreement_lifecycle_status IS NOT NULL
    AND btrim(agreement_lifecycle_status::text) <> ''
  ) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_no_self_franchise;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_no_self_franchise
  CHECK (franchisor_entity_id <> franchisee_entity_id) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_owner_operator_not_null;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_owner_operator_not_null
  CHECK (owner_entity_id IS NOT NULL AND operator_entity_id IS NOT NULL) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_agreement_type;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_agreement_type
  CHECK (
    agreement_type IN (
      'STANDARD_FRANCHISE',
      'MASTER_FRANCHISE',
      'AREA_DEVELOPMENT',
      'SUB_FRANCHISE',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_lifecycle_status;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_lifecycle_status
  CHECK (
    agreement_lifecycle_status IN (
      'DRAFT',
      'PENDING_SIGNATURE',
      'SIGNED',
      'ACTIVE',
      'SUSPENDED',
      'TERMINATED',
      'EXPIRED'
    )
  ) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_effective_dates;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_effective_dates
  CHECK (end_date IS NULL OR end_date >= start_date) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_lifecycle_dates;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_lifecycle_dates
  CHECK (
    (agreement_lifecycle_status <> 'SIGNED' OR signed_at IS NOT NULL)
    AND (agreement_lifecycle_status <> 'ACTIVE' OR activated_at IS NOT NULL)
    AND (agreement_lifecycle_status <> 'TERMINATED' OR terminated_at IS NOT NULL)
  ) NOT VALID;

ALTER TABLE franchise.agreements DROP CONSTRAINT IF EXISTS ck_franchise_agreements_audit_for_terminal;
ALTER TABLE franchise.agreements
  ADD CONSTRAINT ck_franchise_agreements_audit_for_terminal
  CHECK (
    agreement_lifecycle_status NOT IN ('SUSPENDED','TERMINATED','EXPIRED')
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND agreement_audit_ref IS NOT NULL
      AND btrim(agreement_audit_ref::text) <> ''
    )
  ) NOT VALID;

CREATE OR REPLACE FUNCTION franchise.prevent_overlapping_active_agreement()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_overlap_exists boolean := false;
BEGIN
  IF NEW.deleted_at IS NOT NULL OR NEW.agreement_lifecycle_status NOT IN ('SIGNED','ACTIVE','SUSPENDED') THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM franchise.agreements fa
    WHERE fa.tenant_id = NEW.tenant_id
      AND fa.franchisee_entity_id = NEW.franchisee_entity_id
      AND fa.deleted_at IS NULL
      AND fa.agreement_lifecycle_status IN ('SIGNED','ACTIVE','SUSPENDED')
      AND fa.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
      AND daterange(fa.start_date, COALESCE(fa.end_date, '9999-12-31'::date), '[]')
          && daterange(NEW.start_date, COALESCE(NEW.end_date, '9999-12-31'::date), '[]')
  )
  INTO v_overlap_exists;

  IF v_overlap_exists THEN
    RAISE EXCEPTION 'overlapping franchise agreement blocked for tenant %, franchisee %',
      NEW.tenant_id,
      NEW.franchisee_entity_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_franchise_agreements_prevent_overlap ON franchise.agreements;
CREATE TRIGGER trg_franchise_agreements_prevent_overlap
BEFORE INSERT OR UPDATE ON franchise.agreements
FOR EACH ROW
EXECUTE FUNCTION franchise.prevent_overlapping_active_agreement();

DROP TRIGGER IF EXISTS trg_franchise_agreements_set_updated_at ON franchise.agreements;
CREATE TRIGGER trg_franchise_agreements_set_updated_at
BEFORE UPDATE ON franchise.agreements
FOR EACH ROW
EXECUTE FUNCTION franchise.set_updated_at();

ALTER TABLE franchise.agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE franchise.agreements FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_franchise_agreements_tenant_rw ON franchise.agreements;
CREATE POLICY allow_franchise_agreements_tenant_rw
ON franchise.agreements
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
      'franchise',
      'agreements',
      'franchise_core',
      'BASE_TABLE',
      'ACTIVE',
      true,
      true,
      true,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='franchise'
          AND c.table_name='agreements'
      ),
      jsonb_build_object('phase','FAZ_1_3_3_FIX_V2','source','franchise_agreements'),
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

GRANT USAGE ON SCHEMA franchise TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON franchise.agreements TO PUBLIC;
GRANT EXECUTE ON FUNCTION franchise.set_updated_at() TO PUBLIC;
GRANT EXECUTE ON FUNCTION franchise.prevent_overlapping_active_agreement() TO PUBLIC;

COMMIT;
