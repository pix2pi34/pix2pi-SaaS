# FAZ 7-R / 320 MERCHANT DASHBOARD REAL FINAL AUDIT

- PASS_COUNT=57
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- DASHBOARD_RUN_ID=merchant-dashboard-320-20260513_193959

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
smoke_sale=1
smoke_party=1
smoke_product=1
no_role_count=0
```
## Snapshot response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "dashboard_run_id": "merchant-dashboard-320-20260513_193959", "metrics": {"daily_sales_count": 2.0, "daily_sales_total": 391.28, "daily_vat_total": 61.48, "paid_collection_total": 391.28, "sale_line_count": 2.0, "customer_count": 2.0, "party_balance_total": 1500.0, "product_count": 3.0, "low_stock_count": 1.0, "stock_quantity_total": 38.0, "subscription_plan": "pilot-free-controlled", "default_language": "tr-TR", "tenant_status": "opened", "panel_enabled": true, "pos_enabled": true, "marketplace_enabled": false, "access_mode": "controlled_pilot", "access_status": "active"}, "quick_actions": [["quick-party-create", "/parties/"], ["quick-product-create", "/products/"], ["quick-pos-sale", "https://pos.pix2pi.com.tr/sale/"], ["quick-sales-management", "/pos-sales-management/"], ["quick-reports", "/reports/"], ["quick-settings", "/settings/"]]}
```
## Dashboard SELECT
```
dashboard_run=1
metric_daily_sales_count=1
metric_daily_sales_total=1
metric_collection_total=1
metric_customer_count=1
metric_product_count=1
metric_marketplace_status=1
metric_subscription_plan=1
quick_actions=6
dashboard_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_run=0
```
## Cross tenant response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-isolated-b", "dashboard_run_id": "merchant-dashboard-320-cross", "metrics": {"daily_sales_count": 0.0, "daily_sales_total": 0.0, "daily_vat_total": 0.0, "paid_collection_total": 0.0, "sale_line_count": 0.0, "customer_count": 1.0, "party_balance_total": 10.0, "product_count": 1.0, "low_stock_count": 0.0, "stock_quantity_total": 9.0, "subscription_plan": "pilot-free-controlled", "default_language": "tr-TR", "tenant_status": "opened", "panel_enabled": false, "pos_enabled": false, "marketplace_enabled": false, "access_mode": "unknown", "access_status": "inactive"}, "quick_actions": [["quick-party-create", "/parties/"], ["quick-product-create", "/products/"], ["quick-pos-sale", "https://pos.pix2pi.com.tr/sale/"], ["quick-sales-management", "/pos-sales-management/"], ["quick-reports", "/reports/"], ["quick-settings", "/settings/"]]}
```
## Cross tenant SELECT
```
cross_run=1
cross_sales_total_zero=1
cross_no_tenant_a_sale=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_run=0
rollback_metrics=0
rollback_actions=0
rollback_audit=0
```
## Final SELECT
```
final_dashboard_runs=1
final_metrics=16
final_quick_actions=6
final_audit=1
final_daily_total=1
final_collection_total=1
final_marketplace_false=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_355_FIRST_REAL_USAGE_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_325_SALES_POS_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: merchant_dashboard.dashboard_audit_events / OK ✅
table exists: merchant_dashboard.dashboard_metric_snapshots / OK ✅
table exists: merchant_dashboard.dashboard_quick_actions / OK ✅
table exists: merchant_dashboard.dashboard_runs / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx dashboard route bind / OK ✅
dashboard snapshot route reaches API 422 / OK ✅
frontend dashboard page written / OK ✅
dashboard cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS smoke_sale=1 / OK ✅
READINESS_STATUS smoke_party=1 / OK ✅
READINESS_STATUS smoke_product=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
DASHBOARD_SNAPSHOT_STATUS HTTP 201 real metrics / OK ✅
REAL_DB_SELECT_STATUS dashboard_run=1 / OK ✅
REAL_DB_SELECT_STATUS metric_daily_sales_count=1 / OK ✅
REAL_DB_SELECT_STATUS metric_daily_sales_total=1 / OK ✅
REAL_DB_SELECT_STATUS metric_collection_total=1 / OK ✅
REAL_DB_SELECT_STATUS metric_customer_count=1 / OK ✅
REAL_DB_SELECT_STATUS metric_product_count=1 / OK ✅
REAL_DB_SELECT_STATUS metric_marketplace_status=1 / OK ✅
REAL_DB_SELECT_STATUS metric_subscription_plan=1 / OK ✅
REAL_DB_SELECT_STATUS quick_actions=6 / OK ✅
REAL_DB_SELECT_STATUS dashboard_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_run=0 / OK ✅
CROSS_TENANT_OWN_DASHBOARD_STATUS tenant B own dashboard HTTP 201 / OK ✅
CROSS_TENANT_DB_STATUS cross_run=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_sales_total_zero=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_no_tenant_a_sale=0 / OK ✅
ROLLBACK_STATUS dashboard snapshot HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_run=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_metrics=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_actions=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /dashboard/ marker / OK ✅
FINAL_DASHBOARD_STATUS final_dashboard_runs=1 / OK ✅
FINAL_DASHBOARD_STATUS final_quick_actions=6 / OK ✅
FINAL_DASHBOARD_STATUS final_audit=1 / OK ✅
FINAL_DASHBOARD_STATUS final_daily_total=1 / OK ✅
FINAL_DASHBOARD_STATUS final_collection_total=1 / OK ✅
FINAL_DASHBOARD_STATUS final_marketplace_false=1 / OK ✅
FINAL_DASHBOARD_STATUS final_metrics >= 10 / OK ✅
config semantic validation / OK ✅
```
