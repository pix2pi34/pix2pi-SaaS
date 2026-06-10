# FAZ 7-R / 341 COMMERCIAL PLAN PACKAGE RUNTIME REAL FINAL AUDIT

- PASS_COUNT=63
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=commercial-plan-runtime-341-20260513_225505
- TENANT_ID=tenant-api-e2e-success
- PLAN_CODE=pix2pi-starter
- ASSIGNMENT_ID=plan-assignment-341-20260513_225505

## Readiness SELECT
```
tenant_opened=1
tenant_b_opened=1
owner_active=1
owner_role=1
tenant_b_owner_role=1
no_role_count=0
plan_seeded=2
feature_matrix_count=6
```
## Assign response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "plan_code": "pix2pi-starter", "assignment_id": "plan-assignment-341-20260513_225505", "plan_status": "active"}
```
## Assign SELECT
```
tenant_plan_assignment=1
tenant_plan_assignment_audit=1
```
## Summary response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "assignment_id": "plan-assignment-341-20260513_225505", "plan": {"plan_code": "pix2pi-starter", "plan_name": "Pix2pi Starter", "billing_cycle": "monthly", "currency": "TRY", "base_price": "999.00", "plan_status": "active"}, "features": [{"feature_code": "commercial.billing.live", "feature_name": "Canlı billing", "enabled": false, "limit_kind": "none", "limit_value": "0.000", "enforcement_mode": "enforce"}, {"feature_code": "marketplace.catalog.publish", "feature_name": "Marketplace katalog yayınlama", "enabled": true, "limit_kind": "quota", "limit_value": "10.000", "enforcement_mode": "enforce"}, {"feature_code": "marketplace.order.create", "feature_name": "Marketplace sipariş oluşturma", "enabled": true, "limit_kind": "quota", "limit_value": "2.000", "enforcement_mode": "enforce"}, {"feature_code": "panel.dashboard.view", "feature_name": "Panel dashboard görüntüleme", "enabled": true, "limit_kind": "quota", "limit_value": "1000.000", "enforcement_mode": "enforce"}, {"feature_code": "pos.sale.create", "feature_name": "POS satış oluşturma", "enabled": true, "limit_kind": "quota", "limit_value": "100.000", "enforcement_mode": "enforce"}, {"feature_code": "report.view", "feature_name": "Rapor görüntüleme", "enabled": true, "limit_kind": "quota", "limit_value": "20.000", "enforcement_mode": "enforce"}]}
```
## Summary SELECT
```
summary_audit=1
enabled_feature_count=5
```
## Feature check response
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "plan_code": "pix2pi-starter", "feature_code": "marketplace.catalog.publish", "limit_kind": "quota", "limit_value": 10.0}
```
## Quota responses
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "feature_code": "marketplace.order.create", "period_key": "2026-05", "used_amount": 1.0, "limit_value": 2.0}
{"ok": true, "tenant_id": "tenant-api-e2e-success", "feature_code": "marketplace.order.create", "period_key": "2026-05", "used_amount": 2.0, "limit_value": 2.0}
{"ok": false, "error": "quota_limit_exceeded", "current": 2.0, "amount": 1.0, "limit": 2.0}
```
## Quota SELECT
```
quota_usage_amount=2
quota_allow_audits=2
quota_exceed_audit=1
```
## Status responses
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "assignment_id": "plan-assignment-341-20260513_225505", "plan_code": "pix2pi-starter", "old_status": "active", "new_status": "suspended"}
{"ok": false, "error": "tenant_plan_suspended", "plan_code": "pix2pi-starter"}
{"ok": true, "tenant_id": "tenant-api-e2e-success", "assignment_id": "plan-assignment-341-20260513_225505", "plan_code": "pix2pi-starter", "old_status": "suspended", "new_status": "active"}
```
## Status SELECT
```
plan_active_final=1
plan_status_audits=2
suspended_guard_audit=1
```
## Cross response
```json
{"ok": false, "error": "tenant_plan_not_found"}
```
## Cross SELECT
```
tenant_b_plan_assignment=0
tenant_b_quota_usage=0
tenant_safe_deny_audit=1
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## No role SELECT
```
no_role_assignment=0
no_role_audit=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_assignment=0
rollback_audit=0
original_assignment_still_active=1
```
## Final SELECT
```
final_plan_assignment=1
final_feature_matrix=6
final_quota_usage=2
final_main_audits=7
final_negative_audits=3
final_no_rollback_assignment=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_340_MARKETPLACE_FINAL_SMOKE_COMMERCIAL_HANDOFF_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: commercial_runtime.commercial_plan_audit_events / OK ✅
table exists: commercial_runtime.plan_feature_matrix / OK ✅
table exists: commercial_runtime.plan_packages / OK ✅
table exists: commercial_runtime.tenant_plan_assignments / OK ✅
table exists: commercial_runtime.tenant_quota_usage / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx commercial plan route bind / OK ✅
commercial plan assign route reaches API 422 / OK ✅
frontend commercial plan page written / OK ✅
commercial plan seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
READINESS_STATUS plan_seeded=2 / OK ✅
READINESS_STATUS feature_matrix_count=6 / OK ✅
TENANT_PLAN_ASSIGNMENT_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS tenant_plan_assignment=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_plan_assignment_audit=1 / OK ✅
PLAN_FEATURE_MATRIX_STATUS summary HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS summary_audit=1 / OK ✅
REAL_DB_SELECT_STATUS enabled_feature_count=5 / OK ✅
PLAN_FEATURE_CHECK_STATUS allowed HTTP 200 / OK ✅
QUOTA_USE_STATUS first usage HTTP 200 / OK ✅
QUOTA_USE_STATUS second usage HTTP 200 / OK ✅
QUOTA_LIMIT_GUARD_STATUS HTTP 429 / OK ✅
REAL_DB_SELECT_STATUS quota_usage_amount=2 / OK ✅
REAL_DB_SELECT_STATUS quota_allow_audits=2 / OK ✅
REAL_DB_SELECT_STATUS quota_exceed_audit=1 / OK ✅
PLAN_SUSPEND_STATUS HTTP 200 / OK ✅
PLAN_SUSPENDED_GUARD_STATUS HTTP 403 / OK ✅
PLAN_REACTIVATE_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS plan_active_final=1 / OK ✅
REAL_DB_SELECT_STATUS plan_status_audits=2 / OK ✅
REAL_DB_SELECT_STATUS suspended_guard_audit=1 / OK ✅
TENANT_SAFE_COMMERCIAL_STATUS tenant B cannot read tenant A plan / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_plan_assignment=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_b_quota_usage=0 / OK ✅
TENANT_SAFE_DB_STATUS tenant_safe_deny_audit=1 / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
PARTIAL_WRITE_STATUS no_role_assignment=0 / OK ✅
PARTIAL_WRITE_STATUS no_role_audit=0 / OK ✅
ROLLBACK_STATUS plan assign HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_assignment=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: original_assignment_still_active=1 / OK ✅
ROUTE_SMOKE_STATUS /commercial/plans/ marker / OK ✅
FINAL_COMMERCIAL_PLAN_STATUS final_plan_assignment=1 / OK ✅
FINAL_COMMERCIAL_PLAN_STATUS final_feature_matrix=6 / OK ✅
FINAL_COMMERCIAL_PLAN_STATUS final_quota_usage=2 / OK ✅
FINAL_COMMERCIAL_PLAN_STATUS final_main_audits=7 / OK ✅
FINAL_COMMERCIAL_PLAN_STATUS final_negative_audits=3 / OK ✅
FINAL_COMMERCIAL_PLAN_STATUS final_no_rollback_assignment=0 / OK ✅
config semantic validation / OK ✅
```
