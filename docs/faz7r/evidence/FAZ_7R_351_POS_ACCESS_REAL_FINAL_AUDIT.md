# FAZ 7-R / 351 POS ACCESS REAL FINAL AUDIT

- PASS_COUNT=38
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Dependency DB verify
```
tenant_opened=1
branch_active=1
register_active=1
cashier_user=1
cashier_role=1
accountant_role=1
```
## POS session create response
```json
{"ok": true, "session_id": "pos-session-25aa1ec5-fd67-4780-856c-8d0e928f6703", "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "roles": ["cashier"], "next_url": "/sale/"}
```
## POS session DB SELECT
```
cashier_pos_session=1
session_audit=1
```
## POS access responses
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "route_path": "/pos/", "action_code": "pos.access", "roles": ["cashier"]}
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "route_path": "/sale/", "action_code": "pos.sale.create", "roles": ["cashier"]}
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "route_path": "/cart/", "action_code": "pos.cart.write", "roles": ["cashier"]}
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "store_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "route_path": "/payment/", "action_code": "pos.payment.collect", "roles": ["cashier"]}```
## Accountant POS session/deny
```json
{"ok": false, "error": "pos_access_forbidden", "roles": ["accountant"]}

```
## Invalid register
```json
{"ok": false, "error": "register_not_active"}
```
## Missing session
```json
{"ok": false, "error": "session_not_found"}
```
## Expired session
```json
{"ok": false, "error": "session_invalid"}
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback DB SELECT
```
rollback_session=0
rollback_audit=0
```
## Access audit SELECT
```
pos_access_allow=4
pos_access_deny=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_348_REAL_FINAL_V2_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_321_USER_ROLE_PERSONNEL_RBAC_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: pos_runtime.pos_access_audit_events / OK ✅
table exists: pos_runtime.pos_access_sessions / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
pos session-create route reaches API 422 / OK ✅
frontend written / OK ✅
test cleanup completed / OK ✅
DEPENDENCY_DB_STATUS tenant_opened=1 / OK ✅
DEPENDENCY_DB_STATUS branch_active=1 / OK ✅
DEPENDENCY_DB_STATUS register_active=1 / OK ✅
DEPENDENCY_DB_STATUS cashier_user=1 / OK ✅
DEPENDENCY_DB_STATUS cashier_role=1 / OK ✅
DEPENDENCY_DB_STATUS accountant_role=1 / OK ✅
REAL_POS_SESSION_CREATE_STATUS cashier HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS cashier_pos_session=1 / OK ✅
REAL_DB_SELECT_STATUS session_audit=1 / OK ✅
351.1 POS access allowed / OK ✅
351.2 POS sale create allowed / OK ✅
351.3 POS cart write allowed / OK ✅
351.4 POS payment collect allowed / OK ✅
FORBIDDEN_STATUS accountant POS session denied / OK ✅
REGISTER_INVALID_STATUS missing register HTTP 404 / OK ✅
SESSION_INVALID_STATUS missing POS session HTTP 401 / OK ✅
SESSION_INVALID_STATUS expired POS session HTTP 401 / OK ✅
ROLLBACK_STATUS POS session create HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_session=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /pos-access-test/ marker / OK ✅
POS_ACCESS_AUDIT allow count 4 / OK ✅
POS_ACCESS_AUDIT deny count >= 1 / OK ✅
config semantic validation / OK ✅
```
