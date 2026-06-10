# FAZ 1-2.3 RLS Bypass / Cross-Tenant Verification FIX V3B Real Implementation Audit

- Tarih: 2026-05-04T22:13:25+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Migration file: /root/pix2pi/pix2pi-SaaS/db/migrations/faz1/20260504_221324_faz_1_2_3_rls_bypass_cross_tenant_fix_v3b_nobypassrls_and_grants.sql
- Test suite file: /root/pix2pi/pix2pi-SaaS/scripts/security/faz_1_2_3_rls_bypass_cross_tenant_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/security/FAZ_1_2_3_RLS_BASE_POLICY_SET.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_3_rls_bypass_cross_tenant_fix_v3b_20260504_221324/suite_runtime
- BYPASSRLS after: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_3_rls_bypass_cross_tenant_fix_v3b_20260504_221324/suite_runtime/bypassrls_roles_after_fix_v3b.txt

## BYPASSRLS
- BYPASSRLS_AFTER_COUNT=0
- PIX2PI_BYPASSRLS_COUNT=0

## RLS Coverage
- TENANT_TABLE_COUNT=108
- RLS_ENABLED_TABLE_COUNT=108
- RLS_FORCED_TABLE_COUNT=108
- ALLOW_POLICY_COUNT=108
- ENFORCE_POLICY_COUNT=108
- APP_SECURITY_HELPER_COUNT=3

## Verify Role
- VERIFY_ROLE_COUNT=1
- VERIFY_ROLE_BYPASSRLS_COUNT=0
- VERIFY_ROLE_AUTH_USAGE=YES
- VERIFY_ROLE_APPSEC_USAGE=YES
- VERIFY_ROLE_SECURITY_USAGE=YES
- VERIFY_ROLE_USER_ROLES_SELECT=YES
- VERIFY_ROLE_USER_SCOPES_SELECT=YES

## Suite Counters
- SUITE_PASS_COUNT=8
- SUITE_FAIL_COUNT=0
- SUITE_WARN_COUNT=0
- SUITE_STATUS=PASS
- SUITE_SEAL_STATUS=SEALED

## Apply Counters
- PASS_COUNT=31
- FAIL_COUNT=0
- WARN_COUNT=0
