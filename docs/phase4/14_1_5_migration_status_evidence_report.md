# FAZ 4 / 14.1.5 - Migration Status Evidence Report

Generated at: 2026-04-27 07:56:51 +0300

## Summary
ROOT_DIR=.
ENV_FILE=./.env
MIGRATION_DIR=db/migrations
DB_DSN_STATUS=CONFIGURED
DB_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
LOCAL_UP_MIGRATION_COUNT=22
LOCAL_LATEST_VERSION=20260426
DB_CONNECTION_CHECK=PASS
PG_IS_IN_RECOVERY=f
DB_ROLE=PRIMARY_WRITE
SCHEMA_MIGRATIONS_EXISTS=t
SCHEMA_MIGRATIONS_HAS_VERSION_COLUMN=t
SCHEMA_MIGRATIONS_HAS_DIRTY_COLUMN=t
SCHEMA_MIGRATIONS_ROW_COUNT=1
DB_CURRENT_VERSION=2
SCHEMA_MIGRATIONS_DIRTY_STATE=f
FAIL_COUNT=0
WARN_COUNT=0
MIGRATION_STATUS_EVIDENCE=PASS

## Local Up Migrations
001 | 001_phase1_foundation.up.sql
002 | 002_phase2_db_l4_service_registry.up.sql
003 | 003_phase2_db_l4_mission_control.up.sql
004 | 004_phase2_db_l4_jobs_queue.up.sql
005 | 005_phase2_db_l4_idempotency.up.sql
006 | 006_phase2_db_l4_notifications.up.sql
007 | 007_phase2_db_l4_webhooks.up.sql
008 | 008_phase2_db_l4_workflows.up.sql
009 | 009_phase2_db_l4_api_keys.up.sql
010 | 010_phase2_db_l4_plugins.up.sql
20260425 | 20260425_090101_erp_master_party.up.sql
20260425 | 20260425_0910001_erp_cashbank.up.sql
20260425 | 20260425_092001_erp_product_catalog.up.sql
20260425 | 20260425_093001_erp_inventory.up.sql
20260425 | 20260425_094001_erp_sales_documents.up.sql
20260425 | 20260425_095001_erp_procurement_documents.up.sql
20260425 | 20260425_096001_erp_journal.up.sql
20260425 | 20260425_097001_erp_ledger.up.sql
20260425 | 20260425_098001_erp_chart_of_accounts.up.sql
20260425 | 20260425_099001_erp_tax.up.sql
20260426 | 20260426_0911001_erp_fiscal_sequence.up.sql
20260426 | 20260426_111001_erp_runtime_e2e_flow.up.sql

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
PASSWORD_MASKING=ENABLED
