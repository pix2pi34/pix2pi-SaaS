# FAZ 7-R / 357 — Controlled customer access activation

## Amaç

`panel.pix2pi.com.tr/controlled-customer-access-activation/` üzerinde controlled customer access aktivasyon yüzeyini kurar.

## Kapsam

357.1 Controlled customer access activation app shell  
357.2 Tenant / customer / owner activation context  
357.3 Human approval binding preview  
357.4 Activation window / scope preview  
357.5 Customer access toggle preview  
357.6 Panel access activation preview  
357.7 POS access activation preview  
357.8 Market/storefront access activation preview  
357.9 Activation token / session handoff disabled gate  
357.10 Data mutation safety remains disabled  
357.11 Support channel handoff preview  
357.12 Monitoring / incident readiness preview  
357.13 Rollback activation action preview  
357.14 Activation audit timeline  
357.15 Customer notification preview  
357.16 Activation runtime data contract  
357.17 i18n-ready activation marker  
357.18 SEO / OpenGraph activation placeholder  
357.19 Controlled activation smoke test  

## Teknik karar

Bu adım gerçek müşteri erişimini otomatik açmaz. Kontrollü erişim aktivasyon yüzeyi hazırlanır; insan onayı, support handoff ve monitoring readiness sonrası gerçek activation ayrı adımda açılır.

Güvenlik durumu:

- `real_customer_access_activation_enabled=false`
- `real_panel_access_activation_enabled=false`
- `real_pos_access_activation_enabled=false`
- `real_market_access_activation_enabled=false`
- `real_data_mutation_enabled=false`
- `activation_preview_enabled=true`

Sonraki adım:

- 358 — Controlled pilot monitoring / first day watch

## Gate

PASS için:

- `panel.pix2pi.com.tr/controlled-customer-access-activation/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Activation app shell, tenant/customer/owner context, approval binding, activation window, access toggles, panel/POS/market activation preview, token/session handoff disabled gate, data mutation disabled, support handoff, monitoring/incident readiness, rollback preview, audit timeline, notification preview, runtime contract, i18n ve SEO marker'ları bulunmalı.
