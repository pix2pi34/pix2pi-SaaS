# 105 — FAZ 3-9.1 — Master party tabloları

## Amaç

Bu adım, ERP Türkiye Core için müşteri, tedarikçi, kişi/contact ve adres master data persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.master_parties`
2. `erp.master_customers`
3. `erp.master_vendors`
4. `erp.master_contacts`
5. `erp.master_addresses`
6. `erp.master_party_audit_events`

## Desteklenen Ana İşlevler

- Customer master
- Vendor master
- Contact master
- Address master
- Vergi no / vergi dairesi / MERSIS alanları
- Telefon / email alanları
- Customer/vendor ayrışması
- Audit trail
- Tenant-safe master data

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
