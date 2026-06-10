# FAZ 7-R / 323 — Cari ekranı

## Amaç

`panel.pix2pi.com.tr/customers/` üzerinde ERP ilk kullanım ekranlarından cari yönetim yüzeyini kurar.

## Kapsam

323.1 Cari app shell  
323.2 Cari liste ekranı  
323.3 Cari oluştur / düzenle formu  
323.4 Müşteri / tedarikçi / karma cari tipi  
323.5 Vergi no / vergi dairesi / adres zorunlu alanları  
323.6 Telefon / e-posta alanları  
323.7 Cari bakiye özeti  
323.8 Cari durum: aktif / pasif  
323.9 Tenant scoped cari guard  
323.10 Cari validation contract  
323.11 Import / export placeholder  
323.12 i18n-ready cari marker  
323.13 Cari smoke test  

## Teknik karar

Bu adım gerçek backend mutation açmaz. Frontend cari yüzeyi, runtime adapter, tenant scoped header contract, validation contract ve smoke gate kurulur.

Backend endpoint sözleşmesi:

- Cari list: `/api/panel/customers`
- Cari save: `/api/panel/customers/save`
- Cari status: `/api/panel/customers/status`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/customers/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- List, form, tax, contact, balance, tenant guard, validation, import/export ve i18n marker'ları bulunmalı.
