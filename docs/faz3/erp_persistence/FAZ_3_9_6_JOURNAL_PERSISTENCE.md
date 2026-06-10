# 101 — FAZ 3-9.6 — Journal header / journal line tabloları

## Amaç

Bu adım, ERP Türkiye Core için journal header, journal line, status history ve posting audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.journal_headers`
2. `erp.journal_lines`
3. `erp.journal_status_history`
4. `erp.journal_posting_audit_events`

## Desteklenen Ana İşlevler

- Journal header
- Journal line
- Debit / credit ayrımı
- Journal status lifecycle
- Posting status lifecycle
- Posting audit event
- Idempotency key guard
- Source event / document bridge
- Reversal journal relation hazırlığı

## Güvenlik

Tüm tablolarda:

- `tenant_id` zorunludur.
- Row Level Security aktiftir.
- FORCE ROW LEVEL SECURITY aktiftir.
- Tenant policy `app.tenant_id` session setting üzerinden çalışır.

## Kapanış Kuralı

Bu adım şu şartlarda PASS olur:

- 4 tablo DB metadata içinde görülmeli.
- 4 tabloda RLS enabled olmalı.
- 4 tabloda RLS forced olmalı.
- En az 4 tenant policy bulunmalı.
- PK / FK / CHECK / INDEX metadata doğrulanmalı.
- Tüm ana tablolarda `tenant_id` zorunlu olmalı.
