# FAZ 7-R / 347 PILOT CUSTOMER TENANT OPENING REAL FINAL AUDIT

- PASS_COUNT=68
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=pilot-tenant-opening-347-20260513_234022
- TENANT_ID=tenant-api-e2e-success
- OPENING_ID=pilot-opening-347-20260513_234022

## Source SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
commercial_ready=1
entitlement_ui_ready=1
active_subscription=1
paid_invoice=1
```
## Readiness SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
tenant_b_owner_role=1
no_role_count=0
commercial_ready=1
entitlement_ready=1
```
## Open response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "opening_id": "pilot-opening-347-20260513_234022", "pilot_customer_code": "pilot-customer-347", "opening_status": "opened", "access_status": "active", "commercial_status": "ready", "legal_status": "accepted", "owner_user_id": "user-348-accepted", "plan_code": "pix2pi-starter", "subscription_id": "subscription-342-main-20260513_230101", "paid_invoice_id": "invoice-343-main-20260513_231733", "entitlement_status": "ready"}
```
## Open SELECT
```
pilot_opening_created=1
legal_commercial_binding=1
owner_binding=1
access_activation=1
opening_audit=1
```
## Status response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "opening_id": "pilot-opening-347-20260513_234022", "pilot_customer_code": "pilot-customer-347", "pilot_customer_name": "Pix2pi Kontrollü Pilot Müşteri", "opening_status": "opened", "access_status": "active", "commercial_status": "ready", "legal_status": "accepted", "owner_user_id": "user-348-accepted", "plan_code": "pix2pi-starter", "subscription_id": "subscription-342-main-20260513_230101", "paid_invoice_id": "invoice-343-main-20260513_231733", "entitlement_status": "ready"}
```
## Status SELECT
```
status_view_audit=1
```
## Cross response
```json
{"ok": false, "error": "commercial_context_not_ready"}
```
## Cross SELECT
```
tenant_b_opening=0
tenant_safe_deny_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_opening=0
no_role_audit=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_opening=0
rollback_legal_binding=0
rollback_owner_binding=0
rollback_activation=0
rollback_audit=0
```
## Final SELECT
```
final_pilot_opening=1
final_legal_binding=1
final_owner_binding=1
final_access_activation=1
final_main_audits=1
final_cross_deny_audit=1
final_no_role_opening=0
final_no_rollback_opening=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_346_PLAN_ENFORCEMENT_ENTITLEMENT_UI_GUARD_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_345_COMMERCIAL_ACCOUNT_BILLING_CONSOLE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_344_ENTITLEMENT_QUOTA_ENFORCEMENT_RUNTIME_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_343_BILLING_INVOICE_PAYMENT_COLLECTION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_342_SUBSCRIPTION_TENANT_BILLING_LIFECYCLE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_341_COMMERCIAL_PLAN_PACKAGE_RUNTIME_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: pilot_runtime.pilot_customer_tenant_openings / OK ✅
table exists: pilot_runtime.pilot_tenant_access_activations / OK ✅
table exists: pilot_runtime.pilot_tenant_legal_commercial_bindings / OK ✅
table exists: pilot_runtime.pilot_tenant_opening_audit_events / OK ✅
table exists: pilot_runtime.pilot_tenant_owner_bindings / OK ✅
SOURCE_STATUS tenant_opened=1 / OK ✅
SOURCE_STATUS tenant_b_opened=1 / OK ✅
SOURCE_STATUS owner_active=1 / OK ✅
SOURCE_STATUS owner_role=1 / OK ✅
SOURCE_STATUS commercial_ready=1 / OK ✅
SOURCE_STATUS entitlement_ui_ready=1 / OK ✅
SOURCE_STATUS active_subscription=1 / OK ✅
SOURCE_STATUS paid_invoice=1 / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx pilot tenant opening route bind / OK ✅
pilot opening route reaches API 422 / OK ✅
frontend pilot tenant opening page written / OK ✅
pilot tenant opening cleanup and seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
READINESS_STATUS commercial_ready=1 / OK ✅
READINESS_STATUS entitlement_ready=1 / OK ✅
PILOT_TENANT_OPENING_STATUS HTTP 201 opened/active / OK ✅
REAL_DB_SELECT_STATUS pilot_opening_created=1 / OK ✅
REAL_DB_SELECT_STATUS legal_commercial_binding=1 / OK ✅
REAL_DB_SELECT_STATUS owner_binding=1 / OK ✅
REAL_DB_SELECT_STATUS access_activation=1 / OK ✅
REAL_DB_SELECT_STATUS opening_audit=1 / OK ✅
PILOT_TENANT_STATUS_VIEW HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS status_view_audit=1 / OK ✅
TENANT_SAFE_PILOT_OPENING_STATUS tenant B cannot use tenant A commercial state / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_opening=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_safe_deny_audit=1 / OK ✅
NO_ROLE_PILOT_OPENING_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_opening=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
ROLLBACK_STATUS pilot opening HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_opening=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_legal_binding=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_owner_binding=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_activation=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /pilot-tenant-opening/ marker / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_pilot_opening=1 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_legal_binding=1 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_owner_binding=1 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_access_activation=1 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_main_audits=1 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_cross_deny_audit=1 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_no_role_opening=0 / OK ✅
FINAL_PILOT_TENANT_OPENING_STATUS final_no_rollback_opening=0 / OK ✅
config semantic validation / OK ✅
```
