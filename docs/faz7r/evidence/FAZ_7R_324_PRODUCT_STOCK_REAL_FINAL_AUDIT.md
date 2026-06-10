# FAZ 7-R / 324 PRODUCT STOCK REAL FINAL AUDIT

- PASS_COUNT=63
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
tenant_b_opened=1
tenant_b_owner_role=1
no_role_count=0
```
## Create response
```json
{"ok": true, "product_id": "product-324-main", "tenant_id": "tenant-api-e2e-success", "product_code": "PRD-324-001", "barcode": "8690000000324", "sku": "SKU-323-324-001", "stock_quantity": 15.0, "sale_price": 19.9, "vat_rate": 20.0}
```
## Create SELECT
```
product_created=1
category_created=1
opening_stock_movement=1
create_audit=1
```
## Second product response
```json
{"ok": true, "product_id": "product-324-second", "tenant_id": "tenant-api-e2e-success", "product_code": "PRD-324-002", "barcode": "8690000000325", "sku": "SKU-323-324-002", "stock_quantity": 3.0, "sale_price": 35.0, "vat_rate": 10.0}
```
## Category filter response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"product_id": "product-324-second", "product_code": "PRD-324-002", "product_name": "324 Temizlik Ürünü", "barcode": "8690000000325", "sku": "SKU-323-324-002", "category_code": "CAT-324-TEMIZLIK", "unit_code": "kutu", "sale_price": "35.00", "vat_rate": "10.00", "stock_quantity": "3.000", "critical_stock_level": "5.000"}]}
```
## Low stock response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"product_id": "product-324-second", "product_code": "PRD-324-002", "product_name": "324 Temizlik Ürünü", "barcode": "8690000000325", "sku": "SKU-323-324-002", "category_code": "CAT-324-TEMIZLIK", "unit_code": "kutu", "sale_price": "35.00", "vat_rate": "10.00", "stock_quantity": "3.000", "critical_stock_level": "5.000"}]}
```
## Duplicate response
```json
{"ok": false, "error": "duplicate_record", "detail": "ERROR:  duplicate key value violates unique constraint \"ux_erp_inventory_product_tenant_barcode\"\nDETAIL:  Key (tenant_id, lower(barcode))=(tenant-api-e2e-success, 8690000000324) already exists.\n"}
```
## Duplicate SELECT
```
duplicate_product=0
duplicate_stock_movement=0
duplicate_audit=0
```
## Update response
```json
{"ok": true, "product_id": "product-324-main", "tenant_id": "tenant-api-e2e-success", "updated": true}
```
## Update SELECT
```
product_updated=1
update_audit=1
```
## Stock movement response
```json
{"ok": true, "movement_id": "stock-movement-46e71711-c78e-49d8-aa3b-ee579024f69d", "product_id": "product-324-main", "tenant_id": "tenant-api-e2e-success", "stock_after": 25.0}
```
## Stock SELECT
```
product_stock=1
stock_movement_count=2
stock_audit=1
```
## List response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"product_id": "product-324-main", "product_code": "PRD-324-001", "product_name": "324 Test Ürün Güncel", "barcode": "8690000000324", "sku": "SKU-323-324-001", "category_code": "CAT-324-GIDA", "unit_code": "adet", "sale_price": "24.90", "vat_rate": "10.00", "stock_quantity": "25.000", "critical_stock_level": "7.000"}]}
```
## Insufficient stock response
```json
{"ok": false, "error": "insufficient_stock", "stock_quantity": 25.0}
```
## Insufficient SELECT
```
stock_still_25=1
bad_out_movement=0
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## Cross tenant response
```json
{"ok": false, "error": "cross_tenant_denied"}
```
## Cross tenant SELECT
```
tenant_b_unchanged=1
cross_bad_update=0
cross_deny_audit=1
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_product=0
rollback_stock_movement=0
rollback_audit=0
```
## Final SELECT
```
tenant_a_products=2
tenant_a_categories=2
tenant_a_stock_movements=3
tenant_a_audit=5
tenant_b_products=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: erp_inventory.product_audit_events / OK ✅
table exists: erp_inventory.product_categories / OK ✅
table exists: erp_inventory.products / OK ✅
table exists: erp_inventory.stock_movements / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
product create route reaches API 422 / OK ✅
frontend products page written / OK ✅
test cleanup and seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
REAL_CURL_CREATE_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS product_created=1 / OK ✅
REAL_DB_SELECT_STATUS category_created=1 / OK ✅
REAL_DB_SELECT_STATUS opening_stock_movement=1 / OK ✅
REAL_DB_SELECT_STATUS create_audit=1 / OK ✅
SECOND_PRODUCT_CREATE_STATUS HTTP 201 / OK ✅
PRODUCT_CATEGORY_FILTER_STATUS category listed / OK ✅
CRITICAL_STOCK_STATUS low stock listed / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_product=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_stock_movement=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_audit=0 / OK ✅
REAL_CURL_UPDATE_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS product_updated=1 / OK ✅
REAL_DB_SELECT_STATUS update_audit=1 / OK ✅
REAL_CURL_STOCK_MOVEMENT_STATUS HTTP 201 stock_after 25 / OK ✅
REAL_DB_SELECT_STATUS product_stock=1 / OK ✅
REAL_DB_SELECT_STATUS stock_movement_count=2 / OK ✅
REAL_DB_SELECT_STATUS stock_audit=1 / OK ✅
PRODUCT_LIST_SEARCH_STATUS HTTP 200 search found / OK ✅
INSUFFICIENT_STOCK_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS insufficient stock blocked: stock_still_25=1 / OK ✅
PARTIAL_WRITE_STATUS insufficient stock blocked: bad_out_movement=0 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
TENANT_B_PRODUCT_CREATE_STATUS HTTP 201 / OK ✅
CROSS_TENANT_GUARD_STATUS update denied HTTP 403 / OK ✅
CROSS_TENANT_DB_STATUS tenant_b_unchanged=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_bad_update=0 / OK ✅
CROSS_TENANT_DB_STATUS cross_deny_audit=1 / OK ✅
ROLLBACK_STATUS create HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_product=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_stock_movement=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /products/ marker / OK ✅
FINAL_DB_STATUS tenant_a_products >= 2 / OK ✅
FINAL_DB_STATUS tenant_a_categories >= 2 / OK ✅
FINAL_DB_STATUS tenant_a_stock_movements >= 3 / OK ✅
FINAL_DB_STATUS tenant_a_audit >= 4 / OK ✅
FINAL_DB_STATUS tenant_b_products=1 / OK ✅
config semantic validation / OK ✅
```
