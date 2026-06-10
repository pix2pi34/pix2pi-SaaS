# 99 — FAZ 3-9.9 — Tax rule / tax version / tax audit tabloları

## Amaç

Bu adım, ERP Türkiye Core için vergi kuralı, vergi versiyonu, koşul ve audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.tax_rules`
2. `erp.tax_rule_versions`
3. `erp.tax_rule_conditions`
4. `erp.tax_rule_audit_events`

## Desteklenen Ana İşlevler

- Vergi kuralı master tanımı
- Vergi oranı / versiyon yönetimi
- Geçerlilik tarihi yönetimi
- Kural koşulları
- TDHP hesap kodu bağlantı hazırlığı
- e-Belge / satış / satın alma / POS kapsam ayrımı
- Vergi kuralı audit izi

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
