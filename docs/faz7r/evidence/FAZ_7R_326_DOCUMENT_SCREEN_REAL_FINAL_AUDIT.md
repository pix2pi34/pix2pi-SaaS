# FAZ 7-R / 326 DOCUMENT SCREEN REAL FINAL AUDIT

- PASS_COUNT=70
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- DOCUMENT_RUN_ID=document-326-20260513_195222
- DOCUMENT_ID=document-326-main

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
source_sale=1
source_line=1
source_payment=1
no_role_count=0
```
## Create response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "document_run_id": "document-326-20260513_195222", "document_id": "document-326-main", "source_sale_id": "sale-355-main", "document_no": "DOC-326-001", "document_status": "draft", "total_amount": 342.0, "pdf_placeholder": "/documents/tenant-api-e2e-success/DOC-326-001.pdf", "ubl_placeholder": "/documents/tenant-api-e2e-success/DOC-326-001.xml", "next_url": "/documents/?document_id=document-326-main"}
```
## Create SELECT
```
document_created=1
document_line=1
document_artifacts=2
document_pdf_placeholder=1
document_ubl_placeholder=1
document_status_event=1
document_audit=1
```
## List response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"document_id": "document-326-main", "source_sale_id": "sale-355-main", "document_no": "DOC-326-001", "document_type": "sales_receipt", "document_status": "draft", "total_amount": "342.00", "issued_at": ""}]}
```
## Detail response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "document": {"document_id": "document-326-main", "source_sale_id": "sale-355-main", "document_no": "DOC-326-001", "document_type": "sales_receipt", "document_status": "draft", "subtotal_amount": "300.00", "discount_amount": "15.00", "vat_amount": "57.00", "total_amount": "342.00"}, "lines": [{"product_id": "product-355-main", "product_name": "355 Smoke Ürün", "barcode": "8690000000355", "sku": "SKU-355-MAIN", "quantity": "3.000", "unit_price": "100.00", "discount_amount": "15.00", "vat_rate": "20.00", "vat_amount": "57.00", "line_total": "342.00"}], "artifacts": [{"artifact_type": "pdf", "artifact_status": "placeholder", "artifact_path": "/documents/tenant-api-e2e-success/DOC-326-001.pdf", "checksum": "placeholder-checksum-pdf"}, {"artifact_type": "ubl", "artifact_status": "placeholder", "artifact_path": "/documents/tenant-api-e2e-success/DOC-326-001.xml", "checksum": "placeholder-checksum-ubl"}], "status_events": [{"old_status": "", "new_status": "draft", "event_reason": "created_from_paid_pos_sale"}]}
```
## Status response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "document_id": "document-326-main", "old_status": "draft", "new_status": "issued"}
```
## Status SELECT
```
document_issued=1
status_event_issued=1
status_audit=1
```
## Preview response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "preview_id": "document-preview-326-main", "document_id": "document-326-main", "document_status": "issued", "retry_allowed": false, "cancel_allowed": true}
```
## Preview SELECT
```
retry_cancel_preview=1
preview_audit=1
```
## Duplicate response
```json
{"ok": false, "error": "duplicate_document", "detail": "ERROR:  duplicate key value violates unique constraint \"sales_documents_tenant_id_source_sale_id_key\"\nDETAIL:  Key (tenant_id, source_sale_id)=(tenant-api-e2e-success, sale-355-main) already exists.\n"}
```
## Duplicate SELECT
```
duplicate_document=0
duplicate_lines=0
duplicate_artifacts=0
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
rollback_document=0
rollback_lines=0
rollback_artifacts=0
rollback_status_events=0
rollback_audit=0
```
## Final SELECT
```
final_document=1
final_lines=1
final_artifacts=2
final_status_events=2
final_preview=1
final_audit=3
```
## Check log
```
dependency PASS evidence: FAZ_7R_322_BUSINESS_SETTINGS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_325_SALES_POS_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_327_REPORTS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: erp_document.document_artifacts / OK ✅
table exists: erp_document.document_audit_events / OK ✅
table exists: erp_document.document_retry_cancel_previews / OK ✅
table exists: erp_document.document_status_events / OK ✅
table exists: erp_document.sales_document_lines / OK ✅
table exists: erp_document.sales_documents / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx document route bind / OK ✅
document create route reaches API 422 / OK ✅
frontend documents page written / OK ✅
document cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS source_sale=1 / OK ✅
READINESS_STATUS source_line=1 / OK ✅
READINESS_STATUS source_payment=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
DOCUMENT_CREATE_STATUS HTTP 201 from sale / OK ✅
REAL_DB_SELECT_STATUS document_created=1 / OK ✅
REAL_DB_SELECT_STATUS document_line=1 / OK ✅
REAL_DB_SELECT_STATUS document_artifacts=2 / OK ✅
REAL_DB_SELECT_STATUS document_pdf_placeholder=1 / OK ✅
REAL_DB_SELECT_STATUS document_ubl_placeholder=1 / OK ✅
REAL_DB_SELECT_STATUS document_status_event=1 / OK ✅
REAL_DB_SELECT_STATUS document_audit=1 / OK ✅
DOCUMENT_LIST_STATUS HTTP 200 document listed / OK ✅
DOCUMENT_DETAIL_STATUS HTTP 200 detail/artifacts/status events / OK ✅
DOCUMENT_STATUS_UPDATE_STATUS issued HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS document_issued=1 / OK ✅
REAL_DB_SELECT_STATUS status_event_issued=1 / OK ✅
REAL_DB_SELECT_STATUS status_audit=1 / OK ✅
DOCUMENT_RETRY_CANCEL_PREVIEW_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS retry_cancel_preview=1 / OK ✅
REAL_DB_SELECT_STATUS preview_audit=1 / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_document=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_lines=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_artifacts=0 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
CROSS_TENANT_GUARD_STATUS detail denied HTTP 403 / OK ✅
CROSS_TENANT_DB_STATUS cross_deny_audit=1 / OK ✅
rollback source sale seeded / OK ✅
ROLLBACK_SOURCE_STATUS rollback_source_sale=1 / OK ✅
ROLLBACK_SOURCE_STATUS rollback_source_line=1 / OK ✅
ROLLBACK_SOURCE_STATUS rollback_source_payment=1 / OK ✅
ROLLBACK_STATUS document create HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_document=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_lines=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_artifacts=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_status_events=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /documents/ marker / OK ✅
FINAL_DOCUMENT_STATUS final_document=1 / OK ✅
FINAL_DOCUMENT_STATUS final_lines=1 / OK ✅
FINAL_DOCUMENT_STATUS final_artifacts=2 / OK ✅
FINAL_DOCUMENT_STATUS final_status_events=2 / OK ✅
FINAL_DOCUMENT_STATUS final_preview=1 / OK ✅
FINAL_DOCUMENT_STATUS final_audit >= 3 / OK ✅
config semantic validation / OK ✅
```
