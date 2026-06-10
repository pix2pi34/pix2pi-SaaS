# FAZ 4C — 4C-5C Product / Stock Table Discovery

## Amac

uzmanparcaci import akisi icin mevcut urun, stok, kategori ve birim tablolarini kesfetmek.

Bu adim DB'ye yazmaz.

---

## 1. Tenant kontrolu

TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_COUNT=1
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_SCHEMA_COUNT=1

---

## 2. Product tablo adaylari

PRODUCT_TABLE_COUNT=4
public.erp_items
public.erp_parties
public.erp_product_categories
public.erp_products

Product score details:
public.erp_items=score:135
public.erp_parties=score:40
public.erp_product_categories=score:75
public.erp_products=score:130


BEST_PRODUCT_TABLE=public.erp_items
BEST_PRODUCT_SCORE=135

Best product columns:
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

---

## 3. Stock tablo adaylari

STOCK_TABLE_COUNT=3
public.erp_account_movements
public.erp_stock_movements
readmodel.inventory_status_snapshot

Stock score details:
public.erp_account_movements=score:65
public.erp_stock_movements=score:120
readmodel.inventory_status_snapshot=score:90


BEST_STOCK_TABLE=public.erp_stock_movements
BEST_STOCK_SCORE=120

Best stock columns:
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

## 4. Category tablo adaylari

CATEGORY_TABLE_COUNT=1
public.erp_product_categories

---

## 5. Unit tablo adaylari

UNIT_TABLE_COUNT=1
public.erp_units

---

## 6. Karar notu

Bu adim sadece discovery yapar.
Eger tablo adayi yoksa bu adim fail olmaz; 4C-5D mapping strategy icinde create-vs-use-existing karari verilir.

---

## 7. Status

4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=PASS
4C_5C_DB_CONNECT_STATUS=PASS
4C_5C_TENANT_COUNT=1
4C_5C_TENANT_SCHEMA_COUNT=1
4C_5C_PRODUCT_TABLE_COUNT=4
4C_5C_STOCK_TABLE_COUNT=3
4C_5C_CATEGORY_TABLE_COUNT=1
4C_5C_UNIT_TABLE_COUNT=1
4C_5C_BEST_PRODUCT_TABLE=public.erp_items
4C_5C_BEST_PRODUCT_SCORE=135
4C_5C_BEST_STOCK_TABLE=public.erp_stock_movements
4C_5C_BEST_STOCK_SCORE=120
4C_5C_DB_WRITE_APPLIED=NO
4C_5C_CRITICAL_BLOCKER_COUNT=0
4C_5C_WARNING_COUNT=0
4C_5D_READY=YES
