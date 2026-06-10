# FAZ 7-R / 333 OFFLINE POS REAL FINAL AUDIT

- PASS_COUNT=72
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- OFFLINE_QUEUE_ID=offline-queue-333-20260513_202008
- SYNC_SALE_ID=sale-333-sync-20260513_202008

## Readiness SELECT
```
tenant_opened=1
cashier_active=1
cashier_role=1
register_active=1
product_ready=1
no_role_count=0
```
## Queue response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "offline_queue_id": "offline-queue-333-20260513_202008", "offline_sale_id": "offline-sale-333-20260513_202008", "queue_status": "queued", "subtotal_amount": 200.0, "discount_amount": 10.0, "vat_amount": 38.0, "total_amount": 228.0}
```
## Queue SELECT
```
offline_queue=1
offline_lines=1
offline_payment_placeholder=1
offline_queue_audit=1
```
## Duplicate response
```json
{"ok": true, "duplicate": true, "offline_queue_id": "offline-queue-333-20260513_202008", "queue_status": "queued"}
```
## Duplicate SELECT
```
duplicate_queue_rows=1
duplicate_new_queue=0
```
## Sync response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "offline_queue_id": "offline-queue-333-20260513_202008", "queue_status": "synced", "sync_sale_id": "sale-333-sync-20260513_202008", "total_amount": 228.0}
```
## Sync SELECT
```
queue_synced=1
sync_attempt=1
synced_sale=1
synced_sale_line=1
synced_payment=1
offline_payment_synced=1
stock_after_sync=1
offline_sync_stock_movement=1
sync_audit=1
```
## Sync duplicate response
```json
{"ok": true, "duplicate": true, "offline_queue_id": "offline-queue-333-20260513_202008", "queue_status": "synced", "sync_sale_id": "sale-333-sync-20260513_202008"}
```
## Conflict response
```json
{"ok": false, "error": "stock_conflict", "product_id": "product-355-main", "stock_quantity": 10.0, "requested_quantity": 999.0}
```
## Conflict SELECT
```
conflict_queue=1
conflict_attempt=1
conflict_no_sale=0
conflict_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## Cross tenant response
```json
{"ok": false, "error": "cashier_user_not_active"}
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_queue=0
rollback_lines=0
rollback_payment=0
rollback_audit=0
```
## Status response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "offline_queue_id": "offline-queue-333-20260513_202008", "queue_status": "synced", "sync_sale_id": "sale-333-sync-20260513_202008", "total_amount": 228.0}
```
## Final SELECT
```
final_queue_synced=1
final_offline_lines=1
final_payment_synced=1
final_sync_attempt=1
final_synced_sale=1
final_stock_movement=1
final_conflict_queue=1
final_audit=4
```
## Check log
```
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_325_SALES_POS_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_328_IMPORT_EXPORT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: offline_pos.offline_payment_placeholders / OK ✅
table exists: offline_pos.offline_pos_audit_events / OK ✅
table exists: offline_pos.offline_sale_lines / OK ✅
table exists: offline_pos.offline_sales_queue / OK ✅
table exists: offline_pos.offline_sync_attempts / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx offline POS route bind / OK ✅
offline queue route reaches API 422 / OK ✅
frontend offline POS page written / OK ✅
offline POS cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS cashier_active=1 / OK ✅
READINESS_STATUS cashier_role=1 / OK ✅
READINESS_STATUS register_active=1 / OK ✅
READINESS_STATUS product_ready=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
OFFLINE_QUEUE_STATUS HTTP 201 queued / OK ✅
REAL_DB_SELECT_STATUS offline_queue=1 / OK ✅
REAL_DB_SELECT_STATUS offline_lines=1 / OK ✅
REAL_DB_SELECT_STATUS offline_payment_placeholder=1 / OK ✅
REAL_DB_SELECT_STATUS offline_queue_audit=1 / OK ✅
IDEMPOTENCY_STATUS duplicate returned existing queue / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_queue_rows=1 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_new_queue=0 / OK ✅
OFFLINE_SYNC_STATUS HTTP 201 synced / OK ✅
REAL_DB_SELECT_STATUS queue_synced=1 / OK ✅
REAL_DB_SELECT_STATUS sync_attempt=1 / OK ✅
REAL_DB_SELECT_STATUS synced_sale=1 / OK ✅
REAL_DB_SELECT_STATUS synced_sale_line=1 / OK ✅
REAL_DB_SELECT_STATUS synced_payment=1 / OK ✅
REAL_DB_SELECT_STATUS offline_payment_synced=1 / OK ✅
REAL_DB_SELECT_STATUS offline_sync_stock_movement=1 / OK ✅
REAL_DB_SELECT_STATUS sync_audit=1 / OK ✅
REAL_DB_SELECT_STATUS stock_after_sync=1 / OK ✅
SYNC_IDEMPOTENCY_STATUS duplicate sync no second sale / OK ✅
PARTIAL_WRITE_STATUS sync duplicate blocked: sync_sale_rows=1 / OK ✅
PARTIAL_WRITE_STATUS sync duplicate blocked: sync_queue_rows=1 / OK ✅
CONFLICT_QUEUE_STATUS queued / OK ✅
STOCK_CONFLICT_STATUS HTTP 409 / OK ✅
REAL_DB_SELECT_STATUS conflict_queue=1 / OK ✅
REAL_DB_SELECT_STATUS conflict_attempt=1 / OK ✅
REAL_DB_SELECT_STATUS conflict_no_sale=0 / OK ✅
REAL_DB_SELECT_STATUS conflict_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_queue=0 / OK ✅
CROSS_TENANT_GUARD_STATUS cashier not active in tenant B / OK ✅
PARTIAL_WRITE_STATUS cross_queue=0 / OK ✅
ROLLBACK_STATUS queue sale HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_queue=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_lines=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_payment=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
OFFLINE_STATUS_ENDPOINT_STATUS HTTP 200 synced / OK ✅
ROUTE_SMOKE_STATUS /offline-pos/ marker / OK ✅
FINAL_OFFLINE_POS_STATUS final_queue_synced=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_offline_lines=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_payment_synced=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_sync_attempt=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_synced_sale=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_stock_movement=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_conflict_queue=1 / OK ✅
FINAL_OFFLINE_POS_STATUS final_audit >= 3 / OK ✅
config semantic validation / OK ✅
```
