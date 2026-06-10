# FAZ 7-R / 334 — Mobile-ready PWA yüzeyi

## Amaç

`pos.pix2pi.com.tr/pwa/` üzerinde POS için mobile-ready PWA yüzeyini kurar.

## Kapsam

334.1 Mobile-ready PWA app shell  
334.2 PWA manifest  
334.3 Service worker placeholder  
334.4 Install prompt runtime contract  
334.5 Offline fallback page  
334.6 Safe-area / mobile viewport contract  
334.7 Touch-optimized navigation  
334.8 Cache strategy placeholder  
334.9 POS route cache allowlist  
334.10 PWA icon / asset placeholder  
334.11 Tenant / device / cashier session preservation contract  
334.12 i18n-ready PWA marker  
334.13 Mobile-ready PWA smoke test  

## Teknik karar

Bu adım gerçek production offline replay veya gerçek payment finalize açmaz. PWA manifest, service worker placeholder, offline fallback, install prompt runtime, mobile/safe-area yüzey ve smoke gate kurulur.

Bu adım ile POS kullanım yüzeyi mobil/PWA hazırlık seviyesine gelir. Sonraki ana iş marketplace ekranlarına geçiştir:

- 335 — İşletme mağaza vitrini

## Gate

PASS için:

- `/pwa/` HTTP 200 dönmeli.
- `/manifest.json` HTTP 200 ve semantic JSON valid olmalı.
- `/sw.js` HTTP 200 dönmeli.
- `/offline-fallback.html` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Manifest, service worker, install prompt, offline fallback, safe-area, touch navigation, cache strategy, session preservation ve i18n marker'ları bulunmalı.
