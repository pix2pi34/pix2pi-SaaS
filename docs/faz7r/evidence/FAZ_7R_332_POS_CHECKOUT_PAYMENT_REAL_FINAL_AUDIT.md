# FAZ 7-R / 332 POS CHECKOUT / PAYMENT REAL FINAL AUDIT

- PASS_COUNT=67
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=pos-checkout-payment-332-20260513_230836
- TENANT_ID=tenant-api-e2e-success
- CART_ID=cart-332-main-20260513_230836
- PAYMENT_ID=payment-332-main-20260513_230836

## Readiness SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
tenant_b_owner_role=1
no_role_count=0
checkout_product_ready=1
```
## Cart create response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "cart_id": "cart-332-main-20260513_230836", "cart_status": "open"}
```
## Create SELECT
```
cart_created=1
cart_create_audit=1
```
## Add item response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "cart_id": "cart-332-main-20260513_230836", "cart_item_id": "cart-item-47bf2c3a-a96c-4b7c-95c5-cc1778c1d60b", "line_total": 301.2}
```
## Add SELECT
```
cart_item_created=1
cart_totals_updated=1
cart_add_audit=1
```
## Summary response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "cart": {"cart_id": "cart-332-main-20260513_230836", "cart_status": "open", "store_id": "store-332-main", "register_id": "register-332-main", "currency": "TRY", "subtotal_amount": "251.00", "vat_amount": "50.20", "total_amount": "301.20"}, "items": [{"cart_item_id": "cart-item-47bf2c3a-a96c-4b7c-95c5-cc1778c1d60b", "product_id": "checkout-product-332-main", "product_name": "332 POS Checkout Test Ürün", "quantity": "2.000", "unit_price": "125.50", "line_total": "301.20"}]}
```
## Summary SELECT
```
cart_summary_audit=1
```
## Payment response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "cart_id": "cart-332-main-20260513_230836", "payment_id": "payment-332-main-20260513_230836", "payment_status": "pending", "amount": 301.2}
{"ok": true, "duplicate": true, "payment_id": "payment-332-main-20260513_230836", "payment_status": "pending"}
```
## Payment SELECT
```
payment_started=1
payment_duplicate_new_row=0
payment_start_audit=1
```
## Paid response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "cart_id": "cart-332-main-20260513_230836", "payment_id": "payment-332-main-20260513_230836", "old_status": "pending", "new_status": "paid"}
```
## Paid SELECT
```
payment_paid=1
cart_paid=1
payment_paid_audit=1
```
## Failed payment response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "cart_id": "cart-332-failed-20260513_230836", "payment_id": "payment-332-failed-20260513_230836", "old_status": "pending", "new_status": "failed"}
```
## Failed SELECT
```
failed_payment=1
failed_cart_still_open=1
failed_flow_audits=4
```
## Cross response
```json
{"ok": false, "error": "cart_not_found"}
```
## Cross SELECT
```
tenant_b_cart_rows=0
tenant_a_cart_still_paid=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_cart=0
no_role_audit=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_item=0
rollback_cart_zero_total=1
rollback_audit=0
```
## Final SELECT
```
final_main_cart_paid=1
final_main_cart_items=1
final_payment_paid=1
final_failed_payment=1
final_main_audits=5
final_failed_audits=4
final_no_role_cart=0
final_rollback_item=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: pos_checkout.checkout_product_snapshots / OK ✅
table exists: pos_checkout.pos_cart_items / OK ✅
table exists: pos_checkout.pos_carts / OK ✅
table exists: pos_checkout.pos_checkout_audit_events / OK ✅
table exists: pos_checkout.pos_checkout_payments / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx POS checkout route bind / OK ✅
POS checkout cart-create route reaches API 422 / OK ✅
frontend POS checkout page written / OK ✅
POS checkout seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
READINESS_STATUS checkout_product_ready=1 / OK ✅
CART_CREATE_STATUS HTTP 201 open / OK ✅
REAL_DB_SELECT_STATUS cart_created=1 / OK ✅
REAL_DB_SELECT_STATUS cart_create_audit=1 / OK ✅
CART_ADD_ITEM_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS cart_item_created=1 / OK ✅
REAL_DB_SELECT_STATUS cart_totals_updated=1 / OK ✅
REAL_DB_SELECT_STATUS cart_add_audit=1 / OK ✅
CART_SUMMARY_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS cart_summary_audit=1 / OK ✅
PAYMENT_START_STATUS HTTP 201 pending / OK ✅
PAYMENT_IDEMPOTENCY_STATUS duplicate returned existing payment / OK ✅
REAL_DB_SELECT_STATUS payment_started=1 / OK ✅
REAL_DB_SELECT_STATUS payment_duplicate_new_row=0 / OK ✅
REAL_DB_SELECT_STATUS payment_start_audit=1 / OK ✅
PAYMENT_PAID_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS payment_paid=1 / OK ✅
REAL_DB_SELECT_STATUS cart_paid=1 / OK ✅
REAL_DB_SELECT_STATUS payment_paid_audit=1 / OK ✅
PAYMENT_FAILED_STATUS HTTP flow passed / OK ✅
REAL_DB_SELECT_STATUS failed_payment=1 / OK ✅
REAL_DB_SELECT_STATUS failed_cart_still_open=1 / OK ✅
REAL_DB_SELECT_STATUS failed_flow_audits=4 / OK ✅
TENANT_SAFE_CHECKOUT_STATUS tenant B cannot view tenant A cart / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_cart_rows=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_a_cart_still_paid=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_cart=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
ROLLBACK_STATUS cart add item HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_item=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_cart_zero_total=1 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /checkout/ marker / OK ✅
FINAL_POS_CHECKOUT_STATUS final_main_cart_paid=1 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_main_cart_items=1 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_payment_paid=1 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_failed_payment=1 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_main_audits=5 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_failed_audits=4 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_no_role_cart=0 / OK ✅
FINAL_POS_CHECKOUT_STATUS final_rollback_item=0 / OK ✅
config semantic validation / OK ✅
```
