# FAZ 7-R / 351 — POS erişim testi

## Amaç

`pos.pix2pi.com.tr/pos-access-test/` üzerinde ilk işletme kullanıcısı için kontrollü POS erişim testi yüzeyini kurar.

## Kapsam

351.1 POS access test app shell  
351.2 POS auth/session simulation context  
351.3 Tenant / store / register context  
351.4 Cashier / owner role access preview  
351.5 POS route availability checklist  
351.6 Cashier login access check  
351.7 POS sales screen access check  
351.8 Cart / payment flow access check  
351.9 Offline-ready / PWA asset access check  
351.10 Mobile viewport / touch readiness check  
351.11 Unauthorized / forbidden preview  
351.12 POS session timeout preview  
351.13 POS navigation handoff  
351.14 POS access audit timeline  
351.15 Tenant / user / store / register scope guard  
351.16 POS access runtime data contract  
351.17 i18n-ready POS access marker  
351.18 SEO / OpenGraph POS access placeholder  
351.19 POS erişim smoke test  

## Teknik karar

Bu adım gerçek POS login, gerçek satış, gerçek ödeme, gerçek offline queue, gerçek stok düşümü veya gerçek session oluşturma açmaz. POS route erişim preview, mobile/PWA readiness ve 352 tenant izolasyon kontrolü handoff kurulur.

Sonraki adım:

- 352 — Tenant izolasyon kontrolü

## Gate

PASS için:

- `pos.pix2pi.com.tr/pos-access-test/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- POS access app shell, auth/session context, tenant/store/register context, cashier/owner role preview, route checklist, cashier login/sales/cart/payment/offline/mobile checks, unauthorized/forbidden preview, session timeout preview, navigation handoff, audit timeline, POS scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
