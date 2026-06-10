# FAZ 1-3.3 franchise.agreements FIX V4 Real Implementation Audit

- Tarih: 2026-05-06T08:13:22+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Migration file: /root/pix2pi/pix2pi-SaaS/db/migrations/faz1/20260506_081318_faz_1_3_3_franchise_agreements_fix_v4_legacy_date_bridge.sql
- Strict suite file: /root/pix2pi/pix2pi-SaaS/scripts/organization/faz_1_3_3_franchise_agreements_strict_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/organization/FAZ_1_3_3_FRANCHISE_AGREEMENTS.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_3_3_franchise_agreements_fix_v4_20260506_081318/suite_runtime
- Agreement SQL: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_3_3_franchise_agreements_fix_v4_20260506_081318/suite_runtime/franchise_agreements_lifecycle_abuse_suite_fix_v4.sql
- Agreement output: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_3_3_franchise_agreements_fix_v4_20260506_081318/suite_runtime/franchise_agreements_lifecycle_abuse_suite_fix_v4.out

## Counts
- AGREEMENT_STATUS_TYPE=core.record_status
- AGREEMENT_GENERIC_STATUS_VALUE=active
- LEGACY_AGREEMENT_CODE_COLUMN_COUNT=1
- LEGACY_STARTS_ON_COLUMN_COUNT=1
- LEGACY_ENDS_ON_COLUMN_COUNT=1
- LEGACY_TERMINATED_ON_COLUMN_COUNT=0
- LEGACY_SYNC_FUNCTION_COUNT=1
- LEGACY_SYNC_TRIGGER_COUNT=1
- FRANCHISE_SCHEMA_COUNT=1
- AGREEMENT_TABLE_COUNT=1
- AGREEMENT_COLUMN_COUNT=29
- AGREEMENT_FK_COUNT=9
- AGREEMENT_CHECK_COUNT=9
- AGREEMENT_INDEX_COUNT=16
- AGREEMENT_RLS_ENABLED_COUNT=1
- AGREEMENT_RLS_FORCED_COUNT=1
- AGREEMENT_POLICY_COUNT=4
- OVERLAP_FUNCTION_COUNT=1
- OVERLAP_TRIGGER_COUNT=1
- UPDATED_AT_TRIGGER_COUNT=1
- AGREEMENT_AUDIT_COLUMN_COUNT=3
- AGREEMENT_LIFECYCLE_COLUMN_COUNT=1
- AGREEMENT_DICTIONARY_COUNT=1
- AGREEMENT_TEST_STATUS=PASS
- STRICT_SUITE_PASS_COUNT=21
- STRICT_SUITE_FAIL_COUNT=0
- STRICT_SUITE_WARN_COUNT=0
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED

## Apply Counters
- PASS_COUNT=43
- FAIL_COUNT=0
- WARN_COUNT=3
