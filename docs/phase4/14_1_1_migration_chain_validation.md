# FAZ 4 / 14.1.1 - Migration Chain Validation

Generated at: 2026-04-27 18:07:16 +0300

## Summary

ROOT_DIR=.
ACTIVE_MIGRATION_DIR=./db/migrations
ACTIVE_MIGRATION_SQL_COUNT=46
FAIL_COUNT=0
WARN_COUNT=46
MIGRATION_CHAIN_VALIDATION=PASS

## Style Status

STYLE_WARN ⚠️ 001_phase1_foundation.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 001_phase1_foundation.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 002_phase2_db_l4_service_registry.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 002_phase2_db_l4_service_registry.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 003_phase2_db_l4_mission_control.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 003_phase2_db_l4_mission_control.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 004_phase2_db_l4_jobs_queue.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 004_phase2_db_l4_jobs_queue.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 005_phase2_db_l4_idempotency.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 005_phase2_db_l4_idempotency.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 006_phase2_db_l4_notifications.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 006_phase2_db_l4_notifications.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 007_phase2_db_l4_webhooks.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 007_phase2_db_l4_webhooks.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 008_phase2_db_l4_workflows.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 008_phase2_db_l4_workflows.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 009_phase2_db_l4_api_keys.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 009_phase2_db_l4_api_keys.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 010_phase2_db_l4_plugins.down.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 010_phase2_db_l4_plugins.up.sql -> LEGACY_SEQUENCE
STYLE_WARN ⚠️ 20260425_090101_erp_master_party.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_090101_erp_master_party.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_0910001_erp_cashbank.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_0910001_erp_cashbank.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_092001_erp_product_catalog.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_092001_erp_product_catalog.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_093001_erp_inventory.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_093001_erp_inventory.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_094001_erp_sales_documents.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_094001_erp_sales_documents.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_095001_erp_procurement_documents.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_095001_erp_procurement_documents.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_096001_erp_journal.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_096001_erp_journal.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_097001_erp_ledger.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_097001_erp_ledger.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_098001_erp_chart_of_accounts.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_098001_erp_chart_of_accounts.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_099001_erp_tax.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260425_099001_erp_tax.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260426_0911001_erp_fiscal_sequence.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260426_0911001_erp_fiscal_sequence.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260426_111001_erp_runtime_e2e_flow.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260426_111001_erp_runtime_e2e_flow.up.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260427_151001_readmodel_operational_tables.down.sql -> LEGACY_SPLIT_TIMESTAMP
STYLE_WARN ⚠️ 20260427_151001_readmodel_operational_tables.up.sql -> LEGACY_SPLIT_TIMESTAMP

## Pair Status

PAIR_OK ✅ 001_phase1_foundation.up.sql
PAIR_OK ✅ 002_phase2_db_l4_service_registry.up.sql
PAIR_OK ✅ 003_phase2_db_l4_mission_control.up.sql
PAIR_OK ✅ 004_phase2_db_l4_jobs_queue.up.sql
PAIR_OK ✅ 005_phase2_db_l4_idempotency.up.sql
PAIR_OK ✅ 006_phase2_db_l4_notifications.up.sql
PAIR_OK ✅ 007_phase2_db_l4_webhooks.up.sql
PAIR_OK ✅ 008_phase2_db_l4_workflows.up.sql
PAIR_OK ✅ 009_phase2_db_l4_api_keys.up.sql
PAIR_OK ✅ 010_phase2_db_l4_plugins.up.sql
PAIR_OK ✅ 20260425_090101_erp_master_party.up.sql
PAIR_OK ✅ 20260425_0910001_erp_cashbank.up.sql
PAIR_OK ✅ 20260425_092001_erp_product_catalog.up.sql
PAIR_OK ✅ 20260425_093001_erp_inventory.up.sql
PAIR_OK ✅ 20260425_094001_erp_sales_documents.up.sql
PAIR_OK ✅ 20260425_095001_erp_procurement_documents.up.sql
PAIR_OK ✅ 20260425_096001_erp_journal.up.sql
PAIR_OK ✅ 20260425_097001_erp_ledger.up.sql
PAIR_OK ✅ 20260425_098001_erp_chart_of_accounts.up.sql
PAIR_OK ✅ 20260425_099001_erp_tax.up.sql
PAIR_OK ✅ 20260426_0911001_erp_fiscal_sequence.up.sql
PAIR_OK ✅ 20260426_111001_erp_runtime_e2e_flow.up.sql
PAIR_OK ✅ 20260427_151001_readmodel_operational_tables.up.sql

## Bad Files / Errors
OK ✅ hata yok
