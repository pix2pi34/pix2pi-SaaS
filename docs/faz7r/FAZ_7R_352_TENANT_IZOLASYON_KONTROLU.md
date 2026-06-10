# FAZ 7-R / 352 — Tenant izolasyon kontrolü

## Amaç

`panel.pix2pi.com.tr/tenant-isolation-check/` üzerinde kontrollü müşteri açılışı öncesi tenant izolasyon kontrol yüzeyini kurar.

## Kapsam

352.1 Tenant isolation app shell  
352.2 Source tenant / target tenant context  
352.3 Cross-tenant access denial preview  
352.4 RLS readiness checklist  
352.5 Tenant scoped route guard  
352.6 Tenant scoped panel data guard  
352.7 Tenant scoped POS data guard  
352.8 Tenant scoped marketplace data guard  
352.9 Audit/export isolation preview  
352.10 Break-glass disabled preview  
352.11 Tenant isolation regression checklist  
352.12 Isolation incident preview  
352.13 Isolation audit timeline  
352.14 Isolation decision contract  
352.15 Tenant isolation runtime data contract  
352.16 i18n-ready isolation marker  
352.17 SEO / OpenGraph isolation placeholder  
352.18 Tenant izolasyon smoke test  

## Teknik karar

Bu adım gerçek production tenant erişimi açmaz. RLS ve cross-tenant isolation davranışı UI/contract seviyesinde doğrulanır; backend read/write enforcement gerçek açılış öncesi ayrı gate olarak kapalı kalır.

Sonraki adım:

- 353 — Kullanıcı yetki kontrolü

## Gate

PASS için:

- `panel.pix2pi.com.tr/tenant-isolation-check/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Tenant isolation app shell, source/target context, cross-tenant denial, RLS checklist, route/panel/POS/marketplace guards, audit/export isolation, break-glass disabled preview, regression checklist, incident preview, audit timeline, decision contract, runtime contract, i18n ve SEO marker'ları bulunmalı.
