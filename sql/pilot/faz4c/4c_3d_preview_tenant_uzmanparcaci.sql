-- FAZ 4C — 4C-3D-FIX3 Tenant Apply SQL Package / Preview
-- Purpose: uzmanparcaci tenant setup SQL preview
-- Fix: business_code converted to core.code_text compatible uppercase value
-- IMPORTANT:
--   This SQL file is generated as preview.
--   It is NOT committed.
--   It ends with ROLLBACK intentionally.
--
-- Generated at: 2026-05-01 07:23:16
-- Selected tenant table: platform.tenants
-- Tenant schema: tenant_uzmanparcaci
-- Tenant business_code: UZMANPARCACI
-- Tenant slug: uzmanparcaci

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

-- 4. Create schema guarded
CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci;

-- 5. Insert tenant metadata guarded
-- Existing count detected during generation: 0
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

-- 6. Verification
SELECT 'tenant_schema_exists' AS check_name, count(*)::text AS check_value
FROM information_schema.schemata
WHERE schema_name = 'tenant_uzmanparcaci';

SELECT 'tenant_metadata_exists' AS check_name, count(*)::text AS check_value
FROM platform.tenants
WHERE slug = 'uzmanparcaci'
   OR business_code = 'UZMANPARCACI'::core.code_text;

ROLLBACK;

-- Note:
-- This preview intentionally ends with ROLLBACK.
-- Later apply step will generate/execute a guarded COMMIT version only after approval.
