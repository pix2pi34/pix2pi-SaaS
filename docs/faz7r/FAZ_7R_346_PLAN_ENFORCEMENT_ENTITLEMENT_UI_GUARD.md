# FAZ 7-R / 346 — Plan enforcement / entitlement UI guard

## Amaç

`panel.pix2pi.com.tr/entitlements/` üzerinde plan enforcement ve entitlement UI guard yüzeyini kurar.

## Kapsam

346.1 Entitlement UI guard app shell  
346.2 Tenant / user / role / plan context  
346.3 Feature entitlement matrix  
346.4 UI route access guard preview  
346.5 POS entitlement guard  
346.6 Marketplace entitlement guard  
346.7 Product / user / store quota guard bridge  
346.8 Disabled action buttons by entitlement  
346.9 Upgrade required banner  
346.10 Plan enforcement dry-run mode  
346.11 Enforcement audit event preview  
346.12 Permission + entitlement decision contract  
346.13 Tenant / user / action scope guard  
346.14 Frontend guard runtime data contract  
346.15 i18n-ready entitlement marker  
346.16 SEO / OpenGraph entitlement placeholder  
346.17 Entitlement UI guard smoke test  

## Teknik karar

Bu adım gerçek backend enforcement, gerçek ödeme tahsilatı, gerçek plan değişikliği veya gerçek tenant suspend işlemi açmaz. UI guard, entitlement decision preview, route guard preview, disabled action guard ve dry-run enforcement contract kurulur.

Sonraki adım:

- 347 — Pilot müşteri tenant açılışı

## Gate

PASS için:

- `panel.pix2pi.com.tr/entitlements/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Entitlement app shell, tenant/user/plan context, feature matrix, route guard, POS/marketplace guard, quota bridge, disabled actions, upgrade banner, dry-run enforcement, audit preview, permission+entitlement decision, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
