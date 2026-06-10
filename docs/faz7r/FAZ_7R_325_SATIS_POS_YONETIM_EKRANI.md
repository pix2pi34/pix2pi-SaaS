# FAZ 7-R / 325 — Satış / POS yönetim ekranı

## Amaç

`panel.pix2pi.com.tr/sales/` üzerinde merchant panel için satış ve POS yönetim yüzeyini kurar.

## Kapsam

325.1 Satış/POS yönetim app shell  
325.2 Satış özeti ve son satışlar  
325.3 POS terminal / kasa durumu  
325.4 Kasiyer / cihaz register placeholder  
325.5 Fiş / belge akışı preview  
325.6 Ödeme yöntemi özeti  
325.7 İade / iptal / void guard  
325.8 Tenant scoped sales/POS guard  
325.9 Shift / kasa açılış-kapanış policy placeholder  
325.10 Runtime data contract  
325.11 i18n-ready sales/POS marker  
325.12 Sales/POS smoke test  

## Teknik karar

Bu adım gerçek satış veya gerçek POS tahsilat işlemi açmaz. Panel tarafında satış/POS yönetim yüzeyi, runtime adapter, tenant scoped header contract, fallback snapshot ve smoke gate kurulur.

POS gerçek kullanım yüzeyi ayrı domain altında ileride açılır:

- `pos.pix2pi.com.tr`

Bu adım panel tarafı yönetim ekranıdır.

Backend endpoint sözleşmesi:

- Sales snapshot: `/api/panel/sales/snapshot`
- POS terminal list: `/api/panel/pos/terminals`
- Shift policy: `/api/panel/pos/shift-policy`
- Sale guard action: `/api/panel/sales/action`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/sales/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Satış özeti, POS terminal, kasiyer/cihaz, fiş/belge, ödeme, iade/iptal, shift policy, tenant guard, runtime contract ve i18n marker'ları bulunmalı.
