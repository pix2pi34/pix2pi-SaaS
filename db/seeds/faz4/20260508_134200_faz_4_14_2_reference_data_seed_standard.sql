-- 184 — FAZ 4-14.2 Reference Data / Seed Standardı
-- Runtime variables:
--   schema_name
--   seed_scope
--   seed_version
--   applied_by
--   correlation_id

CREATE TABLE IF NOT EXISTS :"schema_name".reference_seed_sets (
    seed_scope       TEXT NOT NULL,
    seed_version     TEXT NOT NULL,
    seed_hash        TEXT NOT NULL,
    status           TEXT NOT NULL DEFAULT 'APPLIED',
    applied_by       TEXT NOT NULL,
    correlation_id   TEXT NOT NULL,
    metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT reference_seed_sets_pk
      PRIMARY KEY (seed_scope, seed_version),

    CONSTRAINT reference_seed_sets_status_chk
      CHECK (status IN ('APPLIED', 'SUPERSEDED', 'DISABLED'))
);

CREATE TABLE IF NOT EXISTS :"schema_name".reference_seed_items (
    seed_scope       TEXT NOT NULL,
    seed_version     TEXT NOT NULL,
    item_type        TEXT NOT NULL,
    item_code        TEXT NOT NULL,
    item_name        TEXT NOT NULL,
    item_payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order       INTEGER NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT reference_seed_items_pk
      PRIMARY KEY (seed_scope, seed_version, item_type, item_code),

    CONSTRAINT reference_seed_items_set_fk
      FOREIGN KEY (seed_scope, seed_version)
      REFERENCES :"schema_name".reference_seed_sets (seed_scope, seed_version)
      ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS reference_seed_items_type_idx
  ON :"schema_name".reference_seed_items (seed_scope, seed_version, item_type);

CREATE INDEX IF NOT EXISTS reference_seed_items_active_idx
  ON :"schema_name".reference_seed_items (seed_scope, seed_version, item_type, is_active);

INSERT INTO :"schema_name".reference_seed_sets (
  seed_scope,
  seed_version,
  seed_hash,
  status,
  applied_by,
  correlation_id,
  metadata
) VALUES (
  :'seed_scope',
  :'seed_version',
  md5(:'seed_scope' || ':' || :'seed_version' || ':FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD'),
  'APPLIED',
  :'applied_by',
  :'correlation_id',
  jsonb_build_object(
    'phase', 'FAZ_4_R',
    'phase_no', 184,
    'step', 'FAZ_4_14_2',
    'policy', 'CLOSED_POLICY_GATE_REFERENCE_ONLY'
  )
)
ON CONFLICT (seed_scope, seed_version)
DO UPDATE SET
  seed_hash = EXCLUDED.seed_hash,
  status = EXCLUDED.status,
  applied_by = EXCLUDED.applied_by,
  correlation_id = EXCLUDED.correlation_id,
  metadata = EXCLUDED.metadata,
  updated_at = now();

INSERT INTO :"schema_name".reference_seed_items (
  seed_scope,
  seed_version,
  item_type,
  item_code,
  item_name,
  item_payload,
  is_active,
  sort_order
) VALUES
  (:'seed_scope', :'seed_version', 'IMPORT_TYPE', 'CUSTOMER', 'Cari import', '{"entity":"customer"}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'IMPORT_TYPE', 'PRODUCT', 'Ürün import', '{"entity":"product"}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'IMPORT_TYPE', 'STOCK', 'Stok import', '{"entity":"stock"}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'IMPORT_TYPE', 'FINANCE_DOCUMENT', 'Fiş / hareket import', '{"entity":"finance_document"}'::jsonb, TRUE, 40),
  (:'seed_scope', :'seed_version', 'IMPORT_TYPE', 'MIXED', 'Karma import', '{"entity":"mixed"}'::jsonb, TRUE, 50),

  (:'seed_scope', :'seed_version', 'IMPORT_STATUS', 'CREATED', 'Oluşturuldu', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'IMPORT_STATUS', 'DRY_RUN_STARTED', 'Dry-run başladı', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'IMPORT_STATUS', 'DRY_RUN_COMPLETED', 'Dry-run tamamlandı', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'IMPORT_STATUS', 'VALIDATED', 'Doğrulandı', '{}'::jsonb, TRUE, 40),
  (:'seed_scope', :'seed_version', 'IMPORT_STATUS', 'COMMITTED', 'Commit edildi', '{}'::jsonb, TRUE, 50),
  (:'seed_scope', :'seed_version', 'IMPORT_STATUS', 'FAILED', 'Hatalı', '{}'::jsonb, TRUE, 60),

  (:'seed_scope', :'seed_version', 'ENTITY_TYPE', 'CUSTOMER', 'Cari', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'ENTITY_TYPE', 'PRODUCT', 'Ürün', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'ENTITY_TYPE', 'STOCK', 'Stok', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'ENTITY_TYPE', 'FINANCE_DOCUMENT', 'Finans belgesi', '{}'::jsonb, TRUE, 40),

  (:'seed_scope', :'seed_version', 'VALIDATION_STATUS', 'PENDING', 'Bekliyor', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'VALIDATION_STATUS', 'VALID', 'Geçerli', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'VALIDATION_STATUS', 'INVALID', 'Geçersiz', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'VALIDATION_STATUS', 'DUPLICATE', 'Mükerrer', '{}'::jsonb, TRUE, 40),
  (:'seed_scope', :'seed_version', 'VALIDATION_STATUS', 'SKIPPED', 'Atlandı', '{}'::jsonb, TRUE, 50),

  (:'seed_scope', :'seed_version', 'TRANSFORM_STATUS', 'PENDING', 'Bekliyor', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'TRANSFORM_STATUS', 'TRANSFORMED', 'Dönüştürüldü', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'TRANSFORM_STATUS', 'TRANSFORM_FAILED', 'Dönüşüm hatalı', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'TRANSFORM_STATUS', 'SKIPPED', 'Atlandı', '{}'::jsonb, TRUE, 40),

  (:'seed_scope', :'seed_version', 'COMMIT_STATUS', 'NOT_COMMITTED', 'Commit edilmedi', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'COMMIT_STATUS', 'COMMIT_READY', 'Commit hazır', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'COMMIT_STATUS', 'COMMITTED', 'Commit edildi', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'COMMIT_STATUS', 'COMMIT_FAILED', 'Commit hatalı', '{}'::jsonb, TRUE, 40),
  (:'seed_scope', :'seed_version', 'COMMIT_STATUS', 'ROLLED_BACK', 'Geri alındı', '{}'::jsonb, TRUE, 50),

  (:'seed_scope', :'seed_version', 'CUSTOMER_TYPE', 'COMMERCIAL', 'Ticari cari', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'CUSTOMER_TYPE', 'INDIVIDUAL', 'Bireysel cari', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'CUSTOMER_TYPE', 'SUPPLIER', 'Tedarikçi', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'CUSTOMER_TYPE', 'BOTH', 'Cari + tedarikçi', '{}'::jsonb, TRUE, 40),

  (:'seed_scope', :'seed_version', 'PRODUCT_TYPE', 'STOCK_ITEM', 'Stok ürünü', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'PRODUCT_TYPE', 'SERVICE', 'Hizmet', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'PRODUCT_TYPE', 'BUNDLE', 'Paket ürün', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'PRODUCT_TYPE', 'RAW_MATERIAL', 'Hammadde', '{}'::jsonb, TRUE, 40),

  (:'seed_scope', :'seed_version', 'STOCK_MOVEMENT_TYPE', 'OPENING', 'Açılış', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'STOCK_MOVEMENT_TYPE', 'IN', 'Giriş', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'STOCK_MOVEMENT_TYPE', 'OUT', 'Çıkış', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'STOCK_MOVEMENT_TYPE', 'ADJUSTMENT', 'Düzeltme', '{}'::jsonb, TRUE, 40),
  (:'seed_scope', :'seed_version', 'STOCK_MOVEMENT_TYPE', 'TRANSFER', 'Transfer', '{}'::jsonb, TRUE, 50),

  (:'seed_scope', :'seed_version', 'FINANCE_DOCUMENT_TYPE', 'SALES_INVOICE', 'Satış faturası', '{}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'FINANCE_DOCUMENT_TYPE', 'PURCHASE_INVOICE', 'Alış faturası', '{}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'FINANCE_DOCUMENT_TYPE', 'RECEIPT', 'Fiş', '{}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'FINANCE_DOCUMENT_TYPE', 'PAYMENT', 'Ödeme', '{}'::jsonb, TRUE, 40),
  (:'seed_scope', :'seed_version', 'FINANCE_DOCUMENT_TYPE', 'COLLECTION', 'Tahsilat', '{}'::jsonb, TRUE, 50),

  (:'seed_scope', :'seed_version', 'UNIT', 'ADET', 'Adet', '{"decimal":false}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'UNIT', 'KG', 'Kilogram', '{"decimal":true}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'UNIT', 'LT', 'Litre', '{"decimal":true}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'UNIT', 'MT', 'Metre', '{"decimal":true}'::jsonb, TRUE, 40),

  (:'seed_scope', :'seed_version', 'CURRENCY', 'TRY', 'Türk Lirası', '{"symbol":"₺"}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'CURRENCY', 'USD', 'Amerikan Doları', '{"symbol":"$"}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'CURRENCY', 'EUR', 'Euro', '{"symbol":"€"}'::jsonb, TRUE, 30),

  (:'seed_scope', :'seed_version', 'VAT_RATE', 'VAT_0', 'KDV %0', '{"rate":0}'::jsonb, TRUE, 10),
  (:'seed_scope', :'seed_version', 'VAT_RATE', 'VAT_1', 'KDV %1', '{"rate":1}'::jsonb, TRUE, 20),
  (:'seed_scope', :'seed_version', 'VAT_RATE', 'VAT_10', 'KDV %10', '{"rate":10}'::jsonb, TRUE, 30),
  (:'seed_scope', :'seed_version', 'VAT_RATE', 'VAT_20', 'KDV %20', '{"rate":20}'::jsonb, TRUE, 40)
ON CONFLICT (seed_scope, seed_version, item_type, item_code)
DO UPDATE SET
  item_name = EXCLUDED.item_name,
  item_payload = EXCLUDED.item_payload,
  is_active = EXCLUDED.is_active,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();

SELECT
  'REFERENCE_DATA_SEED_APPLY_RESULT' AS mode,
  seed_scope,
  seed_version,
  COUNT(*) AS seed_item_count
FROM :"schema_name".reference_seed_items
WHERE seed_scope = :'seed_scope'
  AND seed_version = :'seed_version'
GROUP BY seed_scope, seed_version;

-- REFERENCE_DATA_SEED_STANDARD_IMPLEMENTED
