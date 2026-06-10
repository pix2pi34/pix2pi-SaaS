# FAZ 7-R / 336 — Ürün listeleme ekranı

## Amaç

`market.pix2pi.com.tr/products/` üzerinde marketplace ürün listeleme yüzeyini kurar.

## Kapsam

336.1 Ürün listeleme app shell  
336.2 Storefront / store slug context  
336.3 Ürün arama kutusu  
336.4 Kategori filtresi  
336.5 Marka / stok / fiyat filtreleri  
336.6 Sıralama seçenekleri  
336.7 Ürün kart grid  
336.8 Ürün detay quick preview placeholder  
336.9 Sepete ekle disabled gate  
336.10 Pagination / load-more placeholder  
336.11 Tenant / store / product scope guard  
336.12 Product listing runtime data contract  
336.13 i18n-ready product listing marker  
336.14 SEO / OpenGraph product listing placeholder  
336.15 Ürün listeleme smoke test  

## Teknik karar

Bu adım gerçek sepet, gerçek ödeme, gerçek stok rezervasyonu veya son müşteri checkout açmaz. Ürün listeleme UI, filtre/sıralama runtime, fallback ürün katalog snapshot, tenant/store/product scope guard ve smoke gate kurulur.

Sonraki adım:

- 337 — Marketplace keşif ekranı

## Gate

PASS için:

- `market.pix2pi.com.tr/products/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Ürün listeleme app shell, store context, arama, kategori/marka/stok/fiyat filtreleri, sıralama, ürün grid, quick preview placeholder, sepete ekle disabled gate, pagination, scope guard, runtime data contract, i18n ve SEO marker'ları bulunmalı.
