# FAZ 7-R / 344 ENTITLEMENT / QUOTA ENFORCEMENT RUNTIME REAL FINAL AUDIT

- PASS_COUNT=67
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=entitlement-quota-runtime-344-20260513_232126
- TENANT_ID=tenant-api-e2e-success
- ALLOW_FEATURE=marketplace.catalog.publish
- QUOTA_EXCEED_FEATURE=marketplace.order.create
- DISABLED_FEATURE=commercial.billing.live

## Source SELECT
```
active_assignment=1
active_subscription=1
paid_invoice=1
feature_allow_ready=1
feature_disabled_ready=1
quota_exceed_seed=1
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
```
## Check allowed response
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "plan_code": "pix2pi-starter", "subscription_id": "subscription-342-main-20260513_230101", "paid_invoice_id": "invoice-343-main-20260513_231733", "feature_code": "marketplace.catalog.publish", "used_amount": 0.0, "limit_value": 10.0, "period_key": "2026-05"}
```
## Check SELECT
```
entitlement_allowed_decision=1
entitlement_check_audit=1
```
## Reserve response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "feature_code": "marketplace.catalog.publish", "period_key": "2026-05", "reserved_amount": 1.0, "used_amount": 1.0, "limit_value": 10.0, "ledger_id": "entitlement-ledger-ac11ecb8-78ac-4266-9d3f-0175f92118f4"}
```
## Reserve SELECT
```
usage_ledger_reserved=1
quota_usage_updated=1
quota_reserve_audit=1
```
## Disabled response
```json
{"ok": false, "error": "feature_disabled", "feature_code": "commercial.billing.live"}
```
## Quota exceed response
```json
{"ok": false, "error": "quota_exceeded", "used_amount": 2.0, "requested_amount": 1.0, "limit_value": 2.0}
```
## Negative SELECT
```
disabled_deny_decision=1
quota_exceed_deny_decision=1
negative_deny_audits=2
```
## Cross response
```json
{"ok": false, "error": "no_active_plan"}
```
## Cross SELECT
```
tenant_b_usage_ledger=0
tenant_safe_deny_decision=1
tenant_safe_deny_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_decision=0
no_role_audit=0
no_role_ledger=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_ledger=0
rollback_decision=0
rollback_audit=0
rollback_usage=0
```
## Summary response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "plan_code": "pix2pi-starter", "subscription_id": "subscription-342-main-20260513_230101", "paid_invoice_id": "invoice-343-main-20260513_231733", "features": [{"feature_code": "commercial.billing.live", "feature_name": "Canlı billing", "enabled": false, "limit_kind": "none", "limit_value": "0.000", "used_amount": "0"}, {"feature_code": "marketplace.catalog.publish", "feature_name": "Marketplace katalog yayınlama", "enabled": true, "limit_kind": "quota", "limit_value": "10.000", "used_amount": "1.000"}, {"feature_code": "marketplace.order.create", "feature_name": "Marketplace sipariş oluşturma", "enabled": true, "limit_kind": "quota", "limit_value": "2.000", "used_amount": "2.000"}, {"feature_code": "panel.dashboard.view", "feature_name": "Panel dashboard görüntüleme", "enabled": true, "limit_kind": "quota", "limit_value": "1000.000", "used_amount": "0"}, {"feature_code": "pos.sale.create", "feature_name": "POS satış oluşturma", "enabled": true, "limit_kind": "quota", "limit_value": "100.000", "used_amount": "0"}, {"feature_code": "report.view", "feature_name": "Rapor görüntüleme", "enabled": true, "limit_kind": "quota", "limit_value": "20.000", "used_amount": "0"}]}
```
## Summary SELECT
```
summary_audit=1
```
## Final SELECT
```
final_allow_decisions=2
final_allow_audits=3
final_usage_ledger=1
final_allow_feature_usage=1
final_deny_decisions=3
final_deny_audits=3
final_no_role_decisions=0
final_no_rollback_ledger=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_343_BILLING_INVOICE_PAYMENT_COLLECTION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_342_SUBSCRIPTION_TENANT_BILLING_LIFECYCLE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_341_COMMERCIAL_PLAN_PACKAGE_RUNTIME_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: commercial_runtime.entitlement_runtime_audit_events / OK ✅
table exists: commercial_runtime.entitlement_runtime_decisions / OK ✅
table exists: commercial_runtime.entitlement_usage_ledger / OK ✅
SOURCE_STATUS active_assignment=1 / OK ✅
SOURCE_STATUS active_subscription=1 / OK ✅
SOURCE_STATUS paid_invoice=1 / OK ✅
SOURCE_STATUS feature_allow_ready=1 / OK ✅
SOURCE_STATUS feature_disabled_ready=1 / OK ✅
SOURCE_STATUS quota_exceed_seed=1 / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx entitlement runtime route bind / OK ✅
entitlement check route reaches API 422 / OK ✅
frontend entitlement runtime page written / OK ✅
entitlement runtime cleanup completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
READINESS_STATUS active_subscription=1 / OK ✅
READINESS_STATUS paid_invoice=1 / OK ✅
ENTITLEMENT_CHECK_STATUS HTTP 200 allowed / OK ✅
REAL_DB_SELECT_STATUS entitlement_allowed_decision=1 / OK ✅
REAL_DB_SELECT_STATUS entitlement_check_audit=1 / OK ✅
QUOTA_RESERVE_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS usage_ledger_reserved=1 / OK ✅
REAL_DB_SELECT_STATUS quota_usage_updated=1 / OK ✅
REAL_DB_SELECT_STATUS quota_reserve_audit=1 / OK ✅
DISABLED_FEATURE_GUARD_STATUS HTTP 403 / OK ✅
QUOTA_EXCEEDED_GUARD_STATUS HTTP 429 / OK ✅
REAL_DB_SELECT_STATUS disabled_deny_decision=1 / OK ✅
REAL_DB_SELECT_STATUS quota_exceed_deny_decision=1 / OK ✅
REAL_DB_SELECT_STATUS negative_deny_audits=2 / OK ✅
TENANT_SAFE_ENTITLEMENT_STATUS tenant B cannot use tenant A commercial state / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_usage_ledger=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_safe_deny_decision=1 / OK ✅
TENANT_SAFE_DB_STATUS tenant_safe_deny_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_decision=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_ledger=0 / OK ✅
ROLLBACK_STATUS entitlement reserve HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_ledger=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_decision=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_usage=0 / OK ✅
ENTITLEMENT_SUMMARY_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS summary_audit=1 / OK ✅
ROUTE_SMOKE_STATUS /commercial/entitlements-runtime/ marker / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_allow_decisions=2 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_allow_audits=3 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_usage_ledger=1 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_allow_feature_usage=1 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_deny_decisions=3 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_deny_audits=3 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_no_role_decisions=0 / OK ✅
FINAL_ENTITLEMENT_RUNTIME_STATUS final_no_rollback_ledger=0 / OK ✅
config semantic validation / OK ✅
```
