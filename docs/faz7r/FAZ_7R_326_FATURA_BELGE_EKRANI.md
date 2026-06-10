# FAZ 7-R / 326 — Fatura / belge ekranı

## Amaç

`panel.pix2pi.com.tr/documents/` üzerinde ERP ilk kullanım ekranlarından fatura ve belge yönetim yüzeyini kurar.

## Kapsam

326.1 Fatura/belge app shell  
326.2 Belge liste ekranı  
326.3 Belge oluştur / düzenle formu  
326.4 Belge tipi: e-Fatura / e-Arşiv / e-Adisyon / satış faturası / alış faturası  
326.5 Cari seçimi / müşteri vergi bilgisi preview  
326.6 Belge satırları / ürün / miktar / fiyat / KDV alanları  
326.7 KDV / toplam hesap özeti  
326.8 Belge durum lifecycle preview  
326.9 GİB / özel entegratör canlı gönderim kapalı policy gate  
326.10 PDF / XML / export placeholder  
326.11 Tenant scoped document guard  
326.12 Document validation contract  
326.13 i18n-ready document marker  
326.14 Fatura/belge smoke test  

## Teknik karar

Bu adım gerçek GİB, özel entegratör, e-Fatura, e-Arşiv veya e-Adisyon canlı gönderimi açmaz. Frontend belge yönetim yüzeyi, runtime adapter, tenant scoped header contract, validation contract, lifecycle preview ve smoke gate kurulur.

Canlı dış provider işlemleri policy gate arkasında kapalıdır.

Backend endpoint sözleşmesi:

- Document list: `/api/panel/documents`
- Document draft save: `/api/panel/documents/draft`
- Document lifecycle action: `/api/panel/documents/action`
- Document export: `/api/panel/documents/export`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/documents/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Liste, form, belge tipi, cari preview, satır, KDV/toplam, lifecycle, provider closed gate, export placeholder, tenant guard, validation ve i18n marker'ları bulunmalı.
