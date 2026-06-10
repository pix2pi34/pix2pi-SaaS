# FAZ 1-2.8 Cross-Tenant Security Test Set Suite Result

- Tarih: 2026-05-04T18:52:38+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_cross_tenant_security_test_set_fix_v2_20260504_185234/suite_runtime

## DB/RLS Counters

- TENANT_TABLE_COUNT=100
- RLS_ENABLED_TABLE_COUNT=100
- RLS_FORCED_TABLE_COUNT=100
- ALLOW_POLICY_COUNT=100
- ENFORCE_POLICY_COUNT=100
- HELPER_FUNCTION_COUNT=3

## Contract Hit Counters

- API_TENANT_CONTRACT_COUNT=10647
- API_AUTH_GUARD_COUNT=8827
- EXPORT_CONTRACT_COUNT=71988
- EVENT_CONTRACT_COUNT=36462
- BACKUP_CONTRACT_COUNT=112233

## Test Coverage

- API cross-tenant boundary: implemented via API contract audit + API request RLS boundary table + optional live smoke
- DB cross-tenant boundary: implemented via non-owner RLS role select/insert/update/delete tests
- Export isolation: implemented via tenant-scoped export payload test
- Event tenant mismatch: implemented via mismatch guard function test
- Backup/restore tenant boundary: implemented via tenant-scoped backup payload test
- No tenant context boundary: implemented via zero-visible-row assertion

## Final Counters

- PASS_COUNT=20
- FAIL_COUNT=0
- WARN_COUNT=0
