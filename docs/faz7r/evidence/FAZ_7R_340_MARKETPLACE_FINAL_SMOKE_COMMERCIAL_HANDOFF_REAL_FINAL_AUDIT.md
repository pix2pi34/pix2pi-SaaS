# FAZ 7-R / 340 MARKETPLACE FINAL SMOKE / COMMERCIAL HANDOFF REAL FINAL AUDIT

- PASS_COUNT=61
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=marketplace-final-smoke-340-20260513_224847
- SELLER_ID=seller-335-main
- CATALOG_PRODUCT_ID=catalog-product-335-main
- CHECKOUT_INTENT_ID=checkout-intent-336-c495b5ba-d876-4e5c-8b4b-c35d92b3221a
- ORDER_ID=market-order-340-final-20260513_224847
- PAYMENT_INTENT_ID=payment-intent-340-final-20260513_224847
- DELIVERY_ID=delivery-340-final-20260513_224847

## Readiness SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
seller_enabled=1
catalog_product_public=1
```
## Catalog response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"catalog_product_id": "catalog-product-335-main", "seller_id": "seller-335-main", "seller_tenant_id": "tenant-api-e2e-success", "title": "335 Marketplace Test Ürünü", "slug": "335-marketplace-test-urunu", "category_code": "AUTO-PARTS", "category_name": "Oto Yedek Parça", "sale_price": "125.50", "currency": "TRY", "stock_quantity_snapshot": "8.000", "checkout_enabled": true}]}
```
## Seller read response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller": {"seller_id": "seller-335-main", "seller_name": "Pix2pi Pilot Satıcı", "seller_status": "active", "marketplace_enabled": true, "controlled_access_enabled": true, "default_currency": "TRY"}, "products": [{"catalog_product_id": "catalog-product-335-main", "source_product_id": "product-355-main", "title": "335 Marketplace Test Ürünü", "category_code": "AUTO-PARTS", "sale_price": "125.50", "stock_quantity_snapshot": "8.000", "catalog_status": "published", "market_visibility": "public"}]}
```
## Checkout response
```json
{"ok": true, "checkout_intent_id": "checkout-intent-336-c495b5ba-d876-4e5c-8b4b-c35d92b3221a", "seller_tenant_id": "tenant-api-e2e-success", "catalog_product_id": "catalog-product-335-main"}
```
## Order create response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-340-final-20260513_224847", "checkout_intent_id": "checkout-intent-336-c495b5ba-d876-4e5c-8b4b-c35d92b3221a", "order_status": "requested", "total_amount": 150.6, "next_url": "/orders/?order_id=market-order-340-final-20260513_224847"}
```
## Order accept response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-340-final-20260513_224847", "old_status": "requested", "new_status": "accepted"}
```
## Order preparing response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-340-final-20260513_224847", "old_status": "accepted", "new_status": "preparing"}
```
## Payment intent response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-340-final-20260513_224847", "payment_intent_id": "payment-intent-340-final-20260513_224847", "payment_status": "pending", "amount": 150.6, "currency": "TRY"}
```
## Payment paid response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-340-final-20260513_224847", "payment_intent_id": "payment-intent-340-final-20260513_224847", "old_status": "pending", "new_status": "paid"}
```
## Delivery create response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "marketplace_order_id": "market-order-340-final-20260513_224847", "payment_intent_id": "payment-intent-340-final-20260513_224847", "delivery_id": "delivery-340-final-20260513_224847", "delivery_status": "preparing"}
```
## Delivery transit response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "delivery_id": "delivery-340-final-20260513_224847", "old_status": "preparing", "new_status": "in_transit"}
```
## Delivery delivered response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "delivery_id": "delivery-340-final-20260513_224847", "old_status": "in_transit", "new_status": "delivered"}
```
## Customer lookup response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "order": {"marketplace_order_id": "market-order-340-final-20260513_224847", "order_no": "MKT-D8D30471FF04", "order_status": "preparing", "currency": "TRY", "subtotal_amount": "125.50", "vat_amount": "25.10", "total_amount": "150.60"}, "payment": {"payment_intent_id": "payment-intent-340-final-20260513_224847", "payment_status": "paid", "amount": "150.60"}, "delivery": {"delivery_id": "delivery-340-final-20260513_224847", "delivery_status": "delivered", "tracking_placeholder_ref": "TRK-340-20260513_224847"}}
```
## Customer timeline response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "marketplace_order_id": "market-order-340-final-20260513_224847", "timeline_count": 8, "timeline": [{"event_type": "order_created", "old_status": "none", "new_status": "preparing", "created_at": "current_snapshot"}, {"event_type": "order_status", "old_status": "requested", "new_status": "accepted", "created_at": "2026-05-13 19:48:51.270774+00"}, {"event_type": "order_status", "old_status": "accepted", "new_status": "preparing", "created_at": "2026-05-13 19:48:52.066982+00"}, {"event_type": "payment_status", "old_status": "none", "new_status": "pending", "created_at": "2026-05-13 19:48:53.012525+00"}, {"event_type": "payment_status", "old_status": "pending", "new_status": "paid", "created_at": "2026-05-13 19:48:53.844705+00"}, {"event_type": "delivery_status", "old_status": "none", "new_status": "preparing", "created_at": "2026-05-13 19:48:54.675587+00"}, {"event_type": "delivery_status", "old_status": "preparing", "new_status": "in_transit", "created_at": "2026-05-13 19:48:55.520913+00"}, {"event_type": "delivery_status", "old_status": "in_transit", "new_status": "delivered", "created_at": "2026-05-13 19:48:56.338273+00"}]}
```
## Tenant safe response
```json
{"ok": false, "error": "order_not_found"}
```
## Controlled guard response
```json
{"ok": false, "error": "marketplace_disabled_controlled_access_required"}
```
## Handoff precheck SELECT
```
handoff_catalog_product=1
handoff_order=1
handoff_payment=1
handoff_delivery=1
handoff_customer_views=2
```
## DB SELECT
```
final_smoke_run=1
final_smoke_audits=8
commercial_handoff_checks=9
commercial_handoff_failures=0
```
## Rollback SELECT
```
rollback_final_audit=0
```
## Final SELECT
```
final_catalog_ready=1
final_checkout_intent=1
final_order_preparing=1
final_payment_paid=1
final_delivery_delivered=1
final_customer_views=2
final_smoke_record=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_339_MARKETPLACE_CUSTOMER_ORDER_VIEW_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_338_MARKETPLACE_PAYMENT_DELIVERY_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_337_MARKETPLACE_ORDER_FLOW_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_336_MARKETPLACE_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_335_MARKETPLACE_CATALOG_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_316_NGINX_ROUTE_GOVERNANCE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: marketplace_runtime.marketplace_commercial_handoff_checks / OK ✅
table exists: marketplace_runtime.marketplace_final_smoke_audit_events / OK ✅
table exists: marketplace_runtime.marketplace_final_smoke_runs / OK ✅
marketplace final smoke cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS seller_enabled=1 / OK ✅
READINESS_STATUS catalog_product_public=1 / OK ✅
CATALOG_FINAL_SMOKE_STATUS HTTP 200 checkout enabled / OK ✅
SELLER_MANAGEMENT_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
CHECKOUT_INTENT_FINAL_SMOKE_STATUS HTTP 201 / OK ✅
checkout intent id captured / OK ✅
ORDER_CREATE_FINAL_SMOKE_STATUS HTTP 201 / OK ✅
ORDER_ACCEPT_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
ORDER_PREPARING_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
PAYMENT_INTENT_FINAL_SMOKE_STATUS HTTP 201 / OK ✅
PAYMENT_PAID_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
DELIVERY_CREATE_FINAL_SMOKE_STATUS HTTP 201 / OK ✅
DELIVERY_TRANSIT_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
DELIVERY_DELIVERED_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
CUSTOMER_TRACKING_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
CUSTOMER_TIMELINE_FINAL_SMOKE_STATUS HTTP 200 / OK ✅
TENANT_SAFE_FINAL_SMOKE_STATUS tenant B cannot view tenant A final order / OK ✅
CONTROLLED_GUARD_FINAL_SMOKE_STATUS checkout blocked HTTP 403 / OK ✅
ROUTE_SMOKE_STATUS market.pix2pi.com.tr/catalog/ marker / OK ✅
ROUTE_SMOKE_STATUS market.pix2pi.com.tr/management/ marker / OK ✅
ROUTE_SMOKE_STATUS market.pix2pi.com.tr/orders/ marker / OK ✅
ROUTE_SMOKE_STATUS market.pix2pi.com.tr/payment-delivery/ marker / OK ✅
ROUTE_SMOKE_STATUS market.pix2pi.com.tr/customer-orders/ marker / OK ✅
COMMERCIAL_HANDOFF_PRECHECK handoff_catalog_product=1 / OK ✅
COMMERCIAL_HANDOFF_PRECHECK handoff_order=1 / OK ✅
COMMERCIAL_HANDOFF_PRECHECK handoff_payment=1 / OK ✅
COMMERCIAL_HANDOFF_PRECHECK handoff_delivery=1 / OK ✅
COMMERCIAL_HANDOFF_PRECHECK handoff_customer_views=2 / OK ✅
MARKETPLACE_FINAL_AUDIT_DB_WRITE_STATUS / OK ✅
REAL_DB_SELECT_STATUS final_smoke_run=1 / OK ✅
REAL_DB_SELECT_STATUS final_smoke_audits=8 / OK ✅
REAL_DB_SELECT_STATUS commercial_handoff_checks=9 / OK ✅
REAL_DB_SELECT_STATUS commercial_handoff_failures=0 / OK ✅
ROLLBACK_STATUS simulated DB failure occurred / OK ✅
TRANSACTION_STATUS rollback no partial write / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_catalog_ready=1 / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_checkout_intent=1 / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_order_preparing=1 / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_payment_paid=1 / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_delivery_delivered=1 / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_customer_views=2 / OK ✅
FINAL_MARKETPLACE_SMOKE_STATUS final_smoke_record=1 / OK ✅
config semantic validation / OK ✅
```
