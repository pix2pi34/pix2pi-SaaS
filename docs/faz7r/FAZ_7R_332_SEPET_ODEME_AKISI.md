# FAZ 7-R / 332 — Sepet / ödeme akışı

## Amaç

`pos.pix2pi.com.tr/checkout/` üzerinde POS sepet ve ödeme hazırlık yüzeyini kurar.

## Kapsam

332.1 Checkout app shell  
332.2 Sepet review / line summary  
332.3 Ödeme yöntemi seçimi  
332.4 Nakit / kart / QR ödeme placeholder  
332.5 Alınan tutar / para üstü hesap contract  
332.6 Receipt / sale completion draft payload  
332.7 Payment provider live disabled gate  
332.8 Gerçek satış finalizasyonu kapalı guard  
332.9 Tenant / device / cashier scoped payment guard  
332.10 Offline payment queue placeholder  
332.11 Checkout session storage contract  
332.12 i18n-ready checkout marker  
332.13 Checkout smoke test  

## Teknik karar

Bu adım gerçek ödeme tahsilatı, gerçek payment provider, gerçek fiş kesme, stok düşümü veya sale finalize işlemi açmaz. Checkout UI, runtime adapter, ödeme draft contract, tenant/device/cashier guard, payment provider kapalı gate ve smoke test kurulur.

Sonraki adım:

- 333 — Offline-ready POS hazırlığı

Backend endpoint sözleşmesi:

- Checkout draft: `/api/pos/checkout/draft`
- Payment prepare: `/api/pos/payments/prepare`
- Receipt draft: `/api/pos/receipts/draft`
- Tenant header: `X-Tenant-ID`
- Device header: `X-POS-Device-ID`
- Cashier header: `X-POS-Cashier-Code`

## Gate

PASS için:

- `/checkout/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Checkout shell, sepet review, ödeme yöntemi, nakit/kart/QR placeholder, para üstü hesap, receipt draft, provider disabled gate, finalize disabled guard, tenant/device/cashier guard, offline queue placeholder, session storage ve i18n marker'ları bulunmalı.
