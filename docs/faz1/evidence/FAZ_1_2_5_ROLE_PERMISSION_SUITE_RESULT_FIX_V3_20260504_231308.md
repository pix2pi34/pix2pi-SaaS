# FAZ 1-2.5 Role / Permission Suite Result FIX V3

- Tarih: 2026-05-04T23:13:09+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_5_role_permission_suite_fix_v3_20260504_231308

## Counters
- AUTH_ROLE_TABLE_COUNT=4
- AUTH_ROLE_COLUMN_COUNT=39
- AUTH_ROLE_RLS_ENABLED_COUNT=4
- AUTH_ROLE_RLS_FORCED_COUNT=4
- AUTH_ROLE_POLICY_COUNT=8
- AUTH_ROLE_FUNCTION_COUNT=6
- RBAC_REF_FUNCTION_COUNT=3
- VERIFY_ROLE_COUNT=1
- BRIDGE_UUID_COLUMN_COUNT=2

## Test Coverage
- role_permission link: tested
- legacy role_id/id bridge: tested
- legacy permission_id/id bridge: tested
- user role grant: tested
- user role revoke: tested
- user has role: tested
- user has permission: tested
- assert permission: tested
- negative abuse cases: tested
- RLS tenant boundary: tested
- rollback cleanup: tested

## Final
- PASS_COUNT=19
- FAIL_COUNT=0
- WARN_COUNT=0
