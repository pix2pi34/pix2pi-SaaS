# FAZ 7-R / 343 BILLING INVOICE / PAYMENT COLLECTION REAL FINAL AUDIT

- PASS_COUNT=70
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=billing-invoice-payment-343-20260513_231733
- TENANT_ID=tenant-api-e2e-success
- SOURCE_SUBSCRIPTION_ID=subscription-342-main-20260513_230101
- SOURCE_DRAFT_ID=invoice-draft-342-main-20260513_230101
- INVOICE_ID=invoice-343-main-20260513_231733
- COLLECTION_ID=collection-343-main-20260513_231733

## Latest 342 invoice draft
```
invoice-draft-342-main-20260513_230101|subscription-342-main-20260513_230101|billing-period-342-main-20260513_230101|pix2pi-starter|TRY|999.00|199.80|1198.80|active
```
## Readiness SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
tenant_b_owner_role=1
no_role_count=0
source_draft_ready=1
seed_drafts_ready=2
```
## Invoice issue response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "subscription_id": "subscription-342-main-20260513_230101", "billing_period_id": "billing-period-342-main-20260513_230101", "invoice_draft_id": "invoice-draft-342-main-20260513_230101", "invoice_id": "invoice-343-main-20260513_231733", "invoice_no": "INV-343-20260513_231733", "invoice_status": "issued", "currency": "TRY", "total_amount": 1198.8}
```
## Issue SELECT
```
invoice_issued=1
invoice_line_created=1
draft_marked_issued=1
invoice_issue_audit=1
```
## Duplicate response
```json
{"ok": true, "duplicate": true, "invoice_id": "invoice-343-main-20260513_231733", "invoice_status": "issued"}
```
## Duplicate SELECT
```
invoice_rows_for_draft=1
duplicate_invoice_new_row=0
```
## Payment start response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "invoice_id": "invoice-343-main-20260513_231733", "collection_id": "collection-343-main-20260513_231733", "collection_status": "pending", "amount": 1198.8, "currency": "TRY"}
```
## Payment SELECT
```
payment_collection_pending=1
payment_start_audit=1
```
## Collected response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "invoice_id": "invoice-343-main-20260513_231733", "collection_id": "collection-343-main-20260513_231733", "old_status": "pending", "new_status": "collected"}
```
## Collect SELECT
```
payment_collected=1
invoice_paid=1
payment_collected_audit=1
```
## Summary response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "invoice": {"invoice_id": "invoice-343-main-20260513_231733", "subscription_id": "subscription-342-main-20260513_230101", "billing_period_id": "billing-period-342-main-20260513_230101", "invoice_no": "INV-343-20260513_231733", "invoice_status": "paid", "currency": "TRY", "total_amount": "1198.80"}, "collections": [{"collection_id": "collection-343-main-20260513_231733", "payment_method": "manual_collection_placeholder", "collection_status": "collected", "amount": "1198.80"}]}
```
## Summary SELECT
```
billing_summary_audit=1
```
## Failed response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "invoice_id": "invoice-343-failed-20260513_231733", "collection_id": "collection-343-failed-20260513_231733", "old_status": "pending", "new_status": "failed"}
```
## Failed SELECT
```
failed_invoice_status=1
failed_collection_status=1
failed_flow_audits=3
```
## Cross response
```json
{"ok": false, "error": "invoice_draft_not_found"}
```
## Cross SELECT
```
tenant_b_invoice=0
tenant_safe_deny_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_invoice=0
no_role_audit=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_invoice=0
rollback_invoice_line=0
rollback_audit=0
rollback_draft_still_draft=1
```
## Final SELECT
```
final_invoice_paid=1
final_invoice_line=1
final_collection_collected=1
final_failed_collection=1
final_main_audits=4
final_failed_audits=3
final_negative_audits=1
final_no_rollback_invoice=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_342_SUBSCRIPTION_TENANT_BILLING_LIFECYCLE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_341_COMMERCIAL_PLAN_PACKAGE_RUNTIME_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_325_RECHECK_AFTER_332_POS_CHECKOUT_PAYMENT_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: commercial_runtime.billing_invoice_lines / OK ✅
table exists: commercial_runtime.billing_invoice_payment_audit_events / OK ✅
table exists: commercial_runtime.billing_invoices / OK ✅
table exists: commercial_runtime.billing_payment_collections / OK ✅
latest 342 invoice draft id detected / OK ✅
latest 342 subscription active / OK ✅
latest 342 invoice draft total detected / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx billing invoice/payment route bind / OK ✅
billing invoice issue route reaches API 422 / OK ✅
frontend billing invoice/payment page written / OK ✅
billing invoice/payment cleanup and seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
READINESS_STATUS source_draft_ready=1 / OK ✅
READINESS_STATUS seed_drafts_ready=2 / OK ✅
BILLING_INVOICE_ISSUE_STATUS HTTP 201 issued / OK ✅
REAL_DB_SELECT_STATUS invoice_issued=1 / OK ✅
REAL_DB_SELECT_STATUS invoice_line_created=1 / OK ✅
REAL_DB_SELECT_STATUS draft_marked_issued=1 / OK ✅
REAL_DB_SELECT_STATUS invoice_issue_audit=1 / OK ✅
INVOICE_ISSUE_IDEMPOTENCY_STATUS duplicate returned existing invoice / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: invoice_rows_for_draft=1 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_invoice_new_row=0 / OK ✅
PAYMENT_COLLECTION_START_STATUS HTTP 201 pending / OK ✅
REAL_DB_SELECT_STATUS payment_collection_pending=1 / OK ✅
REAL_DB_SELECT_STATUS payment_start_audit=1 / OK ✅
PAYMENT_COLLECTION_COLLECTED_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS payment_collected=1 / OK ✅
REAL_DB_SELECT_STATUS invoice_paid=1 / OK ✅
REAL_DB_SELECT_STATUS payment_collected_audit=1 / OK ✅
BILLING_SUMMARY_STATUS HTTP 200 paid/collected / OK ✅
REAL_DB_SELECT_STATUS billing_summary_audit=1 / OK ✅
PAYMENT_COLLECTION_FAILED_STATUS HTTP flow passed / OK ✅
REAL_DB_SELECT_STATUS failed_invoice_status=1 / OK ✅
REAL_DB_SELECT_STATUS failed_collection_status=1 / OK ✅
REAL_DB_SELECT_STATUS failed_flow_audits=3 / OK ✅
TENANT_SAFE_BILLING_STATUS tenant B cannot issue tenant A draft / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_invoice=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_safe_deny_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_invoice=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
ROLLBACK_STATUS invoice issue HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_invoice=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_invoice_line=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_draft_still_draft=1 / OK ✅
ROUTE_SMOKE_STATUS /commercial/billing/ marker / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_invoice_paid=1 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_invoice_line=1 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_collection_collected=1 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_failed_collection=1 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_main_audits=4 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_failed_audits=3 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_negative_audits=1 / OK ✅
FINAL_BILLING_INVOICE_PAYMENT_STATUS final_no_rollback_invoice=0 / OK ✅
config semantic validation / OK ✅
```
