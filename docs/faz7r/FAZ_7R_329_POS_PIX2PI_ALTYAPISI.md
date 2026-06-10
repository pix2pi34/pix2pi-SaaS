# FAZ 7-R / 329 — pos.pix2pi.com.tr altyapısı

## Amaç

`pos.pix2pi.com.tr` üzerinde POS kullanım yüzeyinin temel altyapısını kurar.

## Kapsam

329.1 POS subdomain routing  
329.2 POS Nginx route standardı  
329.3 POS app shell  
329.4 POS mobile-first responsive shell  
329.5 POS PWA manifest placeholder  
329.6 POS runtime shell contract  
329.7 POS tenant/session placeholder  
329.8 POS health check  
329.9 POS smoke test  

## Teknik karar

Bu adım gerçek kasiyer login veya satış işlemi açmaz. POS domain, static shell, health endpoint, runtime contract, Nginx route ve smoke gate kurulur.

Sonraki adım:

- 330 — Kasiyer giriş ekranı

## Gate

PASS için:

- `pos.pix2pi.com.tr` route Nginx loaded config içinde görünmeli.
- `/health` HTTP 200 dönmeli.
- `/` HTTP 200 dönmeli.
- POS shell, mobile shell, PWA placeholder, runtime contract ve tenant/session marker'ları bulunmalı.
