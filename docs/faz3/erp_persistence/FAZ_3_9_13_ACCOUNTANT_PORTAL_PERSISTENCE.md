# 109 — FAZ 3-9.13 — Muhasebeci portal / subscription / assigned-company tabloları

## Amaç

Bu adım, ERP Türkiye Core için muhasebeci portalı, abonelik, atanmış firma, kullanıcı, export yetkisi ve audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.accountant_portal_accounts`
2. `erp.accountant_portal_users`
3. `erp.accountant_portal_subscriptions`
4. `erp.accountant_portal_assigned_companies`
5. `erp.accountant_portal_company_export_permissions`
6. `erp.accountant_portal_audit_events`

## Desteklenen Ana İşlevler

- Muhasebeci portal hesabı
- Muhasebeci portal kullanıcıları
- Firma başı abonelik modeli
- Atanmış şirketler
- Assigned company tenant bridge
- Export permission matrix
- TDHP / Logo / Mikro / Zirve / ETA export izni
- Subscription lifecycle
- Portal audit trail
- Idempotency guard

## Güvenlik

Tüm tablolarda:

- `tenant_id` zorunludur.
- Row Level Security aktiftir.
- FORCE ROW LEVEL SECURITY aktiftir.
- Tenant policy `app.tenant_id` session setting üzerinden çalışır.

## Kapanış Kuralı

Bu adım şu şartlarda PASS olur:

- 6 tablo DB metadata içinde görülmeli.
- 6 tabloda RLS enabled olmalı.
- 6 tabloda RLS forced olmalı.
- En az 6 tenant policy bulunmalı.
- PK / FK / CHECK / INDEX metadata doğrulanmalı.
- Tüm ana tablolarda `tenant_id` zorunlu olmalı.
