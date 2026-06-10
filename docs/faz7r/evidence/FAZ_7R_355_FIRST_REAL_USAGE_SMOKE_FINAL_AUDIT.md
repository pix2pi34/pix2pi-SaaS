# FAZ 7-R / 355 FIRST REAL USAGE SMOKE FINAL AUDIT

- PASS_COUNT=53
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- SMOKE_RUN_ID=smoke-355-20260513_074549

## Customer readiness DB SELECT
```
tenant_opened=1
tenant_default_language=1
owner_active=1
owner_role=1
cashier_active=1
cashier_role=1
branch_active=1
register_active=1
```

## Panel session response
```json
{"ok": true, "session_id": "panel-session-c5d88161-e4fc-4c65-afb8-2710ead67b67", "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "roles": ["owner"], "next_url": "/dashboard/"}
```

## Panel access response
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "route_path": "/dashboard/", "action_code": "panel.dashboard.view", "roles": ["owner"]}
```

## POS session response
```json
{"ok": true, "session_id": "pos-session-304dbb70-d6c5-4d58-8aa6-018e08bc6ad1", "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "roles": ["cashier"], "next_url": "/sale/"}
```

## POS access responses
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "route_path": "/sale/", "action_code": "pos.sale.create", "roles": ["cashier"]}
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "route_path": "/payment/", "action_code": "pos.payment.collect", "roles": ["cashier"]}
```

## Permission responses
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "action_code": "billing.manage", "roles": ["owner"], "reason": "owner_wildcard"}
{"ok": true, "allowed": false, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "action_code": "finance.report.view", "roles": ["cashier"], "reason": "permission_denied"}
```

## Tenant isolation responses
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "records": [{"record_id": "tenant-record-99144417-b178-48e8-9b90-adbbbf99d5c5", "record_key": "tenant-a-write-352", "record_value": "A_WRITE_OK"}, {"record_id": "record-352-tenant-a", "record_key": "tenant-a-secret", "record_value": "A_TENANT_ONLY"}]}
{"ok": false, "error": "cross_tenant_denied", "actor_tenant_id": "tenant-api-e2e-success", "target_tenant_id": "tenant-api-e2e-isolated-b"}
```

## Smoke event SELECT
```
smoke_events=8
smoke_events_pass=8
```

## Rollback SELECT
```
rollback_event=0
```

## Final smoke SELECT
```
smoke_run_final=smoke-355-20260513_074549|pass
```

## Check log
```
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_348_REAL_FINAL_V2_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_321_USER_ROLE_PERSONNEL_RBAC_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: customer_smoke.smoke_events / OK ✅
table exists: customer_smoke.smoke_runs / OK ✅
smoke run created / OK ✅
REAL_DB_SELECT_STATUS smoke_run=1 / OK ✅
CUSTOMER_READINESS_STATUS tenant_opened=1 / OK ✅
CUSTOMER_READINESS_STATUS tenant_default_language=1 / OK ✅
CUSTOMER_READINESS_STATUS owner_active=1 / OK ✅
CUSTOMER_READINESS_STATUS owner_role=1 / OK ✅
CUSTOMER_READINESS_STATUS cashier_active=1 / OK ✅
CUSTOMER_READINESS_STATUS cashier_role=1 / OK ✅
CUSTOMER_READINESS_STATUS branch_active=1 / OK ✅
CUSTOMER_READINESS_STATUS register_active=1 / OK ✅
LIVE_API_ROUTE_STATUS panel access route 422 / OK ✅
LIVE_API_ROUTE_STATUS pos access route 422 / OK ✅
LIVE_API_ROUTE_STATUS permission route 422 / OK ✅
LIVE_API_ROUTE_STATUS tenant isolation route 422 / OK ✅
CUSTOMER_PANEL_SESSION_STATUS owner session HTTP 201 / OK ✅
CUSTOMER_PANEL_ACCESS_STATUS dashboard allowed / OK ✅
CUSTOMER_POS_SESSION_STATUS cashier session HTTP 201 / OK ✅
CUSTOMER_POS_ACCESS_STATUS sale allowed / OK ✅
CUSTOMER_POS_ACCESS_STATUS payment allowed / OK ✅
CUSTOMER_PERMISSION_STATUS owner billing.manage allowed / OK ✅
CUSTOMER_PERMISSION_STATUS cashier finance denied / OK ✅
CUSTOMER_TENANT_ISOLATION_STATUS same tenant read allowed / OK ✅
CUSTOMER_TENANT_ISOLATION_STATUS cross tenant read denied / OK ✅
CUSTOMER_LOCALIZATION_STATUS runtime HTTP 200 default/font / OK ✅
CUSTOMER_LOCALE_ROUTE_STATUS tr-TR HTTP 200 JSON valid / OK ✅
CUSTOMER_LOCALE_ROUTE_STATUS ota HTTP 200 JSON valid / OK ✅
CUSTOMER_LOCALE_ROUTE_STATUS ar HTTP 200 JSON valid / OK ✅
CUSTOMER_LOCALE_ROUTE_STATUS fa HTTP 200 JSON valid / OK ✅
CUSTOMER_LOCALE_ROUTE_STATUS en HTTP 200 JSON valid / OK ✅
CUSTOMER_ROUTE_SMOKE_STATUS panel.pix2pi.com.tr/panel-access-test/ marker / OK ✅
CUSTOMER_ROUTE_SMOKE_STATUS panel.pix2pi.com.tr/tenant-isolation-check/ marker / OK ✅
CUSTOMER_ROUTE_SMOKE_STATUS panel.pix2pi.com.tr/user-permission-check/ marker / OK ✅
CUSTOMER_ROUTE_SMOKE_STATUS pos.pix2pi.com.tr/pos-access-test/ marker / OK ✅
SMOKE_AUDIT_INSERT_STATUS events inserted / OK ✅
REAL_DB_SELECT_STATUS smoke_events=8 / OK ✅
REAL_DB_SELECT_STATUS smoke_events_pass=8 / OK ✅
ROLLBACK_STATUS simulated DB failure occurred / OK ✅
TRANSACTION_STATUS rollback no partial write / OK ✅
SMOKE_RUN_FINALIZE_STATUS pass / OK ✅
REAL_DB_SELECT_STATUS smoke_run final pass / OK ✅
config semantic validation / OK ✅
```
