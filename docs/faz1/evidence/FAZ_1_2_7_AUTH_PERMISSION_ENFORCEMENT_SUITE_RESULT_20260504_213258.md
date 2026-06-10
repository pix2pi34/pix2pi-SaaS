# FAZ 1-2.7 Auth / Permission Enforcement Suite Result

- Tarih: 2026-05-04T21:33:01+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_7_auth_permission_enforcement_fix_v2_20260504_213258/suite_runtime

## DB Counters
- RBAC_TABLE_COUNT=4
- RBAC_RLS_ENABLED_COUNT=4
- RBAC_RLS_FORCED_COUNT=4
- RBAC_POLICY_COUNT=8
- RBAC_FUNCTION_COUNT=6
- RBAC_BRIDGE_FUNCTION_COUNT=3
- USER_SCOPE_FUNCTION_COUNT=4
- VERIFY_ROLE_COUNT=2

## Static Audit Counters
- ENFORCEMENT_REPO_HIT_COUNT=25249
- API_PERMISSION_GUARD_HIT_COUNT=464
- TEST_ENFORCEMENT_HIT_COUNT=233
- GATEWAY_AUTH_HIT_COUNT=18237

## Test Coverage
- permission denied before role link: tested
- permission denied before user role grant: tested
- role grant enforcement: tested
- permission grant enforcement: tested
- denied user forbidden path: tested
- user scope grant enforcement: tested
- denied user scope forbidden path: tested
- revoke removes permission: tested
- RLS tenant boundary for user_roles: tested
- RLS tenant boundary for user_scopes: tested
- rollback cleanup: tested
- static API/gateway guard traces: tested

## Final
- PASS_COUNT=20
- FAIL_COUNT=0
- WARN_COUNT=0
