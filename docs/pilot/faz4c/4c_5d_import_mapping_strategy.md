# FAZ 4C — 4C-5D Import Mapping Strategy Decision

## Amac

uzmanparcaci ürün/stok import verisinin hangi strateji ile sisteme alınacağını belirlemek.

Bu adim DB'ye yazmaz.

---

## 1. Tenant kontrolu

TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_COUNT=1
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_SCHEMA_EXISTS=1

---

## 2. Seçilen strateji

SELECTED_IMPORT_MAPPING_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING
CORE_DIRECT_APPLY_NOW=NO
STAGING_TABLE_CREATE_NEEDED=YES
STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
STAGING_TABLE_EXISTS=0

Karar:
Oto yedek parça özel alanları ve veri kalite riski sebebiyle önce staging/import tablosu kullanılacaktır.
ERP core tablolarına doğrudan yazma bu adımda yapılmayacaktır.

---

## 3. Core tablo hedefleri

PRODUCT_TABLE=public.erp_items
PRODUCT_TABLE_EXISTS=1
STOCK_TABLE=public.erp_stock_movements
STOCK_TABLE_EXISTS=1
CATEGORY_TABLE=public.erp_product_categories
CATEGORY_TABLE_EXISTS=1
UNIT_TABLE=public.erp_units
UNIT_TABLE_EXISTS=1

---

## 4. CSV -> Product mapping

product_name -> public.erp_items.item_name
sku -> public.erp_items.sku
category -> public.erp_items.category_id
unit -> public.erp_items.STAGING_ONLY
sale_price -> public.erp_items.STAGING_ONLY
purchase_price -> public.erp_items.STAGING_ONLY
currency -> public.erp_items.STAGING_ONLY
tenant_id -> public.erp_items.tenant_id
oem_code -> public.erp_items.STAGING_ONLY
equivalent_code -> public.erp_items.STAGING_ONLY
vehicle_fitment_note -> public.erp_items.STAGING_ONLY

---

## 5. CSV -> Stock mapping

initial_stock_qty -> public.erp_stock_movements.quantity
product_ref -> public.erp_stock_movements.item_id
tenant_id -> public.erp_stock_movements.tenant_id
movement_type -> public.erp_stock_movements.movement_type
reason -> public.erp_stock_movements.note

---

## 6. Fit sonucu

CORE_DIRECT_REQUIRED_OK=NO
AUTO_PART_SPECIAL_DIRECT_OK=NO

Product columns:
    item_id:uuid:nullable=NO:default=gen_random_uuid()
    tenant_id:text:nullable=NO:default=
    item_code:text:nullable=NO:default=
    item_name:text:nullable=NO:default=
    item_type:text:nullable=NO:default='stock'::text
    category_id:uuid:nullable=YES:default=
    base_unit_id:uuid:nullable=NO:default=
    barcode:text:nullable=YES:default=
    sku:text:nullable=YES:default=
    vat_rate:numeric:nullable=NO:default=20.00
    is_inventory_tracked:boolean:nullable=NO:default=true
    is_sales_allowed:boolean:nullable=NO:default=true
    is_purchase_allowed:boolean:nullable=NO:default=true
    status:text:nullable=NO:default='active'::text
    created_at:timestamp with time zone:nullable=NO:default=now()
    updated_at:timestamp with time zone:nullable=NO:default=now()
    deleted_at:timestamp with time zone:nullable=YES:default=
    created_by:text:nullable=YES:default=
    updated_by:text:nullable=YES:default=

Stock columns:
    stock_movement_id:uuid:nullable=NO:default=gen_random_uuid()
    tenant_id:text:nullable=NO:default=
    movement_no:text:nullable=NO:default=
    movement_type:text:nullable=NO:default=
    movement_direction:text:nullable=NO:default=
    warehouse_id:uuid:nullable=NO:default=
    item_id:uuid:nullable=NO:default=
    unit_id:uuid:nullable=NO:default=
    quantity:numeric:nullable=NO:default=
    unit_cost:numeric:nullable=NO:default=0
    total_cost:numeric:nullable=NO:default=0
    source_type:text:nullable=YES:default=
    source_id:text:nullable=YES:default=
    source_line_id:text:nullable=YES:default=
    movement_at:timestamp with time zone:nullable=NO:default=now()
    posted_at:timestamp with time zone:nullable=YES:default=
    status:text:nullable=NO:default='posted'::text
    note:text:nullable=YES:default=
    created_at:timestamp with time zone:nullable=NO:default=now()
    updated_at:timestamp with time zone:nullable=NO:default=now()
    deleted_at:timestamp with time zone:nullable=YES:default=
    created_by:text:nullable=YES:default=
    updated_by:text:nullable=YES:default=

---

## 7. Status

4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=PASS
4C_5D_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING
4C_5D_CORE_DIRECT_APPLY_NOW=NO
4C_5D_STAGING_TABLE_CREATE_NEEDED=YES
4C_5D_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5D_STAGING_TABLE_EXISTS=0
4C_5D_PRODUCT_TABLE=public.erp_items
4C_5D_STOCK_TABLE=public.erp_stock_movements
4C_5D_CORE_DIRECT_REQUIRED_OK=NO
4C_5D_AUTO_PART_SPECIAL_DIRECT_OK=NO
4C_5D_DB_WRITE_APPLIED=NO
4C_5D_CRITICAL_BLOCKER_COUNT=0
4C_5D_WARNING_COUNT=2
4C_5E_READY=YES
