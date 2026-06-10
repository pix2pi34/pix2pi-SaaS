# 98 — FAZ 3-9.5 — Procurement document tabloları

## Amaç

Bu adım, ERP Türkiye Core kapanışı için satın alma süreci persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.procurement_purchase_orders`
2. `erp.procurement_purchase_order_lines`
3. `erp.procurement_receipts`
4. `erp.procurement_receipt_lines`
5. `erp.procurement_purchase_invoices`
6. `erp.procurement_purchase_invoice_lines`

## İş Akışı

Bu persistence seti şu zinciri destekler:

- Purchase Order
- Receipt
- Purchase Invoice
- Inventory bridge hazırlığı
- Journal / accounting bridge hazırlığı
- Payment / reconciliation bridge hazırlığı

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
