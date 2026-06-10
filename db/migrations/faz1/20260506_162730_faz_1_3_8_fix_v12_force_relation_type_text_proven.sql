BEGIN;

DO $$
DECLARE
  v_relation_type_type text;
  v_relation_type_domain_schema text;
  v_relation_type_domain_name text;
  v_status_type text;
  v_status_domain_schema text;
  v_status_domain_name text;
BEGIN
  SELECT c.data_type, c.domain_schema, c.domain_name
  INTO v_relation_type_type, v_relation_type_domain_schema, v_relation_type_domain_name
  FROM information_schema.columns c
  WHERE c.table_schema='org'
    AND c.table_name='entity_relations'
    AND c.column_name='relation_type'
  LIMIT 1;

  SELECT c.data_type, c.domain_schema, c.domain_name
  INTO v_status_type, v_status_domain_schema, v_status_domain_name
  FROM information_schema.columns c
  WHERE c.table_schema='org'
    AND c.table_name='entity_relations'
    AND c.column_name='status'
  LIMIT 1;

  -- relation_type mutlaka plain text olmalı.
  IF COALESCE(v_relation_type_type, '') <> 'text'
     OR COALESCE(v_relation_type_domain_schema, '') <> ''
     OR COALESCE(v_relation_type_domain_name, '') <> '' THEN
    EXECUTE 'ALTER TABLE org.entity_relations ALTER COLUMN relation_type TYPE text USING relation_type::text';
  END IF;

  -- status core.record_status enum/domain olabilir; dokunmuyoruz.
  -- Sadece yanlışlıkla core.code_text domain ise text'e çeviriyoruz.
  IF COALESCE(v_status_domain_schema, '')='core'
     AND COALESCE(v_status_domain_name, '')='code_text' THEN
    EXECUTE 'ALTER TABLE org.entity_relations ALTER COLUMN status TYPE text USING status::text';
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
