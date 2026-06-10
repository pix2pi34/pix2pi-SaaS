# FAZ 7-R / 324 — Ürün / stok ekranı

## Amaç

`panel.pix2pi.com.tr/products/` üzerinde ERP ilk kullanım ekranlarından ürün ve stok yönetim yüzeyini kurar.

## Kapsam

324.1 Ürün/stok app shell  
324.2 Ürün liste ekranı  
324.3 Ürün oluştur / düzenle formu  
324.4 SKU / barkod / ürün kodu alanları  
324.5 Kategori / marka / birim alanları  
324.6 KDV / satış fiyatı / alış fiyatı alanları  
324.7 Stok miktarı / kritik stok / depo alanları  
324.8 Ürün durum: aktif / pasif  
324.9 Tenant scoped product guard  
324.10 Product validation contract  
324.11 Oto yedek parça uyumluluk placeholder  
324.12 Import / export placeholder  
324.13 i18n-ready product marker  
324.14 Ürün/stok smoke test  

## Teknik karar

Bu adım gerçek backend mutation açmaz. Frontend ürün/stok yüzeyi, runtime adapter, tenant scoped header contract, validation contract ve smoke gate kurulur.

Backend endpoint sözleşmesi:

- Product list: `/api/panel/products`
- Product save: `/api/panel/products/save`
- Product stock: `/api/panel/products/stock`
- Product status: `/api/panel/products/status`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/products/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Liste, form, SKU/barkod, kategori/marka/birim, fiyat/KDV, stok/depo, tenant guard, validation, oto yedek parça placeholder, import/export ve i18n marker'ları bulunmalı.
