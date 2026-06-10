# 102 — FAZ 3-9.7 — Ledger balance / account movement tabloları

## Amaç

Bu adım, ERP Türkiye Core için ledger posting batch, account movement, account balance, period closure ve reconciliation audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.ledger_posting_batches`
2. `erp.ledger_account_movements`
3. `erp.ledger_balances`
4. `erp.ledger_period_closures`
5. `erp.ledger_reconciliation_audit_events`

## Desteklenen Ana İşlevler

- Journal → ledger posting batch
- Account movement
- Debit / credit movement effect
- Period balance
- Period closure
- Ledger reconciliation audit
- Idempotency guard
- Journal header / line bridge
- TDHP account bridge
- Reversal movement relation

## Güvenlik

Tüm tablolarda:

- `tenant_id` zorunludur.
- Row Level Security aktiftir.
- FORCE ROW LEVEL SECURITY aktiftir.
- Tenant policy `app.tenant_id` session setting üzerinden çalışır.

## Kapanış Kuralı

Bu adım şu şartlarda PASS olur:

- 5 tablo DB metadata içinde görülmeli.
- 5 tabloda RLS enabled olmalı.
- 5 tabloda RLS forced olmalı.
- En az 5 tenant policy bulunmalı.
- PK / FK / CHECK / INDEX metadata doğrulanmalı.
- Tüm ana tablolarda `tenant_id` zorunlu olmalı.
