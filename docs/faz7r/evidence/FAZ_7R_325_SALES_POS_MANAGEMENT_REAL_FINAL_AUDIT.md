# FAZ 7-R / 325 SALES POS MANAGEMENT REAL FINAL AUDIT

- PASS_COUNT=48
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
cashier_active=1
cashier_role=1
source_sale=1
source_line=1
source_payment=1
no_role_count=0
```
## Sales list response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"sale_id": "sale-331-main", "sale_no": "POS-331-001", "cashier_user_id": "user-321-cashier", "register_id": "tenant-api-e2e-success-register-main", "sale_status": "completed", "payment_status": "paid", "total_amount": "49.28", "completed_at": "2026-05-13 05:30:09.673858+00"}]}
```
## Sales detail response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "sale": {"sale_id": "sale-331-main", "sale_no": "POS-331-001", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "cashier_user_id": "user-321-cashier", "sale_status": "completed", "payment_status": "paid", "subtotal_amount": "49.80", "discount_amount": "5.00", "vat_amount": "4.48", "total_amount": "49.28"}, "lines": [{"product_id": "product-324-main", "product_name": "324 Test Ürün Güncel", "barcode": "8690000000324", "sku": "SKU-323-324-001", "quantity": "2.000", "unit_price": "24.90", "discount_amount": "5.00", "vat_rate": "10.00", "vat_amount": "4.48", "line_total": "49.28", "stock_after": "23.000"}], "payments": [{"payment_id": "payment-50f423bb-3366-46d7-ae8d-e39c6ee7262f", "payment_method": "cash", "amount": "49.28", "payment_status": "paid", "provider_ref": "manual-pos"}]}
```
## Cashier list response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"sale_id": "sale-331-main", "sale_no": "POS-331-001", "cashier_user_id": "user-321-cashier", "register_id": "tenant-api-e2e-success-register-main", "sale_status": "completed", "payment_status": "paid", "total_amount": "49.28", "completed_at": "2026-05-13 05:30:09.673858+00"}]}
```
## Day summary response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "sale_count": 1, "subtotal_amount": "49.80", "discount_amount": "5.00", "vat_amount": "4.48", "total_amount": "49.28"}
```
## Refund preview response
```json
{"ok": true, "preview_id": "refund-preview-325-main", "tenant_id": "tenant-api-e2e-success", "sale_id": "sale-331-main", "sale_status": "completed", "payment_status": "paid", "refund_allowed": true, "cancel_allowed": false, "refund_amount": 49.28}
```
## Refund SELECT
```
refund_preview=1
refund_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## Cross tenant response
```json
{"ok": false, "error": "cross_tenant_denied"}
```
## Cross SELECT
```
cross_deny_audit=1
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_preview=0
rollback_audit=0
```
## Final SELECT
```
sales_total=1
refund_previews=1
management_audit=5
sale_total_amount=49.28
sale_payment_status=paid
```
## Check log
```
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: pos_sales.sale_audit_events / OK ✅
table exists: pos_sales.sale_lines / OK ✅
table exists: pos_sales.sale_management_audit_events / OK ✅
table exists: pos_sales.sale_payments / OK ✅
table exists: pos_sales.sale_refund_previews / OK ✅
table exists: pos_sales.sales / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
sales-list route reaches API 422 / OK ✅
frontend POS sales management page written / OK ✅
management cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS cashier_active=1 / OK ✅
READINESS_STATUS cashier_role=1 / OK ✅
READINESS_STATUS source_sale=1 / OK ✅
READINESS_STATUS source_line=1 / OK ✅
READINESS_STATUS source_payment=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
SALES_LIST_STATUS HTTP 200 source sale listed / OK ✅
SALES_DETAIL_STATUS HTTP 200 detail/payment paid / OK ✅
CASHIER_SALES_STATUS cashier filter found sale / OK ✅
DAY_SUMMARY_STATUS sale_count total VAT / OK ✅
REFUND_PREVIEW_STATUS HTTP 201 refund_allowed cancel_false / OK ✅
REAL_DB_SELECT_STATUS refund_preview=1 / OK ✅
REAL_DB_SELECT_STATUS refund_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
CROSS_TENANT_GUARD_STATUS detail denied HTTP 403 / OK ✅
CROSS_TENANT_DB_STATUS cross_deny_audit=1 / OK ✅
ROLLBACK_STATUS refund preview HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_preview=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /pos-sales-management/ marker / OK ✅
FINAL_DB_STATUS sales_total=1 / OK ✅
FINAL_DB_STATUS refund_previews=1 / OK ✅
FINAL_DB_STATUS management_audit >= 2 / OK ✅
FINAL_DB_STATUS sale_total_amount=49.28 / OK ✅
FINAL_DB_STATUS sale_payment_status=paid / OK ✅
config semantic validation / OK ✅
```
