# FAZ 7-R / 335 — İşletme mağaza vitrini

## Amaç

`market.pix2pi.com.tr/storefront/` üzerinde işletme mağaza vitrini yüzeyini kurar.

## Kapsam

335.1 Marketplace / storefront subdomain route  
335.2 İşletme mağaza vitrini app shell  
335.3 İşletme profil hero  
335.4 Mağaza durum / çalışma saati kartı  
335.5 Kategori önizleme  
335.6 Öne çıkan ürün grid  
335.7 Teslimat / gel-al seçenekleri placeholder  
335.8 Kampanya / duyuru banner  
335.9 Tenant / store slug guard  
335.10 Storefront runtime data contract  
335.11 i18n-ready storefront marker  
335.12 SEO / OpenGraph placeholder  
335.13 Storefront smoke test  

## Teknik karar

Bu adım gerçek sipariş alma, gerçek ödeme, gerçek stok rezervasyonu veya müşteri checkout açmaz. İşletme vitrini UI, demo/fallback storefront snapshot, tenant/store slug guard, SEO/OpenGraph placeholder, marketplace route ve smoke gate kurulur.

Sonraki adım:

- 336 — Ürün listeleme ekranı

## Gate

PASS için:

- `market.pix2pi.com.tr/storefront/` HTTP 200 dönmeli.
- `/health` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Storefront shell, işletme profil hero, mağaza durum, kategori, ürün grid, teslimat/gel-al, kampanya, tenant/store slug guard, runtime data contract, i18n ve SEO marker'ları bulunmalı.
