# FAZ 7-R / 358 — Controlled pilot monitoring / first day watch

## Amaç

`panel.pix2pi.com.tr/controlled-pilot-monitoring/` üzerinde controlled customer access sonrası ilk gün izleme / pilot watch yüzeyini kurar.

## Kapsam

358.1 Controlled pilot monitoring app shell  
358.2 Pilot tenant / customer watch context  
358.3 First day watch timeline  
358.4 Pilot health dashboard preview  
358.5 Panel / POS / Market route health  
358.6 Auth / permission / tenant isolation watch  
358.7 Runtime error dashboard preview  
358.8 Incident watch queue preview  
358.9 Support handoff / customer contact watch  
358.10 Customer activity / session watch  
358.11 Transaction mutation guard watch  
358.12 Billing / payment disabled watch  
358.13 Localization watch  
358.14 SLO / early warning thresholds  
358.15 Rollback trigger checklist  
358.16 Daily pilot report preview  
358.17 Monitoring audit timeline  
358.18 Monitoring runtime data contract  
358.19 i18n-ready monitoring marker  
358.20 SEO / OpenGraph monitoring placeholder  
358.21 Controlled pilot monitoring smoke test  

## Teknik karar

Bu adım gerçek müşteri verisine müdahale etmez. İlk gün izleme paneli yalnızca preview / dry-run durumunu gösterir. Gerçek satış, ödeme, fatura, stok düşümü ve destructive mutation hâlâ kapalıdır.

Sonraki adım:

- 359 — Pilot feedback / issue triage

## Gate

PASS için:

- `panel.pix2pi.com.tr/controlled-pilot-monitoring/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Watch timeline, health dashboard, route health, auth/permission/isolation watch, runtime error, incident queue, support handoff, customer activity, mutation guard, billing/payment disabled, localization, early warning thresholds, rollback checklist, daily pilot report, audit timeline, runtime contract, i18n ve SEO marker'ları bulunmalı.
