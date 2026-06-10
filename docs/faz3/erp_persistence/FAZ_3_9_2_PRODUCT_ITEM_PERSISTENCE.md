# 106 — FAZ 3-9.2 — Product / item / category / unit tabloları

## Amaç

Bu adım, ERP Türkiye Core için ürün, stok kalemi, kategori, birim, barkod ve ürün audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.product_categories`
2. `erp.product_units`
3. `erp.product_items`
4. `erp.product_item_units`
5. `erp.product_barcodes`
6. `erp.product_item_audit_events`

## Desteklenen Ana İşlevler

- Product category
- Product unit
- Product item
- Unit conversion
- Barcode
- OEM / equivalent code
- Sales / purchase / inventory enable flags
- Tax rule bridge
- Account code bridge
- Product audit trail
- Tenant-safe product master data

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
