# FAZ 7-R / 355 — İlk gerçek kullanım smoke testi

## Amaç

`panel.pix2pi.com.tr/first-real-usage-smoke/` üzerinde controlled customer access öncesi ilk gerçek kullanım zincirini tek müşteri senaryosu olarak smoke etmek.

## Kapsam

355.1 First real usage smoke app shell  
355.2 Pilot tenant / owner / store / register scenario context  
355.3 Panel login + access chain smoke  
355.4 Tenant isolation gate smoke  
355.5 User permission gate smoke  
355.6 Localization customer smoke dependency check  
355.7 POS access chain smoke  
355.8 Marketplace/storefront availability smoke  
355.9 Product / stock read smoke  
355.10 Cart / payment dry-run smoke  
355.11 Invoice / billing disabled gate smoke  
355.12 Audit / correlation timeline  
355.13 Data mutation disabled safety guard  
355.14 Customer journey checklist  
355.15 Rollback / stop criteria preview  
355.16 First usage runtime data contract  
355.17 i18n-ready first usage marker  
355.18 SEO / OpenGraph first usage placeholder  
355.19 İlk gerçek kullanım smoke test  

## Teknik karar

Bu adım canlı müşteriye sınırsız erişim açmaz. İlk gerçek kullanım zinciri kontrollü smoke olarak çalışır:

- panel, POS ve market yüzeyleri route/smoke seviyesinde doğrulanır.
- gerçek satış, gerçek ödeme, gerçek fatura, gerçek stok düşümü ve gerçek customer go-live kapalıdır.
- data mutation disabled guard zorunludur.
- 356 controlled usage go-live kararı öncesi son müşteri kullanım provasıdır.

Sonraki adım:

- 356 — Controlled usage go-live kararı

## Gate

PASS için:

- `panel.pix2pi.com.tr/first-real-usage-smoke/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Panel login/access, tenant isolation, permission, localization, POS access, market/storefront, product/stock read, cart/payment dry-run, invoice/billing disabled gate, audit timeline, data mutation disabled guard, customer journey checklist, rollback/stop criteria, runtime contract, i18n ve SEO marker'ları bulunmalı.
