# FAZ 7-R / 353 USER PERMISSION REAL FINAL AUDIT

- PASS_COUNT=43
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Dependency DB verify
```
tenant_opened=1
owner_role=1
manager_role=1
cashier_role=1
accountant_role=1
no_role_count=0
```
## Owner allow
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-348-accepted", "action_code": "billing.manage", "roles": ["owner"], "reason": "owner_wildcard"}
```
## Manager allow
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-manager", "action_code": "panel.users.role_assign", "roles": ["manager"], "reason": "permission_match"}
```
## Manager deny
```json
{"ok": true, "allowed": false, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-manager", "action_code": "billing.manage", "roles": ["manager"], "reason": "permission_denied"}
```
## Cashier allow
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "action_code": "pos.sale.create", "roles": ["cashier"], "reason": "permission_match"}
```
## Cashier deny
```json
{"ok": true, "allowed": false, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "action_code": "finance.report.view", "roles": ["cashier"], "reason": "permission_denied"}
```
## Accountant allow
```json
{"ok": true, "allowed": true, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-accountant", "action_code": "finance.report.view", "roles": ["accountant"], "reason": "permission_match"}
```
## Accountant deny
```json
{"ok": true, "allowed": false, "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-accountant", "action_code": "pos.sale.create", "roles": ["accountant"], "reason": "permission_denied"}
```
## No role deny
```json
{"ok": true, "allowed": false, "tenant_id": "tenant-api-e2e-success", "user_id": "user-353-no-role", "action_code": "panel.dashboard.view", "roles": [], "reason": "no_role"}
```
## Protected allow
```json
{"ok": true, "allowed": true, "action_event_id": "protected-action-9484fd84-420b-4f1b-8441-a77536199cbf", "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-manager", "action_code": "panel.products.write", "roles": ["manager"], "status": "executed"}
```
## Protected SELECT
```
protected_product_write=1
```
## Protected deny
```json
{"ok": false, "allowed": false, "error": "forbidden", "tenant_id": "tenant-api-e2e-success", "user_id": "user-321-cashier", "action_code": "admin.settings.write", "roles": ["cashier"], "reason": "permission_denied"}
```
## Protected deny SELECT
```
cashier_admin_write=0
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_protected_action=0
rollback_permission_audit=0
```
## Permission audit SELECT
```
permission_allow=5
permission_deny=5
protected_action_executed=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_321_USER_ROLE_PERSONNEL_RBAC_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: tenant_identity.permission_check_audit_events / OK ✅
table exists: tenant_identity.protected_action_events / OK ✅
table exists: tenant_identity.role_permissions / OK ✅
table exists: tenant_identity.tenant_users / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
permission check route reaches API 422 / OK ✅
frontend written / OK ✅
test cleanup and seed completed / OK ✅
DEPENDENCY_DB_STATUS tenant_opened=1 / OK ✅
DEPENDENCY_DB_STATUS owner_role=1 / OK ✅
DEPENDENCY_DB_STATUS manager_role=1 / OK ✅
DEPENDENCY_DB_STATUS cashier_role=1 / OK ✅
DEPENDENCY_DB_STATUS accountant_role=1 / OK ✅
DEPENDENCY_DB_STATUS no_role_count=0 / OK ✅
OWNER_PERMISSION_STATUS wildcard allow billing.manage / OK ✅
MANAGER_PERMISSION_STATUS allow panel.users.role_assign / OK ✅
MANAGER_PERMISSION_STATUS deny billing.manage / OK ✅
CASHIER_PERMISSION_STATUS allow pos.sale.create / OK ✅
CASHIER_PERMISSION_STATUS deny finance.report.view / OK ✅
ACCOUNTANT_PERMISSION_STATUS allow finance.report.view / OK ✅
ACCOUNTANT_PERMISSION_STATUS deny pos.sale.create / OK ✅
NO_ROLE_DENY_STATUS no-role denied / OK ✅
PROTECTED_ACTION_STATUS manager product write executed / OK ✅
REAL_DB_SELECT_STATUS protected_product_write=1 / OK ✅
FORBIDDEN_STATUS cashier admin.settings.write denied / OK ✅
PARTIAL_WRITE_STATUS denied protected action no DB row / OK ✅
VALIDATION_ERROR_STATUS HTTP 422 / OK ✅
ROLLBACK_STATUS protected action HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_protected_action=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_permission_audit=0 / OK ✅
ROUTE_SMOKE_STATUS user-permission-check marker / OK ✅
PERMISSION_AUDIT allow count >= 5 / OK ✅
PERMISSION_AUDIT deny count >= 5 / OK ✅
PROTECTED_ACTION_AUDIT executed count 1 / OK ✅
config semantic validation / OK ✅
```
