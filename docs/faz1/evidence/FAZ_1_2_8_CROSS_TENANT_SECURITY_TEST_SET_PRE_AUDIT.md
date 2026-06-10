# FAZ 1-2.8 Cross-Tenant Security Test Set Pre-Audit

- Tarih: 2026-05-04T18:48:26+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_cross_tenant_security_pre_audit_20260504_184820
- DB_STATUS=PASS

## Scope

- API cross-tenant testleri
- DB cross-tenant testleri
- Export isolation testleri
- Event tenant mismatch testleri
- Backup/restore tenant boundary testleri

## Evidence Files

- cross_tenant_related_repo_hits.txt
- test_file_manifest.txt
- security_test_file_candidates.txt
- runtime_file_manifest.txt
- api_gateway_candidates.txt
- export_event_backup_candidates.txt
- tenant_table_rls_status.csv
- tenant_rls_policy_status.csv

## DB Counters

- TENANT_TABLE_COUNT=100
- RLS_ENABLED_TABLE_COUNT=100
- RLS_FORCED_TABLE_COUNT=100
- ALLOW_POLICY_COUNT=100
- ENFORCE_POLICY_COUNT=100
- HELPER_FUNCTION_COUNT=3

## Final Counters

- PASS_COUNT=14
- FAIL_COUNT=0
- WARN_COUNT=0
