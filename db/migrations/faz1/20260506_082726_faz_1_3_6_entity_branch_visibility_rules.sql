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

  IF to_regclass('org.business_locations') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='tenant_id'
     ) THEN
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_id_tenant_id_fk ON org.business_locations(id, tenant_id)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS org.visibility_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  business_code text NOT NULL,
  visibility_rule_code text NOT NULL,

  subject_type text NOT NULL,
  subject_user_id uuid,
  subject_role text,
  subject_legal_entity_id uuid,
  accountant_entity_id uuid,

  visibility_scope text NOT NULL,
  branch_scope text NOT NULL DEFAULT 'NO_BRANCH',

  target_entity_id uuid,
  target_branch_id uuid,
  target_location_id uuid,

  permission_effect text NOT NULL,
  access_level text NOT NULL DEFAULT 'READ',
  cross_branch_allowed boolean NOT NULL DEFAULT false,

  can_view boolean NOT NULL DEFAULT true,
  can_create boolean NOT NULL DEFAULT false,
  can_update boolean NOT NULL DEFAULT false,
  can_delete boolean NOT NULL DEFAULT false,
  can_export boolean NOT NULL DEFAULT false,

  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',

  approval_ref text,
  lifecycle_reason text,
  visibility_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS visibility_rule_code text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_type text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_user_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_role text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_legal_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS accountant_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS visibility_scope text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS branch_scope text DEFAULT 'NO_BRANCH';
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS target_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS target_branch_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS target_location_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS permission_effect text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS access_level text DEFAULT 'READ';
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS cross_branch_allowed boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_view boolean DEFAULT true;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_create boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_update boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_delete boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_export boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS approval_ref text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS visibility_audit_ref text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.visibility_rules SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.visibility_rules SET business_code='VIS_RULE_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.visibility_rules SET visibility_rule_code=business_code WHERE visibility_rule_code IS NULL OR btrim(visibility_rule_code::text)='';
UPDATE org.visibility_rules SET subject_type='ROLE' WHERE subject_type IS NULL OR btrim(subject_type::text)='';
UPDATE org.visibility_rules SET visibility_scope='ENTITY' WHERE visibility_scope IS NULL OR btrim(visibility_scope::text)='';
UPDATE org.visibility_rules SET branch_scope='NO_BRANCH' WHERE branch_scope IS NULL OR btrim(branch_scope::text)='';
UPDATE org.visibility_rules SET permission_effect='READ_ONLY' WHERE permission_effect IS NULL OR btrim(permission_effect::text)='';
UPDATE org.visibility_rules SET access_level='READ' WHERE access_level IS NULL OR btrim(access_level::text)='';
UPDATE org.visibility_rules SET cross_branch_allowed=false WHERE cross_branch_allowed IS NULL;
UPDATE org.visibility_rules SET can_view=true WHERE can_view IS NULL;
UPDATE org.visibility_rules SET can_create=false WHERE can_create IS NULL;
UPDATE org.visibility_rules SET can_update=false WHERE can_update IS NULL;
UPDATE org.visibility_rules SET can_delete=false WHERE can_delete IS NULL;
UPDATE org.visibility_rules SET can_export=false WHERE can_export IS NULL;
UPDATE org.visibility_rules SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.visibility_rules SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.visibility_rules SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.visibility_rules SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.visibility_rules SET created_at=now() WHERE created_at IS NULL;
UPDATE org.visibility_rules SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='visibility_rules'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.visibility_rules ADD CONSTRAINT pk_org_visibility_rules PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_id_tenant_id_fk
  ON org.visibility_rules(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_tenant_business_code
  ON org.visibility_rules(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_tenant_rule_code
  ON org.visibility_rules(tenant_id, visibility_rule_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_tenant_id ON org.visibility_rules(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_legal_entity_id ON org.visibility_rules(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_branch_id ON org.visibility_rules(branch_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_type ON org.visibility_rules(subject_type);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_role ON org.visibility_rules(subject_role);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_user_id ON org.visibility_rules(subject_user_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_legal_entity_id ON org.visibility_rules(subject_legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_accountant_entity_id ON org.visibility_rules(accountant_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_visibility_scope ON org.visibility_rules(visibility_scope);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_branch_scope ON org.visibility_rules(branch_scope);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_target_entity_id ON org.visibility_rules(target_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_target_branch_id ON org.visibility_rules(target_branch_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_target_location_id ON org.visibility_rules(target_location_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_permission_effect ON org.visibility_rules(permission_effect);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_status ON org.visibility_rules(status);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_effective_dates ON org.visibility_rules(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_audit_ref ON org.visibility_rules(visibility_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_legal_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_target_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_target_entity_tenant
      FOREIGN KEY (target_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_subject_legal_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_subject_legal_entity_tenant
      FOREIGN KEY (subject_legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_accountant_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_accountant_entity_tenant
      FOREIGN KEY (accountant_entity_id, tenant_id)
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
       WHERE conname='fk_org_visibility_rules_branch_tenant'
         AND conrelid='org.visibility_rules'::regclass
     ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
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
       WHERE conname='fk_org_visibility_rules_target_branch_tenant'
         AND conrelid='org.visibility_rules'::regclass
     ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_target_branch_tenant
      FOREIGN KEY (target_branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;

  IF to_regclass('org.business_locations') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='tenant_id'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname='fk_org_visibility_rules_target_location_tenant'
         AND conrelid='org.visibility_rules'::regclass
     ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_target_location_tenant
      FOREIGN KEY (target_location_id, tenant_id)
      REFERENCES org.business_locations(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_required_fields;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND visibility_rule_code IS NOT NULL AND btrim(visibility_rule_code::text) <> ''
    AND subject_type IS NOT NULL AND btrim(subject_type::text) <> ''
    AND visibility_scope IS NOT NULL AND btrim(visibility_scope::text) <> ''
    AND branch_scope IS NOT NULL AND btrim(branch_scope::text) <> ''
    AND permission_effect IS NOT NULL AND btrim(permission_effect::text) <> ''
    AND access_level IS NOT NULL AND btrim(access_level::text) <> ''
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_subject_type;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_subject_type
  CHECK (
    subject_type IN (
      'USER',
      'ROLE',
      'LEGAL_ENTITY',
      'ACCOUNTANT',
      'SYSTEM'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_subject_required;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_subject_required
  CHECK (
    (subject_type='USER' AND subject_user_id IS NOT NULL)
    OR (subject_type='ROLE' AND subject_role IS NOT NULL AND btrim(subject_role::text) <> '')
    OR (subject_type='LEGAL_ENTITY' AND subject_legal_entity_id IS NOT NULL)
    OR (subject_type='ACCOUNTANT' AND accountant_entity_id IS NOT NULL)
    OR (subject_type='SYSTEM')
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_visibility_scope;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_visibility_scope
  CHECK (
    visibility_scope IN (
      'GLOBAL',
      'ENTITY',
      'BRANCH',
      'LOCATION',
      'ACCOUNTANT',
      'ROLE'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_branch_scope;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_branch_scope
  CHECK (
    branch_scope IN (
      'NO_BRANCH',
      'ALL_BRANCHES',
      'SPECIFIC_BRANCH',
      'CROSS_BRANCH'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_target_required;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_target_required
  CHECK (
    (visibility_scope='GLOBAL')
    OR (visibility_scope='ENTITY' AND target_entity_id IS NOT NULL)
    OR (visibility_scope='ACCOUNTANT' AND target_entity_id IS NOT NULL AND accountant_entity_id IS NOT NULL)
    OR (visibility_scope='ROLE' AND subject_role IS NOT NULL)
    OR (visibility_scope='LOCATION' AND target_location_id IS NOT NULL)
    OR (
      visibility_scope='BRANCH'
      AND (
        branch_scope IN ('ALL_BRANCHES','CROSS_BRANCH')
        OR (branch_scope='SPECIFIC_BRANCH' AND target_branch_id IS NOT NULL)
      )
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_permission_effect;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_permission_effect
  CHECK (
    permission_effect IN (
      'READ_ONLY',
      'WRITE_SCOPE',
      'ADMIN_SCOPE',
      'ACCOUNTANT_READ',
      'ACCOUNTANT_EXPORT',
      'CROSS_BRANCH_READ',
      'CROSS_BRANCH_WRITE',
      'NO_ACCESS'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_access_level;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_access_level
  CHECK (
    access_level IN ('READ','WRITE','ADMIN','EXPORT','NONE')
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_effective_dates;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_status;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','REVOKED','EXPIRED')
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_accountant_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_accountant_rule
  CHECK (
    subject_type <> 'ACCOUNTANT'
    OR (
      accountant_entity_id IS NOT NULL
      AND visibility_scope='ACCOUNTANT'
      AND permission_effect IN ('ACCOUNTANT_READ','ACCOUNTANT_EXPORT','READ_ONLY')
      AND can_delete=false
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_cross_branch_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_cross_branch_rule
  CHECK (
    permission_effect NOT IN ('CROSS_BRANCH_READ','CROSS_BRANCH_WRITE')
    OR (
      branch_scope IN ('ALL_BRANCHES','CROSS_BRANCH')
      AND cross_branch_allowed=true
      AND approval_ref IS NOT NULL
      AND btrim(approval_ref::text) <> ''
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_cross_branch_write_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_cross_branch_write_rule
  CHECK (
    permission_effect <> 'CROSS_BRANCH_WRITE'
    OR (
      access_level IN ('WRITE','ADMIN')
      AND can_update=true
      AND cross_branch_allowed=true
      AND approval_ref IS NOT NULL
      AND btrim(approval_ref::text) <> ''
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_no_access_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_no_access_rule
  CHECK (
    permission_effect <> 'NO_ACCESS'
    OR (
      access_level='NONE'
      AND can_view=false
      AND can_create=false
      AND can_update=false
      AND can_delete=false
      AND can_export=false
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_revoke_audit;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_revoke_audit
  CHECK (
    status NOT IN ('REVOKED','EXPIRED')
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND visibility_audit_ref IS NOT NULL
      AND btrim(visibility_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_visibility_rules_set_updated_at ON org.visibility_rules;
CREATE TRIGGER trg_org_visibility_rules_set_updated_at
BEFORE UPDATE ON org.visibility_rules
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.visibility_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.visibility_rules FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_visibility_rules_tenant_rw ON org.visibility_rules;
CREATE POLICY allow_org_visibility_rules_tenant_rw
ON org.visibility_rules
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
      'visibility_rules',
      'organization_visibility_access',
      'ACCESS_RULE_TABLE',
      'ACTIVE',
      true,
      true,
      true,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='org'
          AND c.table_name='visibility_rules'
      ),
      jsonb_build_object(
        'phase','FAZ_1_3_6',
        'source','entity_branch_visibility_rules',
        'scopes', jsonb_build_array('ENTITY','BRANCH','ROLE','ACCOUNTANT','LOCATION','GLOBAL')
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
GRANT SELECT, INSERT, UPDATE ON org.visibility_rules TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
