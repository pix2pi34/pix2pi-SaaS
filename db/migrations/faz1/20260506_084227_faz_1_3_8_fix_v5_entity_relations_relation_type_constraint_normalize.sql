BEGIN;

ALTER TABLE org.entity_relations
  DROP CONSTRAINT IF EXISTS ck_org_entity_relations_relation_type;

ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_relation_type
  CHECK (
    relation_type IS NOT NULL
    AND btrim(relation_type::text) <> ''
    AND relation_type IN (
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
