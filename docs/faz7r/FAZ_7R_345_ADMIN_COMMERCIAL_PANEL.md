# FAZ 7-R / 345 — Admin commercial panel

## Amaç

`panel.pix2pi.com.tr/admin-commercial/` üzerinde platform yöneticisi için ticari yönetim panelini kurar.

## Kapsam

345.1 Admin commercial app shell  
345.2 Platform admin context  
345.3 Tenant commercial overview  
345.4 Subscription account status table  
345.5 Plan catalog management preview  
345.6 Billing approval queue  
345.7 Payment provider gate status  
345.8 Revenue / MRR / trial KPI cards  
345.9 Risk / compliance gate panel  
345.10 Manual commercial override disabled gate  
345.11 Tenant suspend / resume / cancel disabled gate  
345.12 Commercial audit timeline  
345.13 Export / report disabled gate  
345.14 Admin / tenant / commercial scope guard  
345.15 Admin commercial runtime data contract  
345.16 i18n-ready admin commercial marker  
345.17 SEO / OpenGraph admin commercial placeholder  
345.18 Admin commercial smoke test  

## Teknik karar

Bu adım gerçek plan override, gerçek tenant suspend/resume/cancel, gerçek tahsilat, gerçek provider live gate, gerçek export/report veya gerçek subscription lifecycle mutasyonu açmaz. Admin commercial panel yalnızca görünürlük, gate kontrolü, approval queue ve audit timeline yüzeyi kurar.

Sonraki adım:

- 346 — Plan enforcement / entitlement UI guard

## Gate

PASS için:

- `panel.pix2pi.com.tr/admin-commercial/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Admin commercial app shell, platform admin context, tenant overview, subscription table, plan catalog preview, billing approval queue, provider gate, KPI cards, risk/compliance panel, disabled mutation gates, audit timeline, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
