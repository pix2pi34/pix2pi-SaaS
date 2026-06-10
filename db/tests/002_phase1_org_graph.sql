BEGIN;

INSERT INTO platform.tenants (id, business_code, name, slug)
VALUES ('33333333-3333-3333-3333-333333333333', 'TENANT_C', 'Tenant C', 'tenant-c');

INSERT INTO org.legal_entities (id, tenant_id, business_code, legal_name, tax_number)
VALUES
  ('ccccccc1-cccc-cccc-cccc-ccccccccccc1', '33333333-3333-3333-3333-333333333333', 'HOLDING', 'Holding A.S.', '3333333333'),
  ('ccccccc2-cccc-cccc-cccc-ccccccccccc2', '33333333-3333-3333-3333-333333333333', 'OPCO', 'Operasyon A.S.', '3333333334'),
  ('ccccccc3-cccc-cccc-cccc-ccccccccccc3', '33333333-3333-3333-3333-333333333333', 'FRAN', 'Franchise Ltd.', '3333333335');

INSERT INTO org.entity_relations (tenant_id, parent_entity_id, child_entity_id, relation_type, ownership_ratio, effective_from)
VALUES
  ('33333333-3333-3333-3333-333333333333', 'ccccccc1-cccc-cccc-cccc-ccccccccccc1', 'ccccccc2-cccc-cccc-cccc-ccccccccccc2', 'SUBSIDIARY', 100, current_date),
  ('33333333-3333-3333-3333-333333333333', 'ccccccc1-cccc-cccc-cccc-ccccccccccc1', 'ccccccc3-cccc-cccc-cccc-ccccccccccc3', 'FRANCHISE_PARTNER', 20, current_date);

WITH RECURSIVE graph AS (
  SELECT parent_entity_id, child_entity_id, 1 AS depth
  FROM org.entity_relations
  WHERE tenant_id = '33333333-3333-3333-3333-333333333333'
  UNION ALL
  SELECT g.parent_entity_id, er.child_entity_id, g.depth + 1
  FROM graph g
  JOIN org.entity_relations er ON er.parent_entity_id = g.child_entity_id
)
SELECT CASE WHEN count(*) >= 2 THEN 'OK ✅ org graph seeded'
            ELSE 'HATA ❌ org graph missing'
       END AS org_graph_result
FROM graph;

ROLLBACK;

