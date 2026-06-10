BEGIN;

-- seed as admin/current owner role
INSERT INTO platform.tenants (id, business_code, name, slug)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'TENANT_A', 'Tenant A', 'tenant-a'),
  ('22222222-2222-2222-2222-222222222222', 'TENANT_B', 'Tenant B', 'tenant-b')
ON CONFLICT (id) DO NOTHING;

INSERT INTO org.legal_entities (id, tenant_id, business_code, legal_name, tax_number)
VALUES
  ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'LE_A', 'A Sirketi', '1111111111'),
  ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '22222222-2222-2222-2222-222222222222', 'LE_B', 'B Sirketi', '2222222222')
ON CONFLICT (id) DO NOTHING;

INSERT INTO org.branches (id, tenant_id, legal_entity_id, business_code, name)
VALUES
  ('aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '11111111-1111-1111-1111-111111111111', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'BR_A', 'A Merkez'),
  ('bbbbbbb4-bbbb-bbbb-bbbb-bbbbbbbbbbb4', '22222222-2222-2222-2222-222222222222', 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'BR_B', 'B Merkez')
ON CONFLICT (id) DO NOTHING;

-- switch into non-bypass app role for real RLS checks
SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

-- should only see tenant A
SELECT CASE
         WHEN count(*) = 1 THEN 'OK ✅ tenant filter works'
         ELSE 'HATA ❌ tenant filter broken'
       END AS tenant_visibility_result
FROM org.legal_entities;

-- should fail on insert into tenant B
DO $$
BEGIN
  BEGIN
    INSERT INTO org.branches (tenant_id, legal_entity_id, business_code, name)
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbb2',
      'BR_X',
      'Yetkisiz'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant insert succeeded';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'OK ✅ cross tenant insert blocked by RLS';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ super-admin bypass works'
         ELSE 'HATA ❌ super-admin bypass missing'
       END AS super_admin_visibility_result
FROM org.legal_entities;

ROLLBACK;
