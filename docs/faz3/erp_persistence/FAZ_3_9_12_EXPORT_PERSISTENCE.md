# 108 — FAZ 3-9.12 — Export run / export file / validation tabloları

## Amaç

Bu adım, ERP Türkiye Core için export run, export file, export record, validation ve audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.export_runs`
2. `erp.export_files`
3. `erp.export_file_records`
4. `erp.export_validations`
5. `erp.export_audit_events`

## Desteklenen Ana İşlevler

- Logo / Mikro / Zirve / ETA export hazırlığı
- Excel / PDF / CSV / JSON / XML export
- TDHP / ledger / journal export
- Export run lifecycle
- Export file lifecycle
- Record-level export trace
- Validation result trace
- Export audit trail
- Idempotency guard

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
