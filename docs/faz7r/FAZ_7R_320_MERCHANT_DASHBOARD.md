# FAZ 7-R / 320 — Merchant dashboard

## Amaç

`panel.pix2pi.com.tr/dashboard/` üzerinde işletme sahibinin ilk göreceği merchant dashboard yüzeyini kurar.

## Kapsam

320.1 Dashboard app shell  
320.2 Tenant summary card  
320.3 Onboarding progress widget  
320.4 KPI cards  
320.5 Quick actions  
320.6 POS / ERP / Marketplace status cards  
320.7 Alert / notification preview  
320.8 i18n-ready dashboard text markers  
320.9 Dashboard runtime data contract  
320.10 Dashboard smoke test  

## Teknik karar

Bu adım gerçek backend veri bağlantısını production olarak açmaz. Dashboard frontend yüzeyi, runtime contract, mock-safe snapshot ve smoke gate kurulur.

Backend entegrasyon sözleşmesi:

- Snapshot endpoint: `/api/panel/dashboard/snapshot`
- Runtime surface: `merchant_dashboard`
- Tenant context: JWT + selected tenant preference
- Fallback: frontend local snapshot

## Gate

PASS için:

- `/dashboard/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- KPI, onboarding, tenant, quick action, POS, ERP, marketplace ve alert marker'ları bulunmalı.
- i18n `data-i18n` marker'ları bulunmalı.
- Dashboard runtime snapshot contract bulunmalı.
