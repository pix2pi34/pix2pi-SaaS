# FAZ 7-R / 350 PANEL ACCESS REAL FINAL AUDIT

- PASS_COUNT=38
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Dependency DB verify
```
tenant_opened=1
owner_user=1
owner_role=1
cashier_user=1
cashier_role=1
```
## Session create response
```json
{"ok": true, "session_id": "panel-session-87dd8123-d259-4f0e-afec-61a33427c83a", "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "roles": ["owner"], "next_url": "/dashboard/"}
```
## Session DB SELECT
```
owner_session=1
session_audit=1
```
## Dashboard allow
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "route_path": "/dashboard/", "action_code": "panel.dashboard.view", "roles": ["owner"]}
```
## Owner users allow
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "route_path": "/users/", "action_code": "panel.users.role_assign", "roles": ["owner"]}
```
## Cashier forbidden
```json
{"ok": false, "allowed": false, "error": "forbidden", "route_path": "/users/", "action_code": "panel.users.role_assign", "roles": ["cashier"]}
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
access_allow=2
access_deny=2
```
## Check log
```
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_348_REAL_FINAL_V2_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_321_USER_ROLE_PERSONNEL_RBAC_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: tenant_identity.panel_access_audit_events / OK ✅
table exists: tenant_identity.panel_access_sessions / OK ✅
table exists: tenant_identity.role_permissions / OK ✅
table exists: tenant_identity.tenant_users / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
session-create route reaches API 422 / OK ✅
frontend written / OK ✅
test cleanup completed / OK ✅
DEPENDENCY_DB_STATUS tenant_opened=1 / OK ✅
DEPENDENCY_DB_STATUS owner_user=1 / OK ✅
DEPENDENCY_DB_STATUS owner_role=1 / OK ✅
DEPENDENCY_DB_STATUS cashier_user=1 / OK ✅
DEPENDENCY_DB_STATUS cashier_role=1 / OK ✅
REAL_SESSION_CREATE_STATUS owner HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS owner_session=1 / OK ✅
REAL_DB_SELECT_STATUS session_audit=1 / OK ✅
350.3 dashboard access allowed / OK ✅
350.6 users admin access allowed for owner / OK ✅
cashier session create HTTP 201 / OK ✅
FORBIDDEN_STATUS cashier denied users role assign / OK ✅
SESSION_INVALID_STATUS missing session HTTP 401 / OK ✅
SESSION_INVALID_STATUS expired session HTTP 401 / OK ✅
ROLLBACK_STATUS session create HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_session=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /panel-access-test/ marker / OK ✅
ROUTE_SMOKE_STATUS /user-invite/ marker / OK ✅
ROUTE_SMOKE_STATUS /users/ marker / OK ✅
PANEL_ACCESS_AUDIT allow count 2 / OK ✅
PANEL_ACCESS_AUDIT deny count 2 / OK ✅
config semantic validation / OK ✅
```
