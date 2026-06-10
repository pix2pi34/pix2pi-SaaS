# FAZ 7-R / 335 MARKETPLACE CATALOG REAL FINAL AUDIT

- PASS_COUNT=52
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=marketplace-catalog-335-20260513_221532
- SELLER_ID=seller-335-main
- CATALOG_PRODUCT_ID=catalog-product-335-main

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
source_product=1
rollback_source_product=1
tenant_b_opened=1
no_role_count=0
```
## Publish response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "seller_id": "seller-335-main", "catalog_product_id": "catalog-product-335-main", "source_product_id": "product-355-main", "title": "335 Marketplace Test Ürünü", "slug": "335-marketplace-test-urunu", "catalog_status": "published", "marketplace_enabled": false, "next_url": "/catalog/?product=335-marketplace-test-urunu"}
```
## Publish SELECT
```
seller_created=1
catalog_product_created=1
publish_audit=1
```
## Catalog list response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"catalog_product_id": "catalog-product-335-main", "seller_id": "seller-335-main", "seller_tenant_id": "tenant-api-e2e-success", "title": "335 Marketplace Test Ürünü", "slug": "335-marketplace-test-urunu", "category_code": "AUTO-PARTS", "category_name": "Oto Yedek Parça", "sale_price": "100.00", "currency": "TRY", "stock_quantity_snapshot": "10.000", "checkout_enabled": false}]}
```
## Catalog detail response
```json
{"ok": true, "product": {"catalog_product_id": "catalog-product-335-main", "seller_id": "seller-335-main", "seller_tenant_id": "tenant-api-e2e-success", "title": "335 Marketplace Test Ürünü", "slug": "335-marketplace-test-urunu", "category_code": "AUTO-PARTS", "category_name": "Oto Yedek Parça", "sale_price": "100.00", "currency": "TRY", "stock_quantity_snapshot": "10.000", "checkout_enabled": false}}
```
## Checkout guard response
```json
{"ok": false, "error": "marketplace_disabled_controlled_access_required"}
```
## Checkout SELECT
```
checkout_intent_blocked=0
checkout_deny_audit=1
```
## Cross detail response
```json
{"ok": false, "error": "catalog_product_not_found"}
```
## Cross list response
```json
{"ok": true, "seller_tenant_id": "tenant-api-e2e-isolated-b", "count": 0, "items": []}
```
## Duplicate response
```json
{"ok": false, "error": "duplicate_catalog_product", "detail": "ERROR:  duplicate key value violates unique constraint \"marketplace_catalog_products_tenant_id_source_product_id_key\"\nDETAIL:  Key (tenant_id, source_product_id)=(tenant-api-e2e-success, product-355-main) already exists.\n"}
```
## Duplicate SELECT
```
duplicate_product=0
duplicate_audit=0
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_seller=0
no_role_product=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_seller=0
rollback_product=0
rollback_audit=0
```
## Final SELECT
```
final_seller=1
final_catalog_product=1
final_checkout_intents=0
final_allow_audit=1
final_deny_audit=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_316_NGINX_ROUTE_GOVERNANCE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_324_PRODUCT_STOCK_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_328_IMPORT_EXPORT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: marketplace_runtime.marketplace_catalog_audit_events / OK ✅
table exists: marketplace_runtime.marketplace_catalog_products / OK ✅
table exists: marketplace_runtime.marketplace_checkout_intents / OK ✅
table exists: marketplace_runtime.marketplace_sellers / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx marketplace route bind / OK ✅
marketplace admin publish route reaches API 422 / OK ✅
frontend marketplace catalog page written / OK ✅
marketplace cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS source_product=1 / OK ✅
READINESS_STATUS rollback_source_product=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
MARKETPLACE_PUBLISH_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS seller_created=1 / OK ✅
REAL_DB_SELECT_STATUS catalog_product_created=1 / OK ✅
REAL_DB_SELECT_STATUS publish_audit=1 / OK ✅
CATALOG_LIST_STATUS category/search/filter HTTP 200 / OK ✅
CATALOG_DETAIL_STATUS HTTP 200 / OK ✅
MARKETPLACE_CONTROLLED_ACCESS_GUARD_STATUS HTTP 403 / OK ✅
CONTROLLED_ACCESS_DB_STATUS checkout_intent_blocked=0 / OK ✅
CONTROLLED_ACCESS_DB_STATUS checkout_deny_audit=1 / OK ✅
TENANT_SAFE_DETAIL_STATUS tenant B cannot read tenant A product / OK ✅
TENANT_SAFE_LIST_STATUS tenant B list has no tenant A product / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_product=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_audit=0 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_seller=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_product=0 / OK ✅
ROLLBACK_STATUS marketplace publish HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_seller=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_product=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /catalog/ marker / OK ✅
FINAL_MARKETPLACE_STATUS final_seller=1 / OK ✅
FINAL_MARKETPLACE_STATUS final_catalog_product=1 / OK ✅
FINAL_MARKETPLACE_STATUS final_checkout_intents=0 / OK ✅
FINAL_MARKETPLACE_STATUS final_allow_audit=1 / OK ✅
FINAL_MARKETPLACE_STATUS final_deny_audit=1 / OK ✅
config semantic validation / OK ✅
```
