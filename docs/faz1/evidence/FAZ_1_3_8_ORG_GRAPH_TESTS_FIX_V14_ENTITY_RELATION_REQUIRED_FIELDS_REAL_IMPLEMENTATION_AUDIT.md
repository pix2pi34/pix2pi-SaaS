# FAZ 1-3.8 Org Graph Tests FIX V14 Real Implementation Audit

- Tarih: 2026-05-06T16:31:14+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Strict suite file: /root/pix2pi/pix2pi-SaaS/scripts/organization/faz_1_3_8_org_graph_tests_strict_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/organization/FAZ_1_3_8_ORG_GRAPH_TESTS.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_3_8_org_graph_tests_fix_v14_20260506_163110/suite_runtime
- Graph SQL: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_3_8_org_graph_tests_fix_v14_20260506_163110/suite_runtime/org_graph_tests_suite_fix_v14.sql
- Graph output: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_3_8_org_graph_tests_fix_v14_20260506_163110/suite_runtime/org_graph_tests_suite_fix_v14.out

## Schema Awareness\n- FIX V14: org.entity_relations required legal_entity_id and visibility_scope fields are populated in schema-aware inserts.\n- FIX V14: org.entity_relations business_code uses uppercase format matching ck_org_entity_relations_business_code_format.\n- FIX V14: org.legal_entities and dependent graph business_code values are generated through live core.code_text probe.\n- FIX V14: org.entity_relations relation_type/status semantic columns are normalized away from core.code_text when needed.\n- FIX V14: PostgreSQL dollar-quote delimiters in code_text probe function are escaped for bash heredoc safety.
- ENTITY_RELATIONS_RELATION_CODE_COL_COUNT=0
- ENTITY_RELATIONS_BUSINESS_CODE_COL_COUNT=1
- ENTITY_RELATIONS_RELATION_TYPE_COL_COUNT=1
- ENTITY_RELATIONS_STATUS_COL_COUNT=1
- ENTITY_RELATIONS_VISIBILITY_RULE_COL_COUNT=0
- ENTITY_RELATIONS_AUDIT_REF_COL_COUNT=0
- ENTITY_RELATIONS_METADATA_COL_COUNT=1

## Counts
- ENTITY_RELATIONS_TABLE_COUNT=1
- ENTITY_RELATIONS_FK_COUNT=6
- ENTITY_RELATIONS_CHECK_COUNT=9
- ENTITY_RELATIONS_INDEX_COUNT=13
- ENTITY_RELATIONS_RLS_ENABLED_COUNT=1
- ENTITY_RELATIONS_RLS_FORCED_COUNT=1
- ENTITY_RELATIONS_POLICY_COUNT=4
- ENTITY_RELATIONS_CYCLE_GUARD_COUNT=1
- ENTITY_SHAREHOLDERS_TABLE_COUNT=1
- FRANCHISE_AGREEMENTS_TABLE_COUNT=1
- BUSINESS_LOCATIONS_TABLE_COUNT=1
- LOCATION_OPERATION_PROFILES_TABLE_COUNT=1
- VISIBILITY_RULES_TABLE_COUNT=1
- CROSS_COMPANY_RELATIONS_TABLE_COUNT=1
- SHAREHOLDER_OVER_100_GUARD_COUNT=4
- FRANCHISE_OVERLAP_GUARD_COUNT=1
- VISIBILITY_CROSS_BRANCH_CHECK_COUNT=2
- RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=1
- OPERATION_PROFILE_FRANCHISE_RULE_COUNT=1
- ACCOUNTANT_VISIBILITY_CHECK_COUNT=1

## Tests
- GRAPH_TEST_STATUS=PASS
- STRICT_SUITE_PASS_COUNT=26
- STRICT_SUITE_FAIL_COUNT=0
- STRICT_SUITE_WARN_COUNT=0
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED

## Apply Counters
- PASS_COUNT=50
- FAIL_COUNT=0
- WARN_COUNT=4
