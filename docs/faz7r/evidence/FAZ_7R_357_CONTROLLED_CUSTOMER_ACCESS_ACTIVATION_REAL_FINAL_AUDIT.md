# FAZ 7-R / 357 CONTROLLED CUSTOMER ACCESS ACTIVATION REAL FINAL AUDIT

- PASS_COUNT=36
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- DECISION_ID=go-live-356-20260513_074955
- ACTIVATION_ID=activation-357-20260513_075355

## GO decision SELECT
```
go-live-356-20260513_074955|GO_CONTROLLED_USAGE|true|false|true
```

## Activate response
```json
{"ok": true, "activation_id": "activation-357-20260513_075355", "decision_id": "go-live-356-20260513_074955", "tenant_id": "tenant-api-e2e-success", "access_status": "active", "access_mode": "controlled_pilot", "panel_enabled": true, "pos_enabled": true, "marketplace_enabled": false, "localization_enabled": true, "public_launch_allowed": false, "controlled_usage_allowed": true, "next_url": "/controlled-customer-access-activation/"}
```

## Activation DB SELECT
```
activation_active=1
scope_active=5
activation_audit=1
```

## Status response
```json
{"ok": true, "activation_id": "activation-357-20260513_075355", "decision_id": "go-live-356-20260513_074955", "tenant_id": "tenant-api-e2e-success", "access_status": "active", "access_mode": "controlled_pilot", "panel_enabled": true, "pos_enabled": true, "marketplace_enabled": false, "localization_enabled": true}
```

## Panel session under activation
```json
{"ok": true, "session_id": "panel-session-b19f16b6-d72e-4231-b3d8-7275cb91cf08", "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "roles": ["owner"], "next_url": "/dashboard/"}
```

## POS session under activation
```json
{"ok": true, "session_id": "pos-session-7471ae4b-f9f2-434f-b04d-1e110785416e", "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "roles": ["cashier"], "next_url": "/sale/"}
```

## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```

## Rollback SELECT
```
activation_still_active=1
rollback_deactivation_audit=0
```

## Final activation SELECT
```
activation_final=activation-357-20260513_075355|active|true|true|false|true
scope_panel=2
scope_pos=2
scope_localization=1
```

## Check log
```
dependency PASS evidence: FAZ_7R_356_CONTROLLED_USAGE_GO_LIVE_DECISION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_355_FIRST_REAL_USAGE_SMOKE_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: controlled_release.customer_access_activation_audit_events / OK ✅
table exists: controlled_release.customer_access_activation_scopes / OK ✅
table exists: controlled_release.customer_access_activations / OK ✅
table exists: controlled_release.go_live_decisions / OK ✅
GO_DECISION_STATUS latest GO_CONTROLLED_USAGE decision found / OK ✅
previous 357 activation rows cleaned / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
activation route reaches API 422 / OK ✅
activation page written / OK ✅
ACTIVATION_ROUTE_SMOKE_STATUS page marker / OK ✅
CUSTOMER_ACCESS_ACTIVATION_STATUS HTTP 201 active / OK ✅
REAL_DB_SELECT_STATUS activation_active=1 / OK ✅
REAL_DB_SELECT_STATUS scope_active >= 5 / OK ✅
REAL_DB_SELECT_STATUS activation_audit=1 / OK ✅
CUSTOMER_ACCESS_STATUS_API active panel/pos controlled / OK ✅
PANEL_ACCESS_UNDER_ACTIVATION_STATUS owner session HTTP 201 / OK ✅
POS_ACCESS_UNDER_ACTIVATION_STATUS cashier session HTTP 201 / OK ✅
ROLLBACK_STATUS deactivation simulated failure HTTP 500 / OK ✅
TRANSACTION_STATUS rollback kept activation active / OK ✅
PARTIAL_WRITE_STATUS rollback_deactivation_audit=0 / OK ✅
FINAL_ACTIVATION_STATUS active panel pos localization marketplace false / OK ✅
FINAL_SCOPE_STATUS panel=2 / OK ✅
FINAL_SCOPE_STATUS pos=2 / OK ✅
FINAL_SCOPE_STATUS localization=1 / OK ✅
config semantic validation / OK ✅
```
