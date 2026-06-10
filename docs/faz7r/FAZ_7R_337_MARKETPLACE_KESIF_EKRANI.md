# FAZ 7-R / 337 — Marketplace keşif ekranı

## Amaç

`market.pix2pi.com.tr/discover/` üzerinde son müşteri için marketplace keşif yüzeyini kurar.

## Kapsam

337.1 Marketplace discovery app shell  
337.2 Konum / mahalle context  
337.3 Mağaza arama kutusu  
337.4 Kategori keşif kartları  
337.5 Yakındaki mağazalar grid  
337.6 Kampanya / fırsat şeritleri  
337.7 Teslimat / gel-al / açık mağaza filtreleri  
337.8 Sıralama seçenekleri  
337.9 Mağaza kartı quick preview  
337.10 Storefront/products deep-link contract  
337.11 Son müşteri session placeholder  
337.12 Tenant / market / region scope guard  
337.13 Discovery runtime data contract  
337.14 i18n-ready discovery marker  
337.15 SEO / OpenGraph discovery placeholder  
337.16 Marketplace keşif smoke test  

## Teknik karar

Bu adım gerçek sipariş, gerçek ödeme, gerçek stok rezervasyonu veya son müşteri hesap/login akışını açmaz. Discovery UI, mağaza keşif snapshot, konum/mahalle context, kategori/teslimat/açık mağaza filtreleri, deep-link contract ve smoke gate kurulur.

Sonraki adım:

- 338 — Sipariş ekranı

## Gate

PASS için:

- `market.pix2pi.com.tr/discover/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Discovery shell, konum context, mağaza arama, kategori kartları, yakındaki mağazalar, kampanya şeritleri, filtreler, sıralama, quick preview, deep-link, session placeholder, scope guard, runtime data contract, i18n ve SEO marker'ları bulunmalı.
