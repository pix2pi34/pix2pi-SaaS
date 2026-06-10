# FAZ 7-R / 328 — Import / export yüzeyi

## Amaç

`panel.pix2pi.com.tr/import-export/` üzerinde merchant panel için import ve export operasyon yüzeyini kurar.

## Kapsam

328.1 Import/export app shell  
328.2 Cari import/export yüzeyi  
328.3 Ürün/stok import/export yüzeyi  
328.4 Fatura/belge export yüzeyi  
328.5 Muhasebe export formatları: Logo / Mikro / Zirve / ETA  
328.6 Şablon indirme placeholder  
328.7 Dosya yükleme / staging preview placeholder  
328.8 Mapping / validation preview  
328.9 Import job status listesi  
328.10 Export history listesi  
328.11 Tenant scoped import/export guard  
328.12 Import/export runtime contract  
328.13 i18n-ready import/export marker  
328.14 Import/export smoke test  

## Teknik karar

Bu adım gerçek dosya işleme, production accounting export ve backend mutation açmaz. Frontend import/export yüzeyi, runtime adapter, tenant scoped header contract, staging preview, mapping validation, job/history fallback snapshot ve smoke gate kurulur.

Backend endpoint sözleşmesi:

- Import template: `/api/panel/import-export/template`
- Import validate: `/api/panel/import-export/validate`
- Import start: `/api/panel/import-export/import`
- Export start: `/api/panel/import-export/export`
- Job list: `/api/panel/import-export/jobs`
- History list: `/api/panel/import-export/history`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/import-export/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Import, export, cari, ürün, belge, muhasebe formatları, template, staging, mapping, job, history, tenant guard, runtime contract ve i18n marker'ları bulunmalı.
