# 97 — FAZ 3-9.10 — e-Belge document / status / retry / cancel tabloları

## Amaç

Bu adım, ERP Türkiye Core kapanışı için e-Belge persistence temelini oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.e_belge_documents`
2. `erp.e_belge_status_history`
3. `erp.e_belge_retry_queue`
4. `erp.e_belge_cancel_requests`
5. `erp.e_belge_provider_payloads`

## Güvenlik

Tüm tablolarda:

- `tenant_id` zorunludur.
- Row Level Security aktiftir.
- FORCE ROW LEVEL SECURITY aktiftir.
- Tenant policy `app.tenant_id` session setting üzerinden çalışır.

## Kapanış Kuralı

Bu adım şu şartlarda PASS olur:

- Migration dosyası yazılmış olmalı.
- Rollback dosyası yazılmış olmalı.
- Migration gerçek PostgreSQL üzerinde uygulanmalı.
- 5 tablo DB metadata içinde görülmeli.
- 5 tabloda RLS enabled olmalı.
- 5 tabloda RLS forced olmalı.
- En az 5 tenant policy bulunmalı.
- FK/index/check constraint metadata doğrulanmalı.
