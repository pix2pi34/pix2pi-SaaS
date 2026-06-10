# FAZ 1-1.4 Business Common Columns Real Implementation Audit

- Tarih: 2026-05-05T06:24:05+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Migration file: /root/pix2pi/pix2pi-SaaS/db/migrations/faz1/20260505_062403_faz_1_1_4_business_common_columns.sql
- Strict suite file: /root/pix2pi/pix2pi-SaaS/scripts/db/faz_1_1_4_business_common_columns_strict_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/db/FAZ_1_1_4_BUSINESS_COMMON_COLUMNS.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_4_business_common_columns_20260505_062403/suite_runtime

## Snapshot Files
- Business tables: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_4_business_common_columns_20260505_062403/business_table_candidates.csv
- Missing before: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_4_business_common_columns_20260505_062403/business_common_columns_missing_before.csv
- Missing after: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_4_business_common_columns_20260505_062403/business_common_columns_missing_after.csv

## Counts
- BUSINESS_TABLE_COUNT=103
- BEFORE_MISSING_COUNT=513
- AFTER_MISSING_COUNT=0
- STRICT_SUITE_PASS_COUNT=19
- STRICT_SUITE_FAIL_COUNT=0
- STRICT_SUITE_WARN_COUNT=0
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED

## Required Scope Status
- TENANT_ID_STATUS=PASS
- LEGAL_ENTITY_ID_STATUS=PASS
- BRANCH_ID_STATUS=PASS
- CREATED_AT_STATUS=PASS
- UPDATED_AT_STATUS=PASS
- CREATED_BY_STATUS=PASS
- UPDATED_BY_STATUS=PASS
- DELETED_AT_STATUS=PASS
- AUDIT_COLUMNS_STATUS=PASS

## Apply Counters
- PASS_COUNT=16
- FAIL_COUNT=0
- WARN_COUNT=3
