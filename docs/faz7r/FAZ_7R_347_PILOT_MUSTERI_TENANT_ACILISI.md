# FAZ 7-R / 347 — Pilot müşteri tenant açılışı

## Amaç

`panel.pix2pi.com.tr/pilot-tenant/` üzerinde kontrollü ilk müşteri tenant açılış yüzeyini kurar.

## Kapsam

347.1 Pilot tenant açılış app shell  
347.2 Pilot tenant request / draft context  
347.3 Tenant slug / domain / environment context  
347.4 İşletme temel bilgi checklist  
347.5 Legal entity / branch placeholder  
347.6 Default plan binding  
347.7 Default language / timezone / currency binding  
347.8 Owner admin assignment placeholder  
347.9 KVKK / legal / commercial approval gate  
347.10 Data isolation / RLS readiness gate  
347.11 Panel / POS / Market access preparation  
347.12 Tenant provisioning disabled guard  
347.13 Tenant activation disabled guard  
347.14 Tenant opening audit timeline  
347.15 Tenant opening runtime data contract  
347.16 i18n-ready pilot tenant marker  
347.17 SEO / OpenGraph pilot tenant placeholder  
347.18 Pilot tenant opening smoke test  

## Teknik karar

Bu adım gerçek DB tenant insert, gerçek kullanıcı daveti, gerçek aktivasyon, gerçek ödeme veya gerçek müşteri erişimi açmaz. Kontrollü pilot tenant açılışı için UI, checklist, approval gate, isolation readiness, access preparation ve disabled provisioning/activation guard kurulur.

Sonraki adım:

- 348 — İlk işletme kullanıcı daveti

## Gate

PASS için:

- `panel.pix2pi.com.tr/pilot-tenant/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Pilot tenant app shell, request draft, slug/domain context, business checklist, legal/branch placeholder, default plan/language/currency, owner assignment placeholder, approval gates, RLS readiness, access prep, disabled provisioning/activation, audit timeline, runtime contract, i18n ve SEO marker'ları bulunmalı.
