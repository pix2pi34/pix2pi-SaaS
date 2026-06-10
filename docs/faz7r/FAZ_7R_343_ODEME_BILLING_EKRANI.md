# FAZ 7-R / 343 — Ödeme / billing ekranı

## Amaç

`panel.pix2pi.com.tr/billing/` üzerinde işletme müşterisi için ödeme, tahsilat ve billing hazırlık yüzeyini kurar.

## Kapsam

343.1 Ödeme / billing app shell  
343.2 Tenant / merchant / subscription context  
343.3 Billing summary kartları  
343.4 Plan fiyat / KDV / genel toplam breakdown  
343.5 Ödeme yöntemi placeholder  
343.6 Kart saklama / provider token disabled gate  
343.7 Payment provider selection placeholder  
343.8 Invoice draft preview  
343.9 Tahsilat başlat disabled gate  
343.10 Payment attempt disabled gate  
343.11 Billing approval gates paneli  
343.12 Mali / vergi / hukuk onay durumu  
343.13 Tenant / billing / payment scope guard  
343.14 Billing runtime data contract  
343.15 i18n-ready billing marker  
343.16 SEO / OpenGraph billing placeholder  
343.17 Ödeme / billing smoke test  

## Teknik karar

Bu adım gerçek ödeme, gerçek kart saklama, gerçek tahsilat, gerçek provider transaction, gerçek fatura kesimi veya gerçek abonelik aktivasyonu açmaz. Billing UI, invoice draft preview, approval gates, provider placeholder ve disabled payment guards kurulur.

Sonraki adım:

- 344 — Fatura geçmişi ekranı

## Gate

PASS için:

- `panel.pix2pi.com.tr/billing/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Billing app shell, tenant/subscription context, summary, KDV breakdown, payment method placeholder, card/provider disabled gates, invoice draft, payment attempt disabled, approval gates, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
