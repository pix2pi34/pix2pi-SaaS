# FAZ 1-2.4 auth.user_scopes Suite Result FIX V9C

- Tarih: 2026-05-04T20:18:31+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_4_user_scopes_fix_v9c_20260504_201829/suite_runtime

## Model Counters
- USER_SCOPES_TABLE_COUNT=1
- USER_SCOPE_AUDIT_TABLE_COUNT=1
- USER_SCOPES_COLUMN_COUNT=18
- USER_SCOPE_AUDIT_COLUMN_COUNT=11
- USER_SCOPE_RLS_ENABLED_COUNT=2
- USER_SCOPE_RLS_FORCED_COUNT=2
- USER_SCOPE_POLICY_COUNT=4
- USER_SCOPE_FUNCTION_COUNT=4
- VERIFY_ROLE_COUNT=1
- LEGACY_SCOPE_LEVEL_COUNT=1
- SCOPE_LEVEL_ENUM_LABEL_COUNT=3
- TENANT_ID_FK_COUNT=1
- LEGAL_ENTITY_ID_FK_COUNT=1
- BRANCH_ID_FK_COUNT=1
- CODE_TEXT_DOMAIN_COUNT=1
- SECURITY_SCHEMA_COUNT=1
- VERIFY_ROLE_SECURITY_USAGE=YES
- VERIFY_ROLE_SECURITY_EXECUTE_COUNT=8

## Test Coverage
- Tenant scope: tested with real tenant
- Temp main auth user: created inside rollback transaction
- Temp isolated expiry auth user: created inside rollback transaction
- Temp legal entity: created with core.code_text-compatible business_code
- Temp branch: created with core.code_text-compatible business_code
- Legal entity scope: tested with FK-safe reference
- Branch scope: tested with FK-safe reference
- Accountant assigned-company scope: tested
- Scope expiration: tested with isolated user
- Scope revoke: tested
- Scope audit: tested
- RLS tenant boundary: tested
- Legacy security schema RLS dependency grant: tested
- Legacy enum scope_level compatibility: tested
- Legacy user_scopes_target_ck compatibility: tested
- Transaction rollback cleanup: tested

## Final Counters
- PASS_COUNT=24
- FAIL_COUNT=0
- WARN_COUNT=0
