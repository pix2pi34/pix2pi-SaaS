# FAZ 7-R / 337 MARKETPLACE ORDER FLOW REAL FINAL AUDIT

- PASS_COUNT=67
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=marketplace-order-337-20260513_223431
- SELLER_ID=seller-335-main
- CATALOG_PRODUCT_ID=catalog-product-335-main
- ORDER_MAIN_ID=market-order-337-main-20260513_223431
- ORDER_REJECT_ID=market-order-337-reject-20260513_223431

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
seller_enabled=1
catalog_product_public=1
checkout_intents_seeded=4
tenant_b_opened=1
no_role_count=0
```
## Disabled guard response
```json
{"ok": false, "error": "marketplace_disabled_controlled_access_required"}
```
## Disabled SELECT
```
disabled_order_blocked=0
disabled_intent_still_created=1
disabled_deny_audit=1
```
## Create order response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-337-main-20260513_223431", "checkout_intent_id": "checkout-intent-337-main-20260513_223431", "order_status": "requested", "total_amount": 301.2, "next_url": "/orders/?order_id=market-order-337-main-20260513_223431"}
```
## Create SELECT
```
order_created=1
order_item_created=1
intent_converted=1
order_create_audit=1
```
## List response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "count": 1, "orders": [{"marketplace_order_id": "market-order-337-main-20260513_223431", "checkout_intent_id": "checkout-intent-337-main-20260513_223431", "buyer_session_id": "buyer-337-main", "order_no": "MKT-3B7A525BC786", "order_status": "requested", "total_amount": "301.20", "created_at": "2026-05-13 19:34:35.988572+00"}]}
```
## List SELECT
```
seller_list_audit=1
```
## Accept response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-337-main-20260513_223431", "old_status": "requested", "new_status": "accepted"}
```
## Preparing response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-337-main-20260513_223431", "old_status": "accepted", "new_status": "preparing"}
```
## Status SELECT
```
main_order_preparing=1
main_status_history=2
main_status_audit=2
```
## Reject create response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-337-reject-20260513_223431", "checkout_intent_id": "checkout-intent-337-reject-20260513_223431", "order_status": "requested", "total_amount": 150.6, "next_url": "/orders/?order_id=market-order-337-reject-20260513_223431"}
```
## Reject response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-337-reject-20260513_223431", "old_status": "requested", "new_status": "rejected"}
```
## Reject SELECT
```
reject_order_rejected=1
reject_status_history=1
reject_audit=2
```
## Cross response
```json
{"ok": false, "error": "seller_not_found"}
```
## Cross SELECT
```
tenant_b_order_rows=0
tenant_a_orders_still_present=2
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_history=0
no_role_audit=0
main_order_not_changed_by_no_role=1
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_order=0
rollback_item=0
rollback_audit=0
rollback_intent_still_created=1
```
## Final SELECT
```
final_main_order_preparing=1
final_reject_order_rejected=1
final_order_items=2
final_status_history=3
final_converted_intents=2
final_order_audits=7
final_rollback_order=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_336_MARKETPLACE_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_335_MARKETPLACE_CATALOG_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_316_NGINX_ROUTE_GOVERNANCE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: marketplace_runtime.marketplace_order_audit_events / OK ✅
table exists: marketplace_runtime.marketplace_order_items / OK ✅
table exists: marketplace_runtime.marketplace_order_status_history / OK ✅
table exists: marketplace_runtime.marketplace_orders / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx marketplace order route bind / OK ✅
marketplace order create route reaches API 422 / OK ✅
frontend marketplace order page written / OK ✅
marketplace order cleanup and intent seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS seller_enabled=1 / OK ✅
READINESS_STATUS catalog_product_public=1 / OK ✅
READINESS_STATUS checkout_intents_seeded=4 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
CONTROLLED_MARKETPLACE_ORDER_GUARD_STATUS HTTP 403 / OK ✅
CONTROLLED_ORDER_DB_STATUS disabled_order_blocked=0 / OK ✅
CONTROLLED_ORDER_DB_STATUS disabled_intent_still_created=1 / OK ✅
CONTROLLED_ORDER_DB_STATUS disabled_deny_audit=1 / OK ✅
MARKETPLACE_ORDER_CREATE_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS order_created=1 / OK ✅
REAL_DB_SELECT_STATUS order_item_created=1 / OK ✅
REAL_DB_SELECT_STATUS intent_converted=1 / OK ✅
REAL_DB_SELECT_STATUS order_create_audit=1 / OK ✅
SELLER_ORDER_LIST_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS seller_list_audit=1 / OK ✅
ORDER_ACCEPT_STATUS HTTP 200 / OK ✅
ORDER_PREPARING_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS main_order_preparing=1 / OK ✅
REAL_DB_SELECT_STATUS main_status_history=2 / OK ✅
REAL_DB_SELECT_STATUS main_status_audit=2 / OK ✅
REJECT_ORDER_CREATE_STATUS HTTP 201 / OK ✅
ORDER_REJECT_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS reject_order_rejected=1 / OK ✅
REAL_DB_SELECT_STATUS reject_status_history=1 / OK ✅
REAL_DB_SELECT_STATUS reject_audit=2 / OK ✅
TENANT_SAFE_ORDER_GUARD_STATUS tenant B cannot list tenant A seller orders / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_order_rows=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_a_orders_still_present=2 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_history=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
PARTIAL_WRITE_STATUS main_order_not_changed_by_no_role=1 / OK ✅
ROLLBACK_STATUS order create HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_order=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_item=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_intent_still_created=1 / OK ✅
ROUTE_SMOKE_STATUS /orders/ marker / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_main_order_preparing=1 / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_reject_order_rejected=1 / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_order_items=2 / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_status_history=3 / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_converted_intents=2 / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_order_audits=7 / OK ✅
FINAL_MARKETPLACE_ORDER_STATUS final_rollback_order=0 / OK ✅
config semantic validation / OK ✅
```
