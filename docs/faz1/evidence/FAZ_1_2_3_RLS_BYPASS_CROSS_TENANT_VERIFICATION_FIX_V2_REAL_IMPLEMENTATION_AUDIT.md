# FAZ 1-2.3 RLS Bypass / Cross-Tenant Verification FIX V2 Real Implementation Audit

- Tarih: 2026-05-04T22:08:56+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Migration file: /root/pix2pi/pix2pi-SaaS/db/migrations/faz1/20260504_220856_faz_1_2_3_rls_bypass_cross_tenant_fix_v2_security_grants.sql
- Test suite file: /root/pix2pi/pix2pi-SaaS/scripts/security/faz_1_2_3_rls_bypass_cross_tenant_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/security/FAZ_1_2_3_RLS_BASE_POLICY_SET.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_3_rls_bypass_cross_tenant_fix_v2_20260504_220856/suite_runtime
- BypassRLS role snapshot: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_3_rls_bypass_cross_tenant_fix_v2_20260504_220856/suite_runtime/bypassrls_roles_snapshot.txt

## Grant Verification
- VERIFY_ROLE_COUNT=1
- VERIFY_ROLE_BYPASSRLS_COUNT=0
- VERIFY_ROLE_AUTH_USAGE=YES
- VERIFY_ROLE_APPSEC_USAGE=YES
- VERIFY_ROLE_SECURITY_USAGE=YES
- VERIFY_ROLE_USER_ROLES_SELECT=YES
- VERIFY_ROLE_USER_SCOPES_SELECT=YES
- VERIFY_ROLE_SECURITY_EXECUTE_COUNT=8
- BYPASSRLS_ROLE_COUNT=1

## Suite Counters
- SUITE_PASS_COUNT=N/A
- SUITE_FAIL_COUNT=N/A
- SUITE_WARN_COUNT=N/A
- SUITE_STATUS=N/A
- SUITE_SEAL_STATUS=N/A

## Apply Counters
- PASS_COUNT=19
- FAIL_COUNT=4
- WARN_COUNT=1
