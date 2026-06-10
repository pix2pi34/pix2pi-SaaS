# FAZ 1-2.8 Cross-Tenant Security Strict Pre-Audit

- Tarih: 2026-05-04T22:16:13+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_cross_tenant_security_strict_pre_audit_20260504_221606

## Required User Scope
- API cross-tenant testleri
- DB cross-tenant testleri
- Export isolation testleri
- Event tenant mismatch testleri
- Backup/restore tenant boundary testleri

## DB Counters
- TENANT_TABLE_COUNT=108
- RLS_ENABLED_TABLE_COUNT=108
- RLS_FORCED_TABLE_COUNT=108
- ALLOW_POLICY_COUNT=108
- ENFORCE_POLICY_COUNT=108
- BYPASSRLS_ROLE_COUNT=0

## API Cross-Tenant
- API_CROSS_TENANT_CONTRACT_COUNT=7433
- API_ROUTE_CANDIDATE_COUNT=2704
- API_LIVE_BASE_URL=N/A
- API_LIVE_TEST_INPUT_READY=NO

## Export Isolation
- EXPORT_CONTRACT_COUNT=72007
- EXPORT_GUARD_COUNT=1752
- EXPORT_TEST_COUNT=67
0

## Event Tenant Mismatch
- EVENT_CONTRACT_COUNT=43296
- EVENT_MISMATCH_GUARD_COUNT=2086
- EVENT_TEST_COUNT=639

## Backup / Restore Tenant Boundary
- BACKUP_CONTRACT_COUNT=102301
- BACKUP_BOUNDARY_GUARD_COUNT=955
- BACKUP_TEST_COUNT=31
0

## Previous Evidence
- PREVIOUS_128_EVIDENCE_COUNT=3
- PREVIOUS_128_SEAL_COUNT=1

## Pre-Audit Counters
- PASS_COUNT=23
- FAIL_COUNT=0
- WARN_COUNT=3
