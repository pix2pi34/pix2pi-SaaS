# FAZ 7-R / 328 IMPORT EXPORT REAL FINAL AUDIT

- PASS_COUNT=79
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- IMPORT_PARTY_JOB_ID=import-party-328-20260513_200035
- IMPORT_PRODUCT_JOB_ID=import-product-328-20260513_200035
- IMPORT_STOCK_JOB_ID=import-stock-328-20260513_200035
- EXPORT_JOB_ID=export-sales-docs-328-20260513_200035

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
source_sale=1
source_document=1
no_role_count=0
```
## Party import response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "import_job_id": "import-party-328-20260513_200035", "import_type": "party", "row_count": 1, "success_count": 1}
```
## Party import SELECT
```
party_import_job=1
party_import_row=1
party_imported=1
party_import_audit=1
```
## Product import response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "import_job_id": "import-product-328-20260513_200035", "import_type": "product", "row_count": 1, "success_count": 1}
```
## Product import SELECT
```
product_import_job=1
product_import_row=1
product_imported=1
product_category_imported=1
product_import_stock_movement=1
product_import_audit=1
```
## Stock import response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "import_job_id": "import-stock-328-20260513_200035", "import_type": "stock", "row_count": 1, "success_count": 1}
```
## Stock import SELECT
```
stock_import_job=1
stock_import_row=1
product_stock_after_import=1
stock_import_movement=1
stock_import_audit=1
```
## Export response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "export_job_id": "export-sales-docs-328-20260513_200035", "export_type": "sales_documents", "row_count": 4, "total_amount": 853.28, "csv_placeholder": "/exports/tenant-api-e2e-success/export-sales-docs-328-20260513_200035.csv", "xlsx_placeholder": "/exports/tenant-api-e2e-success/export-sales-docs-328-20260513_200035.xlsx"}
```
## Export SELECT
```
export_job=1
export_csv=1
export_xlsx=1
export_artifacts=2
export_audit=1
```
## Invalid response
```json
{"ok": false, "error": "validation_error", "fields": {"file_type": "unsupported_file_type"}}
```
## Invalid SELECT
```
invalid_import_job=0
invalid_import_rows=0
invalid_import_audit=0
```
## Duplicate response
```json
{"ok": false, "error": "duplicate_party_tax_identity"}
```
## Duplicate SELECT
```
duplicate_party=0
duplicate_job=0
duplicate_rows=0
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_export_job=0
no_role_artifacts=0
```
## Cross tenant response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-isolated-b", "export_job_id": "export-328-cross", "export_type": "sales_documents", "row_count": 0, "total_amount": 0.0, "csv_placeholder": "/exports/tenant-api-e2e-isolated-b/export-328-cross.csv", "xlsx_placeholder": "/exports/tenant-api-e2e-isolated-b/export-328-cross.xlsx"}
```
## Cross SELECT
```
cross_export_job=1
cross_export_zero_or_own=1
cross_no_tenant_a_amount=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_party=0
rollback_job=0
rollback_rows=0
rollback_audit=0
```
## Final SELECT
```
final_party=1
final_product=1
final_product_stock=10.000
final_import_jobs=3
final_import_rows=3
final_export_job=1
final_export_artifacts=2
final_audit=4
```
## Check log
```
dependency PASS evidence: FAZ_7R_323_CARI_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_326_DOCUMENT_SCREEN_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_327_REPORTS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: merchant_import_export.export_artifacts / OK ✅
table exists: merchant_import_export.export_jobs / OK ✅
table exists: merchant_import_export.import_export_audit_events / OK ✅
table exists: merchant_import_export.import_job_rows / OK ✅
table exists: merchant_import_export.import_jobs / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx import/export route bind / OK ✅
import parties route reaches API 422 / OK ✅
frontend import/export page written / OK ✅
import/export cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS source_sale=1 / OK ✅
READINESS_STATUS source_document=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
PARTY_IMPORT_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS party_import_job=1 / OK ✅
REAL_DB_SELECT_STATUS party_import_row=1 / OK ✅
REAL_DB_SELECT_STATUS party_imported=1 / OK ✅
REAL_DB_SELECT_STATUS party_import_audit=1 / OK ✅
PRODUCT_IMPORT_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS product_import_job=1 / OK ✅
REAL_DB_SELECT_STATUS product_import_row=1 / OK ✅
REAL_DB_SELECT_STATUS product_imported=1 / OK ✅
REAL_DB_SELECT_STATUS product_category_imported=1 / OK ✅
REAL_DB_SELECT_STATUS product_import_stock_movement=1 / OK ✅
REAL_DB_SELECT_STATUS product_import_audit=1 / OK ✅
STOCK_IMPORT_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS stock_import_job=1 / OK ✅
REAL_DB_SELECT_STATUS stock_import_row=1 / OK ✅
REAL_DB_SELECT_STATUS product_stock_after_import=1 / OK ✅
REAL_DB_SELECT_STATUS stock_import_movement=1 / OK ✅
REAL_DB_SELECT_STATUS stock_import_audit=1 / OK ✅
EXPORT_STATUS HTTP 201 csv/xlsx placeholders / OK ✅
REAL_DB_SELECT_STATUS export_job=1 / OK ✅
REAL_DB_SELECT_STATUS export_csv=1 / OK ✅
REAL_DB_SELECT_STATUS export_xlsx=1 / OK ✅
REAL_DB_SELECT_STATUS export_artifacts=2 / OK ✅
REAL_DB_SELECT_STATUS export_audit=1 / OK ✅
IMPORT_VALIDATION_STATUS HTTP 422 / OK ✅
PARTIAL_WRITE_STATUS invalid blocked: invalid_import_job=0 / OK ✅
PARTIAL_WRITE_STATUS invalid blocked: invalid_import_rows=0 / OK ✅
PARTIAL_WRITE_STATUS invalid blocked: invalid_import_audit=0 / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_party=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_job=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_rows=0 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_export_job=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_artifacts=0 / OK ✅
CROSS_TENANT_EXPORT_STATUS tenant B own export HTTP 201 / OK ✅
CROSS_TENANT_DB_STATUS cross_export_job=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_export_zero_or_own=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_no_tenant_a_amount=0 / OK ✅
ROLLBACK_STATUS import parties HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_party=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_job=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_rows=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /import-export/ marker / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_party=1 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_product=1 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_product_stock=10.000 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_import_jobs=3 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_import_rows=3 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_export_job=1 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_export_artifacts=2 / OK ✅
FINAL_IMPORT_EXPORT_STATUS final_audit=4 / OK ✅
config semantic validation / OK ✅
```
