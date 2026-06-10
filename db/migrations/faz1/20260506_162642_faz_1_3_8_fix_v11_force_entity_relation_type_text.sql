BEGIN;

DO $$
DECLARE
  v_domain_schema text;
  v_domain_name text;
BEGIN
  SELECT c.domain_schema, c.domain_name
  INTO v_domain_schema, v_domain_name
  FROM information_schema.columns c
  WHERE c.table_schema='org'
    AND c.table_name='entity_relations'
    AND c.column_name='relation_type'
  LIMIT 1;

  -- relation_type semantik bir tip alanıdır; core.code_text domain olmamalı.
  -- Domain ise graph relation değerleri check/domain çakışması yaratır.
  IF COALESCE(v_domain_schema, '') <> ''
     OR COALESCE(v_domain_name, '') <> '' THEN
    ALTER TABLE org.entity_relations
      ALTER COLUMN relation_type TYPE text
      USING relation_type::text;
  END IF;
END $$;

ALTER TABLE org.entity_relations
  DROP CONSTRAINT IF EXISTS ck_org_entity_relations_relation_type;

ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_relation_type
  CHECK (
    relation_type IS NOT NULL
    AND btrim(relation_type::text) <> ''
    AND relation_type::text IN (
      'AFFILIATE',
      'FRANCHISE_OWNER_OPERATOR',
      'HOLDING_SUBSIDIARY',
      'HOLDING_PARENT',
      'PARENT_CHILD',
      'PARENT',
      'CHILD',
      'HOLDING',
      'SUBSIDIARY',
      'OWNERSHIP',
      'PARENT_COMPANY',
      'CHILD_COMPANY',
      'SUBSIDIARY_OF',
      'OWNS',
      'CONTROLS',
      'MANAGEMENT',
      'RELATED',
      'OTHER'
    )
  ) NOT VALID;

COMMIT;
