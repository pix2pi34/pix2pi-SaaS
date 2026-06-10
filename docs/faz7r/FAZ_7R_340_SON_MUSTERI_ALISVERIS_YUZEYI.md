# FAZ 7-R / 340 — Son müşteri alışveriş yüzeyi

## Amaç

`market.pix2pi.com.tr/shop/` üzerinde son müşteri için tek girişli alışveriş yüzeyini kurar.

## Kapsam

340.1 Son müşteri shopping app shell  
340.2 Customer session / anonymous context  
340.3 Region / neighborhood context  
340.4 Store discovery shortcut  
340.5 Product discovery shortcut  
340.6 Basket preview widget  
340.7 Storefront / products / order deep-link hub  
340.8 Campaign / recommendation strip  
340.9 Delivery / pickup preference selector  
340.10 Add-to-basket disabled guard  
340.11 Checkout / order submit disabled guard  
340.12 Payment disabled guard  
340.13 Customer / region / store / basket scope guard  
340.14 Shopping runtime data contract  
340.15 i18n-ready shopping marker  
340.16 SEO / OpenGraph shopping placeholder  
340.17 Son müşteri alışveriş smoke test  

## Teknik karar

Bu adım gerçek sepet mutasyonu, gerçek sipariş submit, gerçek ödeme, gerçek stok rezervasyonu veya gerçek müşteri login açmaz. Son müşteri alışveriş kabuğu, discovery/products/orders derin bağlantıları, sepet preview, teslimat/gel-al tercihi, customer/region scope guard ve smoke gate kurulur.

Sonraki adım:

- 341 — Paket / abonelik ekranı

## Gate

PASS için:

- `market.pix2pi.com.tr/shop/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Shopping app shell, customer context, region context, discovery shortcut, product shortcut, basket preview, deep-link hub, campaign strip, fulfillment selector, basket/order/payment disabled guards, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
