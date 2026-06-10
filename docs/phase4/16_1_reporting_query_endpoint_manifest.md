# FAZ 4 / 16.1 - Reporting Query Endpoint Manifest

## Scope

Bu manifest 15 Readmodel blogunda olusan operational readmodel tablolarina okunabilir API yuzeyi tanimlar.

## Security / Tenant Rule

Tum endpointlerde zorunlu:
- Authorization: Bearer JWT
- X-Tenant-ID header
- JWT tenant claim ile X-Tenant-ID uyumu
- Tenant filtresi zorunlu
- Cross-tenant query yasak
- Super-admin bypass bu fazda yok
- Response icinde baska tenant verisi donmez

## Endpoint List

| No | Method | Path | Readmodel Source | Purpose |
|---:|---|---|---|---|
| 1 | GET | /api/v1/reporting/operational/summary | readmodel.tenant_operational_snapshot | Tenant operasyon ozet kartlari |
| 2 | GET | /api/v1/reporting/operational/daily-metrics | readmodel.daily_operational_metrics | Gunluk operasyon metrikleri |
| 3 | GET | /api/v1/reporting/inventory/status | readmodel.inventory_status_snapshot | Stok durum snapshotlari |
| 4 | GET | /api/v1/reporting/documents/work-queue | readmodel.document_work_queue | Belge is kuyrugu |
| 5 | GET | /api/v1/reporting/reconciliation/status | readmodel.reconciliation_status_snapshot | Mutabakat durum snapshotlari |
| 6 | GET | /api/v1/reporting/projections/state | readmodel.projection_state | Projection state / lag kontrolu |

## Endpoint: Operational Summary

GET /api/v1/reporting/operational/summary

Query:
- none

Response data:
- tenant_id
- legal_entity_count
- branch_count
- active_user_count
- customer_count
- vendor_count
- product_count
- open_sales_document_count
- open_purchase_document_count
- stock_alert_count
- pending_document_count
- pending_payment_count
- last_event_time
- refreshed_at

## Endpoint: Daily Metrics

GET /api/v1/reporting/operational/daily-metrics

Query:
- from_date: YYYY-MM-DD
- to_date: YYYY-MM-DD
- cursor: optional
- limit: optional, default 50, max 200

Response data:
- tenant_id
- metric_date
- sales_document_count
- sales_total
- purchase_document_count
- purchase_total
- payment_in_total
- payment_out_total
- stock_movement_count
- journal_count
- error_count
- refreshed_at

## Endpoint: Inventory Status

GET /api/v1/reporting/inventory/status

Query:
- warehouse_id: optional
- alert_only: optional boolean
- sku: optional
- cursor: optional
- limit: optional, default 50, max 200

Response data:
- tenant_id
- item_id
- warehouse_id
- sku
- item_name
- on_hand_qty
- reserved_qty
- available_qty
- min_stock_qty
- negative_stock_flag
- below_min_stock_flag
- last_movement_at
- refreshed_at

## Endpoint: Document Work Queue

GET /api/v1/reporting/documents/work-queue

Query:
- document_type: optional
- source_module: optional
- status: optional
- priority_lte: optional integer
- cursor: optional
- limit: optional, default 50, max 200

Response data:
- tenant_id
- document_type
- document_id
- source_module
- status
- priority
- due_at
- retry_count
- last_event_id
- created_at
- updated_at

## Endpoint: Reconciliation Status

GET /api/v1/reporting/reconciliation/status

Query:
- scope_type: optional
- status: optional
- currency_code: optional
- cursor: optional
- limit: optional, default 50, max 200

Response data:
- tenant_id
- scope_type
- scope_id
- status
- unreconciled_count
- difference_amount
- currency_code
- last_reconciled_at
- refreshed_at

## Endpoint: Projection State

GET /api/v1/reporting/projections/state

Query:
- projection_name: optional
- status: optional
- cursor: optional
- limit: optional, default 50, max 200

Response data:
- tenant_id
- projection_name
- projection_version
- source_stream
- last_event_id
- last_event_time
- last_sequence
- status
- error_count
- updated_at
