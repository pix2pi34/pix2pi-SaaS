# FAZ 7-R / 321 USER ROLE PERSONNEL RBAC FINAL AUDIT

- PASS_COUNT=41
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## User list response
```json
{"ok": true, "users": [{"user_id": "user-321-accountant", "email": "accountant321@example.com", "display_name": "321 Muhasebeci Test", "status": "active"}, {"user_id": "user-321-cashier", "email": "cashier321@example.com", "display_name": "321 Kasiyer Test", "status": "active"}, {"user_id": "user-321-manager", "email": "manager321@example.com", "display_name": "321 Yönetici Test", "status": "active"}, {"user_id": "user-321-rollback", "email": "rollback321@example.com", "display_name": "321 Rollback Test", "status": "active"}, {"user_id": "user-348-accepted", "email": "surucukursu58@gmail.com", "display_name": "Test Davet Kullanıcısı", "status": "active"}]}
```
## Role assignment DB SELECT
```
cashier_role=1
manager_role=1
accountant_role=1
cashier_profile=1
manager_profile=1
accountant_profile=1
role_audit=3
```
## RBAC cashier allow
```json
{"ok": true, "allowed": true, "action_code": "pos.sale.create"}
```
## RBAC cashier deny
```json
{"ok": false, "allowed": false, "error": "forbidden", "action_code": "finance.report.view", "roles": ["cashier"]}
```
## RBAC manager allow
```json
{"ok": true, "allowed": true, "action_code": "panel.users.invite"}
```
## RBAC manager deny
```json
{"ok": false, "allowed": false, "error": "forbidden", "action_code": "billing.manage", "roles": ["manager"]}
```
## RBAC accountant allow
```json
{"ok": true, "allowed": true, "action_code": "finance.report.view"}
```
## RBAC accountant deny
```json
{"ok": false, "allowed": false, "error": "forbidden", "action_code": "pos.sale.create", "roles": ["accountant"]}
```
## RBAC audit SELECT
```
rbac_allow=3
rbac_deny=3
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback DB SELECT
```
rollback_role=0
rollback_profile=0
rollback_audit=0
```
## Check log
```
321.2 dependency evidence 348 invite final PASS / OK ✅
321.2 live user invite API reaches real 348 API / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: tenant_identity.personnel_profiles / OK ✅
table exists: tenant_identity.rbac_audit_events / OK ✅
table exists: tenant_identity.role_permissions / OK ✅
table exists: tenant_identity.tenant_users / OK ✅
RBAC permission seed count >= 10 / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
role assign route reaches API 422 / OK ✅
frontend written / OK ✅
test data cleanup and users seeded / OK ✅
321.1 user list API HTTP 200 / OK ✅
321.5 cashier role assign HTTP 201 / OK ✅
321.6 manager role assign HTTP 201 / OK ✅
321.7 accountant role assign HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS cashier_role=1 / OK ✅
REAL_DB_SELECT_STATUS manager_role=1 / OK ✅
REAL_DB_SELECT_STATUS accountant_role=1 / OK ✅
REAL_DB_SELECT_STATUS cashier_profile=1 / OK ✅
REAL_DB_SELECT_STATUS manager_profile=1 / OK ✅
REAL_DB_SELECT_STATUS accountant_profile=1 / OK ✅
REAL_DB_SELECT_STATUS role_audit=3 / OK ✅
321.5 cashier allowed pos.sale.create / OK ✅
321.5 cashier denied finance.report.view / OK ✅
321.6 manager allowed panel.users.invite / OK ✅
321.6 manager denied billing.manage / OK ✅
321.7 accountant allowed finance.report.view / OK ✅
321.7 accountant denied pos.sale.create / OK ✅
RBAC audit allow count 3 / OK ✅
RBAC audit deny count 3 / OK ✅
VALIDATION_ERROR_STATUS unsupported role HTTP 422 / OK ✅
NOT_FOUND_STATUS missing user HTTP 404 / OK ✅
ROLLBACK_STATUS role assign HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_role=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_profile=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
config semantic validation / OK ✅
```
