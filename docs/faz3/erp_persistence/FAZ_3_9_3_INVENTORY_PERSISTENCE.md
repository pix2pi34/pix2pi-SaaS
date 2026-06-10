# 103 — FAZ 3-9.3 — Inventory stock movement / warehouse balance tabloları

## Amaç

Bu adım, ERP Türkiye Core için stok hareketi, depo bakiyesi, rezervasyon ve balance rebuild audit persistence katmanını oluşturur.

## Kapsam

Oluşturulan tablolar:

1. `erp.inventory_movement_batches`
2. `erp.inventory_stock_movements`
3. `erp.inventory_warehouse_balances`
4. `erp.inventory_reservations`
5. `erp.inventory_balance_rebuild_audit_events`

## Desteklenen Ana İşlevler

- Stok hareket batch kayıtları
- Depo bazlı stok giriş / çıkış hareketleri
- Depo bakiyesi
- Rezervasyon
- Balance rebuild audit
- Idempotency guard
- Source document / source event bridge
- Journal / ledger bridge hazırlığı
- Lot / serial / expiry alanları

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
