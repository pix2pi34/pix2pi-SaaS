# FAZ 7-R / 350 — Panel erişim testi

## Amaç

`panel.pix2pi.com.tr/panel-access-test/` üzerinde ilk işletme kullanıcısı için kontrollü panel erişim testi yüzeyini kurar.

## Kapsam

350.1 Panel access test app shell  
350.2 Auth/session simulation context  
350.3 Tenant selected context  
350.4 Owner admin role access preview  
350.5 Panel route availability checklist  
350.6 Dashboard access check  
350.7 Users / roles access check  
350.8 Products / stock access check  
350.9 Billing / entitlements access check  
350.10 Unauthorized / forbidden preview  
350.11 Session timeout preview  
350.12 Panel navigation handoff  
350.13 Access audit timeline  
350.14 Tenant / user / role / route scope guard  
350.15 Panel access runtime data contract  
350.16 i18n-ready panel access marker  
350.17 SEO / OpenGraph panel access placeholder  
350.18 Panel erişim smoke test  

## Teknik karar

Bu adım gerçek JWT doğrulama, gerçek session açma, gerçek RBAC backend enforcement veya gerçek kullanıcı login açmaz. 349 sonrası panel erişim rotalarının kontrollü smoke ve UI access preview doğrulamasını yapar.

Sonraki adım:

- 351 — POS erişim testi

## Gate

PASS için:

- `panel.pix2pi.com.tr/panel-access-test/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Panel erişim app shell, auth/session context, tenant context, owner role preview, route availability checklist, dashboard/users/products/billing checks, unauthorized/forbidden preview, session timeout preview, navigation handoff, audit timeline, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
