# FAZ 7-R / 345 COMMERCIAL ACCOUNT / BILLING CONSOLE REAL FINAL AUDIT

- PASS_COUNT=50
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=commercial-account-console-345-20260513_232918
- TENANT_ID=tenant-api-e2e-success

## Source SELECT
```
active_plan_assignment=1
active_subscription=1
paid_invoice=1
entitlement_allow_decisions=2
entitlement_usage_ledger=1
plan_feature_matrix=6
```
## Readiness SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
tenant_b_owner_role=1
no_role_count=0
active_subscription=1
paid_invoice=1
entitlement_usage=1
```
## Account summary response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "account_status": "commercial_ready", "plan": {"plan_code": "pix2pi-starter", "plan_status": "active"}, "subscription": {"subscription_id": "subscription-342-main-20260513_230101", "subscription_status": "active"}, "billing": {"latest_invoice_id": "invoice-343-main-20260513_231733", "latest_invoice_status": "paid", "latest_total_amount": 1198.8, "invoices": [{"invoice_id": "invoice-343-failed-20260513_231733", "invoice_no": "INV-343-FAILED-20260513_231733", "invoice_status": "payment_failed", "total_amount": "1198.80", "issued_at": "2026-05-13 20:17:41.559909+00"}, {"invoice_id": "invoice-343-main-20260513_231733", "invoice_no": "INV-343-20260513_231733", "invoice_status": "paid", "total_amount": "1198.80", "issued_at": "2026-05-13 20:17:37.346012+00"}], "collections": [{"collection_id": "collection-343-failed-20260513_231733", "invoice_id": "invoice-343-failed-20260513_231733", "collection_status": "failed", "amount": "1198.80"}, {"collection_id": "collection-343-main-20260513_231733", "invoice_id": "invoice-343-main-20260513_231733", "collection_status": "collected", "amount": "1198.80"}]}, "entitlements": {"feature_count": 6, "usage_count": 2, "deny_decision_count": 2, "features": [{"feature_code": "commercial.billing.live", "feature_name": "Canlı billing", "enabled": false, "limit_kind": "none", "limit_value": "0.000"}, {"feature_code": "marketplace.catalog.publish", "feature_name": "Marketplace katalog yayınlama", "enabled": true, "limit_kind": "quota", "limit_value": "10.000"}, {"feature_code": "marketplace.order.create", "feature_name": "Marketplace sipariş oluşturma", "enabled": true, "limit_kind": "quota", "limit_value": "2.000"}, {"feature_code": "panel.dashboard.view", "feature_name": "Panel dashboard görüntüleme", "enabled": true, "limit_kind": "quota", "limit_value": "1000.000"}, {"feature_code": "pos.sale.create", "feature_name": "POS satış oluşturma", "enabled": true, "limit_kind": "quota", "limit_value": "100.000"}, {"feature_code": "report.view", "feature_name": "Rapor görüntüleme", "enabled": true, "limit_kind": "quota", "limit_value": "20.000"}], "usage": [{"feature_code": "marketplace.catalog.publish", "period_key": "2026-05", "used_amount": "1.000", "limit_value": "10.000"}, {"feature_code": "marketplace.order.create", "period_key": "2026-05", "used_amount": "2.000", "limit_value": "2.000"}], "recent_decisions": [{"feature_code": "marketplace.order.create", "decision": "deny", "reason_code": "quota_exceeded", "created_at": "2026-05-13 20:21:34.155951+00"}, {"feature_code": "commercial.billing.live", "decision": "deny", "reason_code": "feature_disabled", "created_at": "2026-05-13 20:21:33.142374+00"}, {"feature_code": "marketplace.catalog.publish", "decision": "allow", "reason_code": "reserved", "created_at": "2026-05-13 20:21:32.007289+00"}, {"feature_code": "marketplace.catalog.publish", "decision": "allow", "reason_code": "allowed", "created_at": "2026-05-13 20:21:30.866497+00"}]}}
```
## Summary SELECT
```
account_snapshot=1
account_summary_audit=1
```
## Health response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "commercial_health_status": "pass", "checks": {"plan_active": true, "subscription_active": true, "invoice_paid": true, "features_present": true, "entitlement_usage_present": true}, "account_status": "commercial_ready"}
```
## Health SELECT
```
account_health_audit=1
```
## Cross response
```json
{"ok": false, "error": "commercial_account_not_found"}
```
## Cross SELECT
```
tenant_b_snapshot=0
tenant_safe_deny_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_snapshot=0
no_role_audit=0
```
## Final SELECT
```
final_account_snapshot=1
final_account_audits=2
final_cross_deny_audit=1
final_no_role_snapshot=0
final_billing_paid_source=1
final_entitlement_usage_source=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_344_ENTITLEMENT_QUOTA_ENFORCEMENT_RUNTIME_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_343_BILLING_INVOICE_PAYMENT_COLLECTION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_342_SUBSCRIPTION_TENANT_BILLING_LIFECYCLE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_341_COMMERCIAL_PLAN_PACKAGE_RUNTIME_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: commercial_runtime.commercial_account_audit_events / OK ✅
table exists: commercial_runtime.commercial_account_snapshots / OK ✅
SOURCE_STATUS active_plan_assignment=1 / OK ✅
SOURCE_STATUS active_subscription=1 / OK ✅
SOURCE_STATUS paid_invoice=1 / OK ✅
SOURCE_STATUS entitlement_usage_ledger=1 / OK ✅
SOURCE_STATUS plan_feature_matrix=6 / OK ✅
SOURCE_STATUS entitlement_allow_decisions >= 1 / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx commercial account route bind / OK ✅
commercial account summary route reaches API 422 / OK ✅
frontend commercial account page written / OK ✅
commercial account cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
READINESS_STATUS active_subscription=1 / OK ✅
READINESS_STATUS paid_invoice=1 / OK ✅
READINESS_STATUS entitlement_usage=1 / OK ✅
COMMERCIAL_ACCOUNT_SUMMARY_STATUS HTTP 200 commercial_ready / OK ✅
REAL_DB_SELECT_STATUS account_snapshot=1 / OK ✅
REAL_DB_SELECT_STATUS account_summary_audit=1 / OK ✅
COMMERCIAL_ACCOUNT_HEALTH_STATUS pass / OK ✅
REAL_DB_SELECT_STATUS account_health_audit=1 / OK ✅
TENANT_SAFE_COMMERCIAL_ACCOUNT_STATUS tenant B cannot use tenant A commercial account / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_snapshot=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_safe_deny_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_snapshot=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /commercial/account/ marker / OK ✅
FINAL_COMMERCIAL_ACCOUNT_STATUS final_account_snapshot=1 / OK ✅
FINAL_COMMERCIAL_ACCOUNT_STATUS final_account_audits=2 / OK ✅
FINAL_COMMERCIAL_ACCOUNT_STATUS final_cross_deny_audit=1 / OK ✅
FINAL_COMMERCIAL_ACCOUNT_STATUS final_no_role_snapshot=0 / OK ✅
FINAL_COMMERCIAL_ACCOUNT_STATUS final_billing_paid_source=1 / OK ✅
FINAL_COMMERCIAL_ACCOUNT_STATUS final_entitlement_usage_source=1 / OK ✅
config semantic validation / OK ✅
```
