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

CREATE TABLE IF NOT EXISTS org.entity_relations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  parent_entity_id uuid NOT NULL,
  child_entity_id uuid NOT NULL,
  business_code text NOT NULL,
  relation_type text NOT NULL,
  visibility_scope text NOT NULL DEFAULT 'INHERIT',
  visibility_rule_code text,
  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS parent_entity_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS child_entity_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS relation_type text;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS visibility_scope text DEFAULT 'INHERIT';
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS visibility_rule_code text;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.entity_relations SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.entity_relations SET legal_entity_id=parent_entity_id WHERE legal_entity_id IS NULL AND parent_entity_id IS NOT NULL;
UPDATE org.entity_relations SET business_code='ENTITY_REL_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.entity_relations SET visibility_scope='INHERIT' WHERE visibility_scope IS NULL OR btrim(visibility_scope)='';
UPDATE org.entity_relations SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.entity_relations SET status='ACTIVE' WHERE status IS NULL OR btrim(status)='';
UPDATE org.entity_relations SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.entity_relations SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.entity_relations SET created_at=now() WHERE created_at IS NULL;
UPDATE org.entity_relations SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='entity_relations'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.entity_relations ADD CONSTRAINT pk_org_entity_relations PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_relations_id_tenant_id_fk
  ON org.entity_relations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_relations_tenant_business_code
  ON org.entity_relations(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_relations_active_edge
  ON org.entity_relations(tenant_id, parent_entity_id, child_entity_id, relation_type)
  WHERE deleted_at IS NULL AND status='ACTIVE';

CREATE INDEX IF NOT EXISTS idx_org_entity_relations_tenant_id ON org.entity_relations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_legal_entity_id ON org.entity_relations(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_parent_entity_id ON org.entity_relations(parent_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_child_entity_id ON org.entity_relations(child_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_relation_type ON org.entity_relations(relation_type);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_visibility_rule_code ON org.entity_relations(visibility_rule_code);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_status ON org.entity_relations(status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_relations_legal_entity_tenant'
      AND conrelid='org.entity_relations'::regclass
  ) THEN
    ALTER TABLE org.entity_relations
      ADD CONSTRAINT fk_org_entity_relations_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_relations_parent_tenant'
      AND conrelid='org.entity_relations'::regclass
  ) THEN
    ALTER TABLE org.entity_relations
      ADD CONSTRAINT fk_org_entity_relations_parent_tenant
      FOREIGN KEY (parent_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_relations_child_tenant'
      AND conrelid='org.entity_relations'::regclass
  ) THEN
    ALTER TABLE org.entity_relations
      ADD CONSTRAINT fk_org_entity_relations_child_tenant
      FOREIGN KEY (child_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_required_fields;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND parent_entity_id IS NOT NULL
    AND child_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code) <> ''
    AND relation_type IS NOT NULL AND btrim(relation_type) <> ''
    AND visibility_scope IS NOT NULL AND btrim(visibility_scope) <> ''
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status) <> ''
  ) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_no_self_relation;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_no_self_relation
  CHECK (parent_entity_id <> child_entity_id) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_relation_type;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_relation_type
  CHECK (
    relation_type IN (
      'HOLDING_SUBSIDIARY',
      'PARENT_CHILD',
      'AFFILIATE',
      'MANAGEMENT',
      'FRANCHISE_OWNER_OPERATOR',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_visibility_scope;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_visibility_scope
  CHECK (
    visibility_scope IN (
      'INHERIT',
      'PARENT_ONLY',
      'CHILD_ONLY',
      'CUSTOM_RULE'
    )
  ) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_effective_dates;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_status;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_status
  CHECK (status IN ('ACTIVE','INACTIVE','PLANNED','ENDED')) NOT VALID;

CREATE OR REPLACE FUNCTION org.prevent_entity_relation_cycle()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_cycle_exists boolean := false;
BEGIN
  IF NEW.deleted_at IS NOT NULL OR NEW.status <> 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  IF NEW.parent_entity_id = NEW.child_entity_id THEN
    RAISE EXCEPTION 'entity relation cycle/self relation blocked: parent and child cannot be same';
  END IF;

  WITH RECURSIVE descendants(entity_id) AS (
    SELECT er.child_entity_id
    FROM org.entity_relations er
    WHERE er.tenant_id = NEW.tenant_id
      AND er.parent_entity_id = NEW.child_entity_id
      AND er.deleted_at IS NULL
      AND er.status = 'ACTIVE'
      AND er.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)

    UNION

    SELECT er.child_entity_id
    FROM org.entity_relations er
    JOIN descendants d ON d.entity_id = er.parent_entity_id
    WHERE er.tenant_id = NEW.tenant_id
      AND er.deleted_at IS NULL
      AND er.status = 'ACTIVE'
      AND er.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  SELECT EXISTS (
    SELECT 1
    FROM descendants
    WHERE entity_id = NEW.parent_entity_id
  )
  INTO v_cycle_exists;

  IF v_cycle_exists THEN
    RAISE EXCEPTION 'entity relation cycle blocked for tenant %, parent %, child %',
      NEW.tenant_id,
      NEW.parent_entity_id,
      NEW.child_entity_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_org_entity_relations_prevent_cycle ON org.entity_relations;
CREATE TRIGGER trg_org_entity_relations_prevent_cycle
BEFORE INSERT OR UPDATE ON org.entity_relations
FOR EACH ROW
EXECUTE FUNCTION org.prevent_entity_relation_cycle();

DROP TRIGGER IF EXISTS trg_org_entity_relations_set_updated_at ON org.entity_relations;
CREATE TRIGGER trg_org_entity_relations_set_updated_at
BEFORE UPDATE ON org.entity_relations
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.entity_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.entity_relations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_entity_relations_tenant_rw ON org.entity_relations;
CREATE POLICY allow_org_entity_relations_tenant_rw
ON org.entity_relations
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
      'entity_relations',
      'organization_core',
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
          AND c.table_name='entity_relations'
      ),
      jsonb_build_object('phase','FAZ_1_3_1','source','org_entity_relations'),
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
GRANT SELECT, INSERT, UPDATE ON org.entity_relations TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.prevent_entity_relation_cycle() TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
