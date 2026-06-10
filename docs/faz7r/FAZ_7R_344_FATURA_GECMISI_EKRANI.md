# FAZ 7-R / 344 — Fatura geçmişi ekranı

## Amaç

`panel.pix2pi.com.tr/invoices/` üzerinde işletme müşterisi için fatura geçmişi, fatura taslakları ve tahsilat/fatura durum görünümünü kurar.

## Kapsam

344.1 Fatura geçmişi app shell  
344.2 Tenant / merchant / billing context  
344.3 Fatura liste tablosu  
344.4 Fatura durum filtreleri  
344.5 Tarih / dönem filtresi placeholder  
344.6 Fatura detay preview  
344.7 Tutar / KDV / genel toplam gösterimi  
344.8 Ödeme durumu rozeti  
344.9 PDF indir disabled gate  
344.10 e-Fatura / e-Arşiv gönderim disabled gate  
344.11 Muhasebe export disabled gate  
344.12 Tahsilat makbuzu placeholder  
344.13 Tenant / invoice / billing scope guard  
344.14 Invoice history runtime data contract  
344.15 i18n-ready invoice marker  
344.16 SEO / OpenGraph invoice placeholder  
344.17 Fatura geçmişi smoke test  

## Teknik karar

Bu adım gerçek fatura kesimi, gerçek e-Fatura/e-Arşiv gönderimi, gerçek PDF üretimi, gerçek muhasebe export veya gerçek tahsilat makbuzu üretimi açmaz. Fatura geçmişi UI, fallback invoice snapshot, filtreler, detay preview ve disabled gates kurulur.

Sonraki adım:

- 345 — Admin commercial panel

## Gate

PASS için:

- `panel.pix2pi.com.tr/invoices/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Fatura geçmişi app shell, tenant/billing context, liste, filtreler, detay preview, tutar/KDV/toplam, ödeme status, PDF/e-Belge/export disabled gates, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
