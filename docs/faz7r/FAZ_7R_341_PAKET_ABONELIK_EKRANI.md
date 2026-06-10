# FAZ 7-R / 341 — Paket / abonelik ekranı

## Amaç

`panel.pix2pi.com.tr/plans/` üzerinde işletme müşterisi için paket / abonelik seçimi yüzeyini kurar.

## Kapsam

341.1 Paket / abonelik app shell  
341.2 Tenant / merchant context  
341.3 Paket kartları  
341.4 Plan özellik matrisi  
341.5 Aylık / yıllık fiyat görünümü  
341.6 Mevcut plan rozeti  
341.7 Plan yükseltme / düşürme disabled gate  
341.8 Trial / pilot plan placeholder  
341.9 Vergi / KDV fiyat notu  
341.10 Commercial policy note  
341.11 Plan comparison runtime contract  
341.12 Entitlement preview handoff  
341.13 Billing handoff disabled gate  
341.14 Tenant / plan / subscription scope guard  
341.15 i18n-ready plan marker  
341.16 SEO / OpenGraph plan placeholder  
341.17 Paket / abonelik smoke test  

## Teknik karar

Bu adım gerçek ödeme, gerçek abonelik değişikliği, gerçek tahsilat, gerçek fatura veya plan enforcement açmaz. Paket seçimi UI, fallback plan katalogu, plan comparison, entitlement preview ve billing handoff disabled gate kurulur.

Sonraki adım:

- 342 — Kullanım hakkı / kota ekranı

## Gate

PASS için:

- `panel.pix2pi.com.tr/plans/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Paket app shell, tenant context, plan kartları, feature matrix, fiyat toggle, mevcut plan rozeti, upgrade/downgrade disabled gate, pilot/trial placeholder, KDV notu, commercial policy, runtime contract, entitlement handoff, billing handoff disabled, scope guard, i18n ve SEO marker'ları bulunmalı.
