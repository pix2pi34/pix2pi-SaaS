# 100 — FAZ 3-9.8 — TDHP chart / account mapping / version tabloları

## Amaç

Bu adım, ERP Türkiye Core için TDHP hesap planı, hesap planı versiyonları, hesaplar, mapping setleri, mapping versiyonları ve mapping rule tablolarını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.tdhp_charts`
2. `erp.tdhp_chart_versions`
3. `erp.tdhp_accounts`
4. `erp.account_mapping_sets`
5. `erp.account_mapping_versions`
6. `erp.account_mapping_rules`

## Desteklenen Ana İşlevler

- TDHP chart master
- TDHP chart version
- TDHP account listesi
- Sales / procurement / inventory / payment / e-Belge / POS mapping setleri
- Mapping version yönetimi
- Debit / credit / tax account mapping rule kayıtları

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
