# 107 — FAZ 3-9.11 — Payment / collection / refund / reconciliation tabloları

## Amaç

Bu adım, ERP Türkiye Core için tahsilat, ödeme, iade, mahsup/allocation ve reconciliation persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.payment_methods`
2. `erp.payment_transactions`
3. `erp.collection_allocations`
4. `erp.payment_allocations`
5. `erp.refund_transactions`
6. `erp.reconciliation_runs`
7. `erp.reconciliation_items`
8. `erp.payment_audit_events`

## Desteklenen Ana İşlevler

- Payment method master
- Payment / collection transaction
- Customer collection allocation
- Vendor payment allocation
- Refund transaction
- Reconciliation run
- Reconciliation item
- Payment audit trail
- Journal / ledger bridge
- Provider / bank reference bridge
- Idempotency guard

## Güvenlik

Tüm tablolarda:

- `tenant_id` zorunludur.
- Row Level Security aktiftir.
- FORCE ROW LEVEL SECURITY aktiftir.
- Tenant policy `app.tenant_id` session setting üzerinden çalışır.

## Kapanış Kuralı

Bu adım şu şartlarda PASS olur:

- 8 tablo DB metadata içinde görülmeli.
- 8 tabloda RLS enabled olmalı.
- 8 tabloda RLS forced olmalı.
- En az 8 tenant policy bulunmalı.
- PK / FK / CHECK / INDEX metadata doğrulanmalı.
- Tüm ana tablolarda `tenant_id` zorunlu olmalı.
