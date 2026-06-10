-- FAZ 4C — 4C-3F Tenant Commit SQL Package
-- Purpose: uzmanparcaci real pilot tenant setup
-- IMPORTANT:
--   This file is a COMMIT package.
--   4C-3F only creates this file.
--   4C-3F does NOT execute it.
--   Execution must happen in 4C-3G Apply step only.

BEGIN;

-- 1. Safety check: selected tenant table must exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'platform'
      AND table_name = 'tenants'
  ) THEN
    RAISE EXCEPTION 'Selected tenant table %.% does not exist', 'platform', 'tenants';
  END IF;
END
$$;

-- 2. Safety check: required columns must exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='platform'
      AND table_name='tenants'
      AND column_name='business_code'
  ) THEN
    RAISE EXCEPTION 'Required column platform.tenants.business_code does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='platform'
      AND table_name='tenants'
      AND column_name='slug'
  ) THEN
    RAISE EXCEPTION 'Required column platform.tenants.slug does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='platform'
      AND table_name='tenants'
      AND column_name='name'
  ) THEN
    RAISE EXCEPTION 'Required column platform.tenants.name does not exist';
  END IF;
END
$$;

-- 3. Safety check: business_code must satisfy core.code_text
SELECT 'UZMANPARCACI'::core.code_text;

-- 4. Create tenant schema guarded
CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci;

-- 5. Insert tenant metadata guarded
INSERT INTO platform.tenants (
  business_code,
  slug,
  name,
  status,
  created_at,
  updated_at
)
SELECT
  'UZMANPARCACI'::core.code_text,
  'uzmanparcaci',
  'uzmanparcaci',
  'active',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1
  FROM platform.tenants
  WHERE slug = 'uzmanparcaci'
     OR business_code = 'UZMANPARCACI'::core.code_text
);

-- 6. Verification before commit
DO $$
DECLARE
  schema_count integer;
  tenant_count integer;
BEGIN
  SELECT count(*) INTO schema_count
  FROM information_schema.schemata
  WHERE schema_name = 'tenant_uzmanparcaci';

  SELECT count(*) INTO tenant_count
  FROM platform.tenants
  WHERE slug = 'uzmanparcaci'
     OR business_code = 'UZMANPARCACI'::core.code_text;

  IF schema_count <> 1 THEN
    RAISE EXCEPTION 'Tenant schema verification failed. schema_count=%', schema_count;
  END IF;

  IF tenant_count <> 1 THEN
    RAISE EXCEPTION 'Tenant metadata verification failed. tenant_count=%', tenant_count;
  END IF;
END
$$;

COMMIT;
