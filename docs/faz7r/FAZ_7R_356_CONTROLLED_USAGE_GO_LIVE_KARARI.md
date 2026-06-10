# FAZ 7-R / 356 — Controlled usage go-live kararı

## Amaç

`panel.pix2pi.com.tr/controlled-usage-go-live-decision/` üzerinde ilk gerçek kullanım smoke sonrası kontrollü müşteri kullanımına geçiş karar yüzeyini kurar.

## Kapsam

356.1 Controlled go-live decision app shell  
356.2 Decision board context  
356.3 Prerequisite evidence checklist  
356.4 Security gate decision  
356.5 Tenant isolation gate decision  
356.6 Permission gate decision  
356.7 Localization gate decision  
356.8 Panel / POS / Market route gate decision  
356.9 Data mutation safety decision  
356.10 Billing / payment disabled decision  
356.11 Support / rollback readiness decision  
356.12 Customer access mode decision  
356.13 Go / no-go decision preview  
356.14 Approver checklist placeholder  
356.15 Final risk register preview  
356.16 Decision audit timeline  
356.17 Controlled go-live runtime data contract  
356.18 i18n-ready decision marker  
356.19 SEO / OpenGraph decision placeholder  
356.20 Controlled go-live decision smoke test  

## Teknik karar

Bu adım gerçek müşteri erişimini otomatik açmaz. Karar yüzeyi `GO_PREVIEW / READY_FOR_APPROVAL` üretir, fakat `real_customer_go_live_enabled=false` kalır. Gerçek erişim ancak sonraki kontrollü activation adımı ve insan onayı ile açılır.

Sonraki adım:

- 357 — Controlled customer access activation

## Gate

PASS için:

- `panel.pix2pi.com.tr/controlled-usage-go-live-decision/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Evidence checklist, security, tenant isolation, permission, localization, panel/POS/market route, data mutation safety, billing/payment disabled, support/rollback readiness, customer access mode, go/no-go preview, approver checklist, risk register, audit timeline, runtime contract, i18n ve SEO marker'ları bulunmalı.
