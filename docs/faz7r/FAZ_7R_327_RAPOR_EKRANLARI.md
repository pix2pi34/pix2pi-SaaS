# FAZ 7-R / 327 — Rapor ekranları

## Amaç

`panel.pix2pi.com.tr/reports/` üzerinde merchant panel için ilk ERP rapor ekranlarını kurar.

## Kapsam

327.1 Reports app shell  
327.2 KPI summary cards  
327.3 Satış raporu yüzeyi  
327.4 Stok raporu yüzeyi  
327.5 Cari raporu yüzeyi  
327.6 Fatura / belge raporu yüzeyi  
327.7 Tarih aralığı / filtre yüzeyi  
327.8 Export placeholder  
327.9 Reporting store / read model contract  
327.10 Tenant scoped report guard  
327.11 Runtime fallback snapshot  
327.12 i18n-ready report marker  
327.13 Reports smoke test  

## Teknik karar

Bu adım gerçek reporting store sorgusunu production olarak açmaz. Frontend rapor yüzeyi, runtime adapter, tenant scoped header contract, read model contract, fallback snapshot ve smoke gate kurulur.

Backend endpoint sözleşmesi:

- Reports snapshot: `/api/panel/reports/snapshot`
- Sales report: `/api/panel/reports/sales`
- Stock report: `/api/panel/reports/stock`
- Customer report: `/api/panel/reports/customers`
- Document report: `/api/panel/reports/documents`
- Export: `/api/panel/reports/export`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/reports/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- KPI, satış, stok, cari, belge, filtre, export, read model, tenant guard, fallback snapshot ve i18n marker'ları bulunmalı.
