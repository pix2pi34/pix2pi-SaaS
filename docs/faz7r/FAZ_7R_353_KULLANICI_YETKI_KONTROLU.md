# FAZ 7-R / 353 — Kullanıcı yetki kontrolü

## Amaç

`panel.pix2pi.com.tr/user-permission-check/` üzerinde kontrollü müşteri açılışı öncesi kullanıcı rol/yetki karar yüzeyini kurar.

## Kapsam

353.1 User permission check app shell  
353.2 Tenant / user / role / session context  
353.3 Role permission matrix preview  
353.4 Permission decision contract  
353.5 Panel route permission checks  
353.6 POS action permission checks  
353.7 Marketplace action permission checks  
353.8 Commercial / billing permission checks  
353.9 Admin-only action disabled gate  
353.10 Least privilege / deny-by-default preview  
353.11 Role switch regression preview  
353.12 Unauthorized / forbidden permission state preview  
353.13 Permission audit timeline  
353.14 Tenant / user / role / action scope guard  
353.15 Permission runtime data contract  
353.16 i18n-ready permission marker  
353.17 SEO / OpenGraph permission placeholder  
353.18 Kullanıcı yetki kontrolü smoke test  

## Teknik karar

Bu adım gerçek backend RBAC enforcement, gerçek role mutation veya gerçek admin override açmaz. Yetki kararları UI/contract seviyesinde doğrulanır; 354 localization customer smoke öncesinde kullanıcı yetki matrisi ve deny-by-default davranışı görünür hale getirilir.

Sonraki adım:

- 354 — Localization customer smoke

## Gate

PASS için:

- `panel.pix2pi.com.tr/user-permission-check/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- User permission app shell, tenant/user/role/session context, role matrix, permission decision contract, panel/POS/marketplace/commercial checks, admin-only disabled gate, least privilege, role switch regression, unauthorized/forbidden preview, audit timeline, action scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
