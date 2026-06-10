# FAZ 7-R / 333 — Offline-ready POS hazırlığı

## Amaç

`pos.pix2pi.com.tr/offline/` üzerinde POS offline hazırlık yüzeyini ve runtime contract yapısını kurar.

## Kapsam

333.1 Offline-ready POS app shell  
333.2 Network status indicator  
333.3 Local offline queue storage contract  
333.4 Offline sale draft queue  
333.5 Idempotency key generation  
333.6 Sync / replay policy placeholder  
333.7 Conflict resolution preview  
333.8 Queue retention / clear guard  
333.9 Tenant / device / cashier scoped offline guard  
333.10 Service worker / PWA handoff placeholder  
333.11 Offline runtime health contract  
333.12 i18n-ready offline marker  
333.13 Offline-ready POS smoke test  

## Teknik karar

Bu adım gerçek offline satış replay, gerçek stok düşümü, gerçek ödeme finalize veya production sync açmaz. Offline queue contract, idempotency, tenant/device/cashier guard, conflict policy ve smoke gate kurulur.

Mobile PWA yüzeyi bir sonraki adımda genişletilir:

- 334 — Mobile-ready PWA yüzeyi

Backend endpoint sözleşmesi:

- Offline queue sync: `/api/pos/offline/sync`
- Offline replay status: `/api/pos/offline/replay-status`
- Tenant header: `X-Tenant-ID`
- Device header: `X-POS-Device-ID`
- Cashier header: `X-POS-Cashier-Code`

## Gate

PASS için:

- `/offline/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Offline shell, network status, local queue, idempotency, sync/replay, conflict, retention, tenant/device/cashier guard, service worker handoff, runtime health ve i18n marker'ları bulunmalı.
