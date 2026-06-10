# 104 — FAZ 3-9.4 — Sales document tabloları

## Amaç

Bu adım, ERP Türkiye Core için satış belge zinciri persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.sales_quotations`
2. `erp.sales_quotation_lines`
3. `erp.sales_orders`
4. `erp.sales_order_lines`
5. `erp.sales_deliveries`
6. `erp.sales_delivery_lines`
7. `erp.sales_invoices`
8. `erp.sales_invoice_lines`

## İş Akışı

Bu persistence seti şu zinciri destekler:

- Quotation
- Order
- Delivery
- Invoice
- Inventory bridge
- Journal / ledger bridge
- e-Belge bridge
- Payment / collection bridge hazırlığı

## Güvenlik

Tüm tablolarda:

- `tenant_id` zorunludur.
- Row Level Security aktiftir.
- FORCE ROW LEVEL SECURITY aktiftir.
- Tenant policy `app.tenant_id` session setting üzerinden çalışır.

## Kapanış Kuralı

Bu adım şu şartlarda PASS olur:

- 8 tablo DB metadata içinde görülmeli.
- 8 tabloda RLS enabled olmalı.
- 8 tabloda RLS forced olmalı.
- En az 8 tenant policy bulunmalı.
- PK / FK / CHECK / INDEX metadata doğrulanmalı.
- Tüm ana tablolarda `tenant_id` zorunlu olmalı.
