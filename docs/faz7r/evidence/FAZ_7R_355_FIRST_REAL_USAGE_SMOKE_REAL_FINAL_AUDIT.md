# FAZ 7-R / 355 FIRST REAL USAGE SMOKE REAL FINAL AUDIT

- PASS_COUNT=72
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- SMOKE_RUN_ID=first-real-usage-355-20260513_193359
- PARTY_ID=party-355-customer-a
- PRODUCT_ID=product-355-main
- SALE_ID=sale-355-main

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
cashier_active=1
cashier_role=1
register_active=1
```
## Party create response
```json
{"ok": true, "party_id": "party-355-customer-a", "tenant_id": "tenant-api-e2e-success", "party_code": "CARI-355-001", "party_type": "customer", "current_balance": 0.0}
```
## Party SELECT
```
party_created=1
party_movement=1
```
## Product create response
```json
{"ok": true, "product_id": "product-355-main", "tenant_id": "tenant-api-e2e-success", "product_code": "PRD-355-001", "barcode": "8690000000355", "sku": "SKU-355-MAIN", "stock_quantity": 10.0, "sale_price": 100.0, "vat_rate": 20.0}
```
## Product SELECT
```
product_created=1
product_category=1
opening_stock=1
```
## Stock response
```json
{"ok": true, "movement_id": "stock-movement-ca5766a0-f64e-4143-9d6d-61d35cace235", "product_id": "product-355-main", "tenant_id": "tenant-api-e2e-success", "stock_after": 15.0}
```
## Stock SELECT
```
stock_after_in=1
stock_in_movement=1
```
## POS sale response
```json
{"ok": true, "sale_id": "sale-355-main", "tenant_id": "tenant-api-e2e-success", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "cashier_user_id": "user-321-cashier", "sale_status": "completed", "payment_status": "paid", "subtotal_amount": 300.0, "discount_amount": 15.0, "vat_amount": 57.0, "total_amount": 342.0, "line_count": 1}
```
## Sale SELECT
```
sale_completed=1
sale_line=1
sale_payment=1
stock_after_sale=1
pos_sale_stock_movement=1
```
## Dashboard response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "sale_count": 2, "subtotal_amount": "349.80", "discount_amount": "20.00", "vat_amount": "61.48", "total_amount": "391.28"}
```
## Dashboard SELECT
```
dashboard_sale_count=1
dashboard_sale_total=1
dashboard_stock_after=1
dashboard_metric_count=4
```
## Report SELECT
```
daily_sales_report=1
product_sales_report=1
vat_report=1
stock_report=1
report_count=4
```
## Smoke SELECT
```
smoke_run=first-real-usage-355-20260513_193359|pass|party-355-customer-a|product-355-main|sale-355-main|true|true|true
smoke_events=6
smoke_event_fail=0
```
## Rollback SELECT
```
rollback_event=0
```
## Final SELECT
```
final_party=1
final_product=1
final_stock=12.000
final_sale=1
final_payment=1
final_dashboard=4
final_reports=4
final_smoke_run=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_325_SALES_POS_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: customer_smoke.first_usage_dashboard_snapshots / OK ✅
table exists: customer_smoke.first_usage_report_snapshots / OK ✅
table exists: customer_smoke.first_usage_smoke_events / OK ✅
table exists: customer_smoke.first_usage_smoke_runs / OK ✅
323 party API health / OK ✅
324 product stock API health / OK ✅
331 POS sale API health / OK ✅
325 sales management API health / OK ✅
nginx smoke route bind / OK ✅
first real usage smoke page written / OK ✅
test cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS cashier_active=1 / OK ✅
READINESS_STATUS cashier_role=1 / OK ✅
READINESS_STATUS register_active=1 / OK ✅
SMOKE_PARTY_CREATE_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS party_created=1 / OK ✅
REAL_DB_SELECT_STATUS party_movement=1 / OK ✅
SMOKE_PRODUCT_CREATE_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS product_created=1 / OK ✅
REAL_DB_SELECT_STATUS product_category=1 / OK ✅
REAL_DB_SELECT_STATUS opening_stock=1 / OK ✅
SMOKE_STOCK_IN_STATUS HTTP 201 stock_after 15 / OK ✅
REAL_DB_SELECT_STATUS stock_after_in=1 / OK ✅
REAL_DB_SELECT_STATUS stock_in_movement=1 / OK ✅
SMOKE_POS_SALE_STATUS HTTP 201 total 342 / OK ✅
REAL_DB_SELECT_STATUS sale_completed=1 / OK ✅
REAL_DB_SELECT_STATUS sale_line=1 / OK ✅
REAL_DB_SELECT_STATUS sale_payment=1 / OK ✅
REAL_DB_SELECT_STATUS stock_after_sale=1 / OK ✅
REAL_DB_SELECT_STATUS pos_sale_stock_movement=1 / OK ✅
DASHBOARD_API_STATUS day-summary HTTP 200 / OK ✅
dashboard snapshots inserted / OK ✅
DASHBOARD_VISIBLE_STATUS dashboard_sale_count=1 / OK ✅
DASHBOARD_VISIBLE_STATUS dashboard_sale_total=1 / OK ✅
DASHBOARD_VISIBLE_STATUS dashboard_stock_after=1 / OK ✅
DASHBOARD_VISIBLE_STATUS dashboard_metric_count=4 / OK ✅
report snapshots inserted / OK ✅
REPORT_GENERATION_STATUS daily_sales_report=1 / OK ✅
REPORT_GENERATION_STATUS product_sales_report=1 / OK ✅
REPORT_GENERATION_STATUS vat_report=1 / OK ✅
REPORT_GENERATION_STATUS stock_report=1 / OK ✅
REPORT_GENERATION_STATUS report_count=4 / OK ✅
SMOKE_AUDIT_DB_WRITE_STATUS smoke run/events inserted / OK ✅
REAL_DB_SELECT_STATUS smoke_run pass / OK ✅
REAL_DB_SELECT_STATUS smoke_events=6 / OK ✅
REAL_DB_SELECT_STATUS smoke_event_fail=0 / OK ✅
ROLLBACK_STATUS simulated DB failure occurred / OK ✅
TRANSACTION_STATUS rollback no partial write / OK ✅
ROUTE_SMOKE_STATUS /first-real-usage-smoke/ marker / OK ✅
FINAL_REAL_USAGE_STATUS final_party=1 / OK ✅
FINAL_REAL_USAGE_STATUS final_product=1 / OK ✅
FINAL_REAL_USAGE_STATUS final_stock=12.000 / OK ✅
FINAL_REAL_USAGE_STATUS final_sale=1 / OK ✅
FINAL_REAL_USAGE_STATUS final_payment=1 / OK ✅
FINAL_REAL_USAGE_STATUS final_dashboard=4 / OK ✅
FINAL_REAL_USAGE_STATUS final_reports=4 / OK ✅
FINAL_REAL_USAGE_STATUS final_smoke_run=1 / OK ✅
config semantic validation / OK ✅
```
