# FAZ 7-R / 362 — Controlled rollout cohort setup

## Amaç

`panel.pix2pi.com.tr/controlled-rollout-cohort-setup/` üzerinde kontrollü rollout için müşteri cohort kurulum yüzeyini hazırlar.

## Kapsam

362.1 Controlled rollout cohort app shell  
362.2 Rollout cohort setup context  
362.3 Cohort size / limit preview  
362.4 Customer eligibility checklist  
362.5 Tenant selection preview  
362.6 Sector / region / risk segmentation  
362.7 Rollout wave schedule preview  
362.8 Feature flag cohort binding preview  
362.9 Entitlement / plan binding preview  
362.10 Support capacity gate  
362.11 Monitoring capacity gate  
362.12 Legal / KVKK approval hold gate  
362.13 Billing / payment live disabled gate  
362.14 Data mutation disabled safety guard  
362.15 Cohort rollback plan preview  
362.16 Cohort communication draft preview  
362.17 Cohort setup audit timeline  
362.18 Cohort setup runtime data contract  
362.19 i18n-ready cohort marker  
362.20 SEO / OpenGraph cohort placeholder  
362.21 Controlled rollout cohort smoke test

## Teknik karar

Bu adım gerçek müşteri ekleme, gerçek rollout activation, gerçek billing/payment ve data mutation açmaz. Cohort sadece preview/dry-run olarak hazırlanır.

Sonraki adım:

- 363 — Controlled rollout cohort approval gate
