# FAZ 7-R / 359 — Pilot feedback / issue triage

## Amaç

`panel.pix2pi.com.tr/pilot-feedback-triage/` üzerinde controlled pilot ilk gün izleme sonrası müşteri geri bildirimlerini, issue triage kuyruğunu ve hotfix/no-hotfix kararını preview olarak kurar.

## Kapsam

359.1 Pilot feedback triage app shell  
359.2 Pilot tenant / customer feedback context  
359.3 Feedback intake channels  
359.4 Customer sentiment snapshot  
359.5 Issue triage queue preview  
359.6 Severity / priority classification  
359.7 Owner assignment preview  
359.8 Duplicate issue merge preview  
359.9 Incident escalation link preview  
359.10 Product backlog candidate preview  
359.11 Support response draft preview  
359.12 Hotfix / no-hotfix decision preview  
359.13 Data mutation disabled safety guard  
359.14 Rollback request review preview  
359.15 Daily pilot report handoff  
359.16 Feedback audit timeline  
359.17 Feedback triage runtime data contract  
359.18 i18n-ready feedback marker  
359.19 SEO / OpenGraph feedback placeholder  
359.20 Pilot feedback triage smoke test

## Teknik karar

Bu adım gerçek ticket sistemi, gerçek müşteri bildirimi, gerçek hotfix deploy ve gerçek DB mutation açmaz. Sadece feedback/issue triage karar yüzeyini hazırlar.

Sonraki adım:

- 360 — Pilot stabilization / fix plan closure
