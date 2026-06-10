# FAZ 7-R / 331 POS SALE REAL FINAL AUDIT

- PASS_COUNT=55
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Readiness SELECT
```
tenant_opened=1
cashier_active=1
cashier_role=1
register_active=1
product_ready=1
tenant_b_product_ready=1
no_role_count=0
```
## Search response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"product_id": "product-324-main", "product_name": "324 Test Ürün Güncel", "barcode": "8690000000324", "sku": "SKU-323-324-001", "sale_price": "24.90", "vat_rate": "10.00", "stock_quantity": "25.000"}]}
```
## Quote response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "subtotal_amount": 49.8, "discount_amount": 5.0, "taxable_amount": 44.8, "vat_amount": 4.48, "total_amount": 49.28, "lines": [{"product_id": "product-324-main", "product_name": "324 Test Ürün Güncel", "barcode": "8690000000324", "sku": "SKU-323-324-001", "quantity": 2.0, "unit_price": 24.9, "discount_amount": 5.0, "vat_rate": 10.0, "vat_amount": 4.48, "line_total": 49.28, "stock_after": 23.0}]}
```
## Sale complete response
```json
{"ok": true, "sale_id": "sale-331-main", "tenant_id": "tenant-api-e2e-success", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "cashier_user_id": "user-321-cashier", "sale_status": "completed", "payment_status": "paid", "subtotal_amount": 49.8, "discount_amount": 5.0, "vat_amount": 4.48, "total_amount": 49.28, "line_count": 1}
```
## Sale SELECT
```
sale_completed=1
sale_line=1
sale_payment=1
product_stock_after_sale=1
stock_out_movement=1
sale_audit=1
```
## Insufficient response
```json
{"ok": false, "error": "insufficient_stock", "product_id": "product-324-main", "stock_quantity": 23.0}
```
## Insufficient SELECT
```
insufficient_sale=0
insufficient_line=0
insufficient_payment=0
stock_still_23=1
```
## No role response
```json
{"ok": false, "error": "cashier_user_has_no_role"}
```
## Cross tenant response
```json
{"ok": false, "error": "cross_tenant_denied", "product_id": "product-324-tenant-b"}
```
## Cross SELECT
```
cross_sale=0
tenant_b_stock_unchanged=1
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_sale=0
rollback_line=0
rollback_payment=0
rollback_stock_movement=0
stock_after_rollback=1
```
## Final SELECT
```
tenant_sales=1
tenant_sale_lines=1
tenant_sale_payments=1
tenant_sale_audit=1
stock_after_all=23.000
```
## Check log
```
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: pos_sales.sale_audit_events / OK ✅
table exists: pos_sales.sale_lines / OK ✅
table exists: pos_sales.sale_payments / OK ✅
table exists: pos_sales.sales / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
pos sale quote route reaches API 422 / OK ✅
frontend POS sale page written / OK ✅
test cleanup and stock reset completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS cashier_active=1 / OK ✅
READINESS_STATUS cashier_role=1 / OK ✅
READINESS_STATUS register_active=1 / OK ✅
READINESS_STATUS product_ready=1 / OK ✅
READINESS_STATUS tenant_b_product_ready=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
PRODUCT_SEARCH_STATUS barcode HTTP 200 found / OK ✅
POS_CART_QUOTE_STATUS subtotal discount VAT total / OK ✅
POS_SALE_COMPLETE_STATUS HTTP 201 completed paid / OK ✅
REAL_DB_SELECT_STATUS sale_completed=1 / OK ✅
REAL_DB_SELECT_STATUS sale_line=1 / OK ✅
REAL_DB_SELECT_STATUS sale_payment=1 / OK ✅
REAL_DB_SELECT_STATUS product_stock_after_sale=1 / OK ✅
REAL_DB_SELECT_STATUS stock_out_movement=1 / OK ✅
REAL_DB_SELECT_STATUS sale_audit=1 / OK ✅
INSUFFICIENT_STOCK_STATUS sale blocked HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS insufficient blocked: insufficient_sale=0 / OK ✅
PARTIAL_WRITE_STATUS insufficient blocked: insufficient_line=0 / OK ✅
PARTIAL_WRITE_STATUS insufficient blocked: insufficient_payment=0 / OK ✅
PARTIAL_WRITE_STATUS insufficient blocked: stock_still_23=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
CROSS_TENANT_GUARD_STATUS sale denied HTTP 403 / OK ✅
CROSS_TENANT_DB_STATUS cross_sale=0 / OK ✅
CROSS_TENANT_DB_STATUS tenant_b_stock_unchanged=1 / OK ✅
ROLLBACK_STATUS sale HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_sale=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_line=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_payment=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_stock_movement=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: stock_after_rollback=1 / OK ✅
ROUTE_SMOKE_STATUS /sale/ marker / OK ✅
FINAL_DB_STATUS tenant_sales=1 / OK ✅
FINAL_DB_STATUS tenant_sale_lines=1 / OK ✅
FINAL_DB_STATUS tenant_sale_payments=1 / OK ✅
FINAL_DB_STATUS tenant_sale_audit=1 / OK ✅
FINAL_DB_STATUS stock_after_all=23.000 / OK ✅
config semantic validation / OK ✅
```
