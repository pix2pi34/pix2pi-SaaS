# FAZ 7-R / 327 REPORTS REAL FINAL AUDIT

- PASS_COUNT=61
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- REPORT_RUN_ID=reports-327-20260513_194400

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
smoke_sale=1
smoke_product_line=1
smoke_party=1
no_role_count=0
```
## Report generation response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "report_run_id": "reports-327-20260513_194400", "reports": {"daily_sales_report": {"row_count": 2, "total": 391.28, "vat": 61.48}, "product_sales_report": {"row_count": 2, "total": 391.28, "quantity": 5.0}, "stock_report": {"row_count": 3, "total": 38.0, "low_stock_count": 1}, "party_balance_report": {"row_count": 3, "total": 1500.0}, "vat_report": {"row_count": 2, "total": 61.48}, "marketplace_report": {"row_count": 1, "status": "disabled"}, "subscription_usage_report": {"row_count": 1, "plan": "pilot-free-controlled", "tenant_status": "opened", "language": "tr-TR"}}}
```
## Report SELECT
```
report_run=1
daily_sales_report=1
product_sales_report=1
stock_report=1
party_balance_report=1
vat_report=1
marketplace_report=1
subscription_usage_report=1
report_rows=8
report_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_run=0
no_role_snapshots=0
```
## Cross tenant response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-isolated-b", "report_run_id": "reports-327-cross", "reports": {"daily_sales_report": {"row_count": 0, "total": 0.0, "vat": 0.0}, "product_sales_report": {"row_count": 0, "total": 0.0, "quantity": 0.0}, "stock_report": {"row_count": 1, "total": 9.0, "low_stock_count": 0}, "party_balance_report": {"row_count": 1, "total": 10.0}, "vat_report": {"row_count": 0, "total": 0.0}, "marketplace_report": {"row_count": 0, "status": "disabled"}, "subscription_usage_report": {"row_count": 1, "plan": "pilot-free-controlled", "tenant_status": "opened", "language": "tr-TR"}}}
```
## Cross tenant SELECT
```
cross_run=1
cross_daily_zero=1
cross_no_tenant_a_sales=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_run=0
rollback_snapshots=0
rollback_rows=0
rollback_audit=0
```
## Final SELECT
```
final_report_run=1
final_snapshots=7
final_rows=8
final_audit=1
final_daily_sales=1
final_product_sales=1
final_vat=1
final_marketplace=1
final_subscription=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_320_MERCHANT_DASHBOARD_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_355_FIRST_REAL_USAGE_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_325_SALES_POS_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: merchant_reports.report_audit_events / OK ✅
table exists: merchant_reports.report_rows / OK ✅
table exists: merchant_reports.report_runs / OK ✅
table exists: merchant_reports.report_snapshots / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx reports route bind / OK ✅
reports generate route reaches API 422 / OK ✅
frontend reports page written / OK ✅
reports cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS smoke_sale=1 / OK ✅
READINESS_STATUS smoke_product_line=1 / OK ✅
READINESS_STATUS smoke_party=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
REPORT_GENERATION_STATUS HTTP 201 all reports / OK ✅
REAL_DB_SELECT_STATUS report_run=1 / OK ✅
REAL_DB_SELECT_STATUS daily_sales_report=1 / OK ✅
REAL_DB_SELECT_STATUS product_sales_report=1 / OK ✅
REAL_DB_SELECT_STATUS stock_report=1 / OK ✅
REAL_DB_SELECT_STATUS party_balance_report=1 / OK ✅
REAL_DB_SELECT_STATUS vat_report=1 / OK ✅
REAL_DB_SELECT_STATUS marketplace_report=1 / OK ✅
REAL_DB_SELECT_STATUS subscription_usage_report=1 / OK ✅
REAL_DB_SELECT_STATUS report_audit=1 / OK ✅
REAL_DB_SELECT_STATUS report_rows >= 3 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_run=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_snapshots=0 / OK ✅
CROSS_TENANT_OWN_REPORT_STATUS tenant B own report HTTP 201 / OK ✅
CROSS_TENANT_DB_STATUS cross_run=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_daily_zero=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_no_tenant_a_sales=0 / OK ✅
ROLLBACK_STATUS reports generate HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_run=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_snapshots=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_rows=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /reports/ marker / OK ✅
FINAL_REPORT_STATUS final_report_run=1 / OK ✅
FINAL_REPORT_STATUS final_snapshots=7 / OK ✅
FINAL_REPORT_STATUS final_audit=1 / OK ✅
FINAL_REPORT_STATUS final_daily_sales=1 / OK ✅
FINAL_REPORT_STATUS final_product_sales=1 / OK ✅
FINAL_REPORT_STATUS final_vat=1 / OK ✅
FINAL_REPORT_STATUS final_marketplace=1 / OK ✅
FINAL_REPORT_STATUS final_subscription=1 / OK ✅
FINAL_REPORT_STATUS final_rows >= 3 / OK ✅
config semantic validation / OK ✅
```
