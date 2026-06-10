-- FAZ 4 / 15.1 - Operational readmodel tables rollback
-- Drops only the objects created by the matching up migration.

DROP INDEX IF EXISTS readmodel.idx_reconciliation_status_snapshot_status;
DROP INDEX IF EXISTS readmodel.idx_document_work_queue_source_module;
DROP INDEX IF EXISTS readmodel.idx_document_work_queue_status_priority;
DROP INDEX IF EXISTS readmodel.idx_inventory_status_alerts;
DROP INDEX IF EXISTS readmodel.idx_daily_operational_metrics_date;
DROP INDEX IF EXISTS readmodel.idx_tenant_operational_snapshot_refreshed;
DROP INDEX IF EXISTS readmodel.idx_projection_state_status;

DROP TABLE IF EXISTS readmodel.reconciliation_status_snapshot;
DROP TABLE IF EXISTS readmodel.document_work_queue;
DROP TABLE IF EXISTS readmodel.inventory_status_snapshot;
DROP TABLE IF EXISTS readmodel.daily_operational_metrics;
DROP TABLE IF EXISTS readmodel.tenant_operational_snapshot;
DROP TABLE IF EXISTS readmodel.projection_state;

DROP SCHEMA IF EXISTS readmodel;
