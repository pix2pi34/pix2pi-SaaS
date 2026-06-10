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

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_id_tenant_id_fk
  ON org.visibility_rules(id, tenant_id);

CREATE TABLE IF NOT EXISTS org.cross_company_relations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,

  business_code text NOT NULL,
  relation_code text NOT NULL,

  relation_type text NOT NULL,
  relation_direction text NOT NULL DEFAULT 'OUTBOUND',
  relation_channel text NOT NULL DEFAULT 'DIRECT',

  counterparty_entity_id uuid,
  counterparty_external_ref text,
  counterparty_name text NOT NULL,

  visibility_rule_id uuid,
  visibility_effect text NOT NULL DEFAULT 'INTERNAL_ONLY',
  cross_company_visibility_allowed boolean NOT NULL DEFAULT false,

  is_partner boolean NOT NULL DEFAULT false,
  is_customer boolean NOT NULL DEFAULT false,
  is_vendor boolean NOT NULL DEFAULT false,

  credit_limit numeric(18,2),
  payment_term_days integer,
  currency_code text NOT NULL DEFAULT 'TRY',

  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',

  approval_ref text,
  lifecycle_reason text,
  relation_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_code text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_type text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_direction text DEFAULT 'OUTBOUND';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_channel text DEFAULT 'DIRECT';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS counterparty_entity_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS counterparty_external_ref text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS counterparty_name text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS visibility_rule_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS visibility_effect text DEFAULT 'INTERNAL_ONLY';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS cross_company_visibility_allowed boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS is_partner boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS is_customer boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS is_vendor boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS credit_limit numeric(18,2);
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS payment_term_days integer;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS currency_code text DEFAULT 'TRY';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS approval_ref text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_audit_ref text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.cross_company_relations SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.cross_company_relations SET business_code='CCR_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.cross_company_relations SET relation_code=business_code WHERE relation_code IS NULL OR btrim(relation_code::text)='';
UPDATE org.cross_company_relations SET relation_type='PARTNER' WHERE relation_type IS NULL OR btrim(relation_type::text)='';
UPDATE org.cross_company_relations SET relation_direction='OUTBOUND' WHERE relation_direction IS NULL OR btrim(relation_direction::text)='';
UPDATE org.cross_company_relations SET relation_channel='DIRECT' WHERE relation_channel IS NULL OR btrim(relation_channel::text)='';
UPDATE org.cross_company_relations SET counterparty_name=COALESCE(counterparty_name, counterparty_external_ref, 'UNKNOWN_COUNTERPARTY') WHERE counterparty_name IS NULL OR btrim(counterparty_name::text)='';
UPDATE org.cross_company_relations SET visibility_effect='INTERNAL_ONLY' WHERE visibility_effect IS NULL OR btrim(visibility_effect::text)='';
UPDATE org.cross_company_relations SET cross_company_visibility_allowed=false WHERE cross_company_visibility_allowed IS NULL;
UPDATE org.cross_company_relations SET is_partner=false WHERE is_partner IS NULL;
UPDATE org.cross_company_relations SET is_customer=false WHERE is_customer IS NULL;
UPDATE org.cross_company_relations SET is_vendor=false WHERE is_vendor IS NULL;
UPDATE org.cross_company_relations SET currency_code='TRY' WHERE currency_code IS NULL OR btrim(currency_code::text)='';
UPDATE org.cross_company_relations SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.cross_company_relations SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.cross_company_relations SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.cross_company_relations SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.cross_company_relations SET created_at=now() WHERE created_at IS NULL;
UPDATE org.cross_company_relations SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='cross_company_relations'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.cross_company_relations ADD CONSTRAINT pk_org_cross_company_relations PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_id_tenant_id_fk
  ON org.cross_company_relations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_tenant_business_code
  ON org.cross_company_relations(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_tenant_relation_code
  ON org.cross_company_relations(tenant_id, relation_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_internal_active
  ON org.cross_company_relations(tenant_id, legal_entity_id, counterparty_entity_id, relation_type)
  WHERE deleted_at IS NULL
    AND status='ACTIVE'
    AND counterparty_entity_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_external_active
  ON org.cross_company_relations(tenant_id, legal_entity_id, counterparty_external_ref, relation_type)
  WHERE deleted_at IS NULL
    AND status='ACTIVE'
    AND counterparty_external_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_tenant_id ON org.cross_company_relations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_legal_entity_id ON org.cross_company_relations(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_counterparty_entity_id ON org.cross_company_relations(counterparty_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_counterparty_external_ref ON org.cross_company_relations(counterparty_external_ref);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_relation_type ON org.cross_company_relations(relation_type);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_relation_direction ON org.cross_company_relations(relation_direction);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_visibility_rule_id ON org.cross_company_relations(visibility_rule_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_visibility_effect ON org.cross_company_relations(visibility_effect);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_partner_flag ON org.cross_company_relations(is_partner);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_customer_flag ON org.cross_company_relations(is_customer);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_vendor_flag ON org.cross_company_relations(is_vendor);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_status ON org.cross_company_relations(status);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_effective_dates ON org.cross_company_relations(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_audit_ref ON org.cross_company_relations(relation_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_cross_company_relations_legal_entity_tenant'
      AND conrelid='org.cross_company_relations'::regclass
  ) THEN
    ALTER TABLE org.cross_company_relations
      ADD CONSTRAINT fk_org_cross_company_relations_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_cross_company_relations_counterparty_entity_tenant'
      AND conrelid='org.cross_company_relations'::regclass
  ) THEN
    ALTER TABLE org.cross_company_relations
      ADD CONSTRAINT fk_org_cross_company_relations_counterparty_entity_tenant
      FOREIGN KEY (counterparty_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_cross_company_relations_visibility_rule_tenant'
      AND conrelid='org.cross_company_relations'::regclass
  ) THEN
    ALTER TABLE org.cross_company_relations
      ADD CONSTRAINT fk_org_cross_company_relations_visibility_rule_tenant
      FOREIGN KEY (visibility_rule_id, tenant_id)
      REFERENCES org.visibility_rules(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_required_fields;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND relation_code IS NOT NULL AND btrim(relation_code::text) <> ''
    AND relation_type IS NOT NULL AND btrim(relation_type::text) <> ''
    AND relation_direction IS NOT NULL AND btrim(relation_direction::text) <> ''
    AND relation_channel IS NOT NULL AND btrim(relation_channel::text) <> ''
    AND counterparty_name IS NOT NULL AND btrim(counterparty_name::text) <> ''
    AND visibility_effect IS NOT NULL AND btrim(visibility_effect::text) <> ''
    AND currency_code IS NOT NULL AND btrim(currency_code::text) <> ''
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_counterparty_required;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_counterparty_required
  CHECK (
    counterparty_entity_id IS NOT NULL
    OR (
      counterparty_external_ref IS NOT NULL
      AND btrim(counterparty_external_ref::text) <> ''
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_no_self_relation;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_no_self_relation
  CHECK (
    counterparty_entity_id IS NULL
    OR counterparty_entity_id <> legal_entity_id
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_relation_type;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_relation_type
  CHECK (
    relation_type IN (
      'PARTNER',
      'CUSTOMER',
      'VENDOR',
      'CUSTOMER_VENDOR',
      'STRATEGIC_PARTNER',
      'ACCOUNTANT_CLIENT',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_relation_direction;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_relation_direction
  CHECK (
    relation_direction IN ('OUTBOUND','INBOUND','BIDIRECTIONAL')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_relation_channel;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_relation_channel
  CHECK (
    relation_channel IN ('DIRECT','MARKETPLACE','FRANCHISE','ACCOUNTANT_PORTAL','INTEGRATION','OTHER')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_flags_match_type;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_flags_match_type
  CHECK (
    (relation_type='PARTNER' AND is_partner=true)
    OR (relation_type='STRATEGIC_PARTNER' AND is_partner=true)
    OR (relation_type='CUSTOMER' AND is_customer=true)
    OR (relation_type='VENDOR' AND is_vendor=true)
    OR (relation_type='CUSTOMER_VENDOR' AND is_customer=true AND is_vendor=true)
    OR (relation_type='ACCOUNTANT_CLIENT')
    OR (relation_type='OTHER')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_visibility_effect;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_visibility_effect
  CHECK (
    visibility_effect IN (
      'INTERNAL_ONLY',
      'COUNTERPARTY_VISIBLE',
      'ACCOUNTANT_VISIBLE',
      'CROSS_COMPANY_VISIBLE',
      'NO_VISIBILITY'
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_cross_company_visibility;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_cross_company_visibility
  CHECK (
    visibility_effect <> 'CROSS_COMPANY_VISIBLE'
    OR (
      cross_company_visibility_allowed=true
      AND (
        visibility_rule_id IS NOT NULL
        OR (
          approval_ref IS NOT NULL
          AND btrim(approval_ref::text) <> ''
        )
      )
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_accountant_visibility;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_accountant_visibility
  CHECK (
    relation_type <> 'ACCOUNTANT_CLIENT'
    OR visibility_effect IN ('ACCOUNTANT_VISIBLE','CROSS_COMPANY_VISIBLE')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_money_terms;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_money_terms
  CHECK (
    (credit_limit IS NULL OR credit_limit >= 0)
    AND (payment_term_days IS NULL OR payment_term_days >= 0)
    AND currency_code ~ '^[A-Z]{3}$'
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_effective_dates;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_status;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','TERMINATED','ARCHIVED')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_termination_audit;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_termination_audit
  CHECK (
    status NOT IN ('TERMINATED','ARCHIVED')
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND relation_audit_ref IS NOT NULL
      AND btrim(relation_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_cross_company_relations_set_updated_at ON org.cross_company_relations;
CREATE TRIGGER trg_org_cross_company_relations_set_updated_at
BEFORE UPDATE ON org.cross_company_relations
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.cross_company_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.cross_company_relations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_cross_company_relations_tenant_rw ON org.cross_company_relations;
CREATE POLICY allow_org_cross_company_relations_tenant_rw
ON org.cross_company_relations
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
      'cross_company_relations',
      'organization_partner_relation',
      'RELATION_TABLE',
      'ACTIVE',
      true,
      true,
      false,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='org'
          AND c.table_name='cross_company_relations'
      ),
      jsonb_build_object(
        'phase','FAZ_1_3_7',
        'source','partner_customer_vendor_cross_company_relations',
        'relation_types', jsonb_build_array('PARTNER','CUSTOMER','VENDOR','CUSTOMER_VENDOR','ACCOUNTANT_CLIENT')
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
GRANT SELECT, INSERT, UPDATE ON org.cross_company_relations TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
