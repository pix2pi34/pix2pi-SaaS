-- FAZ 4C — 4C-5F Import SQL Package / Dry Run Plan
-- Purpose: uzmanparcaci product import staging preview
-- IMPORTANT:
--   This SQL file is preview only.
--   It ends with ROLLBACK intentionally.
--   4C-5F does NOT perform permanent DB write.
--
-- Generated at: 2026-05-01T05:07:56.511626+00:00
-- Tenant business_code: UZMANPARCACI
-- Tenant schema: tenant_uzmanparcaci
-- Staging table: tenant_uzmanparcaci.pilot_product_import_staging
-- Sample row count: 5

BEGIN;

-- 1. Safety check: tenant must exist
DO $$
DECLARE
  tenant_count integer;
BEGIN
  SELECT count(*) INTO tenant_count
  FROM platform.tenants
  WHERE id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND business_code='UZMANPARCACI'::core.code_text;

  IF tenant_count <> 1 THEN
    RAISE EXCEPTION 'Tenant verification failed. tenant_count=%', tenant_count;
  END IF;
END
$$;

-- 2. Safety check: tenant schema must exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.schemata
    WHERE schema_name='tenant_uzmanparcaci'
  ) THEN
    RAISE EXCEPTION 'Tenant schema tenant_uzmanparcaci does not exist';
  END IF;
END
$$;

-- 3. Create staging table guarded
CREATE TABLE IF NOT EXISTS tenant_uzmanparcaci.pilot_product_import_staging (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  import_batch_code text NOT NULL,
  source_file text NOT NULL,
  source_row_number integer NOT NULL,
  product_name text NOT NULL,
  sku text NOT NULL,
  category text NOT NULL,
  unit text NOT NULL,
  initial_stock_qty numeric(18,4) NOT NULL,
  sale_price numeric(18,4) NOT NULL,
  purchase_price numeric(18,4) NOT NULL,
  currency text NOT NULL,
  oem_code text NOT NULL,
  equivalent_code text NOT NULL,
  vehicle_fitment_note text NOT NULL,
  brand text NOT NULL,
  part_group text NOT NULL,
  barcode text NULL,
  notes text NULL,
  validation_status text NOT NULL DEFAULT 'VALIDATED',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Insert sample rows into staging
INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging (
  tenant_id,
  import_batch_code,
  source_file,
  source_row_number,
  product_name,
  sku,
  category,
  unit,
  initial_stock_qty,
  sale_price,
  purchase_price,
  currency,
  oem_code,
  equivalent_code,
  vehicle_fitment_note,
  brand,
  part_group,
  barcode,
  notes
)
SELECT
  '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,
  'UZMANPARCACI_SAMPLE_4C5E',
  'product_import_sample.csv',
  2,
  'Fren Balatasi On Takim',
  'UZP-FREN-0001',
  'Fren Sistemi',
  'ADET',
  12,
  1250,
  850,
  'TRY',
  'OEM-FREN-001',
  'EQ-FREN-001',
  'Renault Megane 3 / Fluence uyumlu',
  'Ornek Marka',
  'Fren',
  NULL,
  'Pilot sample 1'
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
    AND sku='UZP-FREN-0001'
);

INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging (
  tenant_id,
  import_batch_code,
  source_file,
  source_row_number,
  product_name,
  sku,
  category,
  unit,
  initial_stock_qty,
  sale_price,
  purchase_price,
  currency,
  oem_code,
  equivalent_code,
  vehicle_fitment_note,
  brand,
  part_group,
  barcode,
  notes
)
SELECT
  '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,
  'UZMANPARCACI_SAMPLE_4C5E',
  'product_import_sample.csv',
  3,
  'Yag Filtresi',
  'UZP-FILTRE-0002',
  'Filtre',
  'ADET',
  25,
  320,
  210,
  'TRY',
  'OEM-FILTRE-002',
  'EQ-FILTRE-002',
  'Renault Clio / Symbol uyumlu',
  'Ornek Marka',
  'Filtre',
  NULL,
  'Pilot sample 2'
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
    AND sku='UZP-FILTRE-0002'
);

INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging (
  tenant_id,
  import_batch_code,
  source_file,
  source_row_number,
  product_name,
  sku,
  category,
  unit,
  initial_stock_qty,
  sale_price,
  purchase_price,
  currency,
  oem_code,
  equivalent_code,
  vehicle_fitment_note,
  brand,
  part_group,
  barcode,
  notes
)
SELECT
  '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,
  'UZMANPARCACI_SAMPLE_4C5E',
  'product_import_sample.csv',
  4,
  'Hava Filtresi',
  'UZP-FILTRE-0003',
  'Filtre',
  'ADET',
  18,
  450,
  300,
  'TRY',
  'OEM-HAVA-003',
  'EQ-HAVA-003',
  'Fiat Egea / Linea uyumlu',
  'Ornek Marka',
  'Filtre',
  NULL,
  'Pilot sample 3'
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
    AND sku='UZP-FILTRE-0003'
);

INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging (
  tenant_id,
  import_batch_code,
  source_file,
  source_row_number,
  product_name,
  sku,
  category,
  unit,
  initial_stock_qty,
  sale_price,
  purchase_price,
  currency,
  oem_code,
  equivalent_code,
  vehicle_fitment_note,
  brand,
  part_group,
  barcode,
  notes
)
SELECT
  '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,
  'UZMANPARCACI_SAMPLE_4C5E',
  'product_import_sample.csv',
  5,
  'Amortisor On Sag',
  'UZP-SUSP-0004',
  'Suspansiyon',
  'ADET',
  6,
  2100,
  1500,
  'TRY',
  'OEM-AMORT-004',
  'EQ-AMORT-004',
  'Ford Focus 3 on sag uyumlu',
  'Ornek Marka',
  'Suspansiyon',
  NULL,
  'Pilot sample 4'
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
    AND sku='UZP-SUSP-0004'
);

INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging (
  tenant_id,
  import_batch_code,
  source_file,
  source_row_number,
  product_name,
  sku,
  category,
  unit,
  initial_stock_qty,
  sale_price,
  purchase_price,
  currency,
  oem_code,
  equivalent_code,
  vehicle_fitment_note,
  brand,
  part_group,
  barcode,
  notes
)
SELECT
  '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,
  'UZMANPARCACI_SAMPLE_4C5E',
  'product_import_sample.csv',
  6,
  'Triger Seti',
  'UZP-MOTOR-0005',
  'Motor',
  'SET',
  4,
  3900,
  2800,
  'TRY',
  'OEM-TRIGER-005',
  'EQ-TRIGER-005',
  'Volkswagen Golf / Jetta uyumlu',
  'Ornek Marka',
  'Motor',
  NULL,
  'Pilot sample 5'
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
    AND sku='UZP-MOTOR-0005'
);

-- 5. Verification
SELECT 'staging_row_count' AS check_name, count(*)::text AS check_value
FROM tenant_uzmanparcaci.pilot_product_import_staging
WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
  AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E';

SELECT 'duplicate_sku_count' AS check_name, count(*)::text AS check_value
FROM (
  SELECT sku
  FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
  GROUP BY sku
  HAVING count(*) > 1
) d;

ROLLBACK;

-- Note:
-- This preview intentionally ends with ROLLBACK.
-- 4C-5G will execute this preview and verify rollback safety.
