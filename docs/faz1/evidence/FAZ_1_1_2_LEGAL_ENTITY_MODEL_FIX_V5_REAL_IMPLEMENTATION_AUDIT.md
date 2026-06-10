# FAZ 1-1.2 Legal Entity Model FIX V5 Real Implementation Audit

- Tarih: 2026-05-05T07:21:59+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Strict suite file: /root/pix2pi/pix2pi-SaaS/scripts/db/faz_1_1_2_legal_entity_model_strict_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/db/FAZ_1_1_2_LEGAL_ENTITY_MODEL.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_2_legal_entity_model_fix_v5_20260505_072157/suite_runtime
- Lifecycle SQL: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_2_legal_entity_model_fix_v5_20260505_072157/suite_runtime/legal_entity_lifecycle_abuse_suite_fix_v5.sql
- Lifecycle output: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_2_legal_entity_model_fix_v5_20260505_072157/suite_runtime/legal_entity_lifecycle_abuse_suite_fix_v5.out

## Type-aware status / tenant FK
- LEGAL_ENTITY_STATUS_VALUE=active
- LEGAL_ENTITY_ADDRESS_STATUS_VALUE=ACTIVE
- LEGAL_ENTITY_STATUS_TYPE=core.record_status
- LEGAL_ENTITY_ADDRESS_STATUS_TYPE=text
- TENANT_REF_TABLE=platform.tenants
- TENANT_REF_COL=id
- REAL_TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439

## Counts
- LEGAL_ENTITY_TABLE_COUNT=1
- LEGAL_ENTITY_ADDRESS_TABLE_COUNT=1
- LEGAL_ENTITY_COLUMN_COUNT=25
- LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=20
- LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=4
- LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=4
- LEGAL_ENTITY_INDEX_COUNT=6
- LEGAL_ENTITY_ADDRESS_INDEX_COUNT=4
- LEGAL_ENTITY_RLS_ENABLED_COUNT=2
- LEGAL_ENTITY_RLS_FORCED_COUNT=2
- LEGAL_ENTITY_POLICY_COUNT=5
- LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=2
- STRICT_SUITE_PASS_COUNT=18
- STRICT_SUITE_FAIL_COUNT=0
- STRICT_SUITE_WARN_COUNT=0
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED

## Required Scope Status
- COMPANY_MODEL_STATUS=PASS
- TAX_INFO_STATUS=PASS
- TRADE_TITLE_STATUS=PASS
- ADDRESS_LINK_STATUS=PASS
- TENANT_RELATION_STATUS=PASS
- LEGAL_ENTITY_TEST_STATUS=PASS

## Apply Counters
- PASS_COUNT=32
- FAIL_COUNT=0
- WARN_COUNT=2
