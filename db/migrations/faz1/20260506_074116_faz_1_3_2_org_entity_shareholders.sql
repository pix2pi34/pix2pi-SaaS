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

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_id_tenant_id_fk
  ON org.legal_entities(id, tenant_id);

CREATE TABLE IF NOT EXISTS org.entity_shareholders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  business_code text NOT NULL,
  shareholder_type text NOT NULL,
  shareholder_entity_id uuid,
  shareholder_name text NOT NULL,
  shareholder_tax_number text,
  share_class text NOT NULL DEFAULT 'COMMON',
  ownership_percentage numeric(9,6) NOT NULL,
  voting_percentage numeric(9,6),
  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',
  ownership_audit_ref text,
  ownership_change_reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS shareholder_type text;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS shareholder_entity_id uuid;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS shareholder_name text;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS shareholder_tax_number text;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS share_class text DEFAULT 'COMMON';
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS ownership_percentage numeric(9,6);
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS voting_percentage numeric(9,6);
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS ownership_audit_ref text;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS ownership_change_reason text;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.entity_shareholders ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.entity_shareholders SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.entity_shareholders SET business_code='ENTITY_SH_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.entity_shareholders SET shareholder_name=COALESCE(NULLIF(shareholder_name,''), 'UNKNOWN SHAREHOLDER') WHERE shareholder_name IS NULL OR btrim(shareholder_name)='';
UPDATE org.entity_shareholders SET share_class='COMMON' WHERE share_class IS NULL OR btrim(share_class)='';
UPDATE org.entity_shareholders SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.entity_shareholders SET status='ACTIVE' WHERE status IS NULL OR btrim(status)='';
UPDATE org.entity_shareholders SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.entity_shareholders SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.entity_shareholders SET created_at=now() WHERE created_at IS NULL;
UPDATE org.entity_shareholders SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.entity_shareholders ADD CONSTRAINT pk_org_entity_shareholders PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_shareholders_id_tenant_id_fk
  ON org.entity_shareholders(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_shareholders_tenant_business_code
  ON org.entity_shareholders(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_tenant_id
  ON org.entity_shareholders(tenant_id);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_legal_entity_id
  ON org.entity_shareholders(legal_entity_id);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_branch_id
  ON org.entity_shareholders(branch_id);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_shareholder_entity_id
  ON org.entity_shareholders(shareholder_entity_id);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_shareholder_type
  ON org.entity_shareholders(shareholder_type);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_effective_dates
  ON org.entity_shareholders(effective_from, effective_to);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_status
  ON org.entity_shareholders(status);

CREATE INDEX IF NOT EXISTS idx_org_entity_shareholders_ownership_audit_ref
  ON org.entity_shareholders(ownership_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_shareholders_entity_tenant'
      AND conrelid='org.entity_shareholders'::regclass
  ) THEN
    ALTER TABLE org.entity_shareholders
      ADD CONSTRAINT fk_org_entity_shareholders_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_shareholders_shareholder_entity_tenant'
      AND conrelid='org.entity_shareholders'::regclass
  ) THEN
    ALTER TABLE org.entity_shareholders
      ADD CONSTRAINT fk_org_entity_shareholders_shareholder_entity_tenant
      FOREIGN KEY (shareholder_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_required_fields;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code) <> ''
    AND shareholder_type IS NOT NULL AND btrim(shareholder_type) <> ''
    AND shareholder_name IS NOT NULL AND btrim(shareholder_name) <> ''
    AND share_class IS NOT NULL AND btrim(share_class) <> ''
    AND ownership_percentage IS NOT NULL
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status) <> ''
  ) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_shareholder_type;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_shareholder_type
  CHECK (
    shareholder_type IN (
      'LEGAL_ENTITY',
      'INDIVIDUAL',
      'EXTERNAL_COMPANY',
      'FOUNDATION',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_entity_required_for_legal_type;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_entity_required_for_legal_type
  CHECK (
    shareholder_type <> 'LEGAL_ENTITY'
    OR shareholder_entity_id IS NOT NULL
  ) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_no_self_ownership;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_no_self_ownership
  CHECK (
    shareholder_entity_id IS NULL
    OR shareholder_entity_id <> legal_entity_id
  ) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_ownership_percentage_range;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_ownership_percentage_range
  CHECK (ownership_percentage > 0 AND ownership_percentage <= 100) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_voting_percentage_range;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_voting_percentage_range
  CHECK (voting_percentage IS NULL OR (voting_percentage >= 0 AND voting_percentage <= 100)) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_effective_dates;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.entity_shareholders DROP CONSTRAINT IF EXISTS ck_org_entity_shareholders_status;
ALTER TABLE org.entity_shareholders
  ADD CONSTRAINT ck_org_entity_shareholders_status
  CHECK (status IN ('ACTIVE','INACTIVE','PLANNED','ENDED')) NOT VALID;

CREATE OR REPLACE FUNCTION org.prevent_entity_shareholder_over_100()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_total numeric(12,6) := 0;
BEGIN
  IF NEW.deleted_at IS NOT NULL OR NEW.status <> 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(sum(es.ownership_percentage), 0)
  INTO v_total
  FROM org.entity_shareholders es
  WHERE es.tenant_id = NEW.tenant_id
    AND es.legal_entity_id = NEW.legal_entity_id
    AND es.deleted_at IS NULL
    AND es.status = 'ACTIVE'
    AND es.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    AND daterange(es.effective_from, COALESCE(es.effective_to, '9999-12-31'::date), '[]')
        && daterange(NEW.effective_from, COALESCE(NEW.effective_to, '9999-12-31'::date), '[]');

  IF (v_total + NEW.ownership_percentage) > 100 THEN
    RAISE EXCEPTION 'ownership percentage exceeds 100 for tenant %, entity %, total %, new %',
      NEW.tenant_id,
      NEW.legal_entity_id,
      v_total,
      NEW.ownership_percentage;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_org_entity_shareholders_prevent_over_100 ON org.entity_shareholders;
CREATE TRIGGER trg_org_entity_shareholders_prevent_over_100
BEFORE INSERT OR UPDATE ON org.entity_shareholders
FOR EACH ROW
EXECUTE FUNCTION org.prevent_entity_shareholder_over_100();

DROP TRIGGER IF EXISTS trg_org_entity_shareholders_set_updated_at ON org.entity_shareholders;
CREATE TRIGGER trg_org_entity_shareholders_set_updated_at
BEFORE UPDATE ON org.entity_shareholders
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.entity_shareholders ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.entity_shareholders FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_entity_shareholders_tenant_rw ON org.entity_shareholders;
CREATE POLICY allow_org_entity_shareholders_tenant_rw
ON org.entity_shareholders
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
      'entity_shareholders',
      'organization_ownership_core',
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
          AND c.table_name='entity_shareholders'
      ),
      jsonb_build_object('phase','FAZ_1_3_2','source','org_entity_shareholders'),
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
GRANT SELECT, INSERT, UPDATE ON org.entity_shareholders TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.prevent_entity_shareholder_over_100() TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
