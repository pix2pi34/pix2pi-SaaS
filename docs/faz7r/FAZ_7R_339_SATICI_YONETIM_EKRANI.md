# FAZ 7-R / 339 — Satıcı yönetim ekranı

## Amaç

`market.pix2pi.com.tr/seller/` üzerinde marketplace satıcı yönetim yüzeyini kurar.

## Kapsam

339.1 Satıcı yönetim app shell  
339.2 Store / seller session context  
339.3 Mağaza profil yönetimi placeholder  
339.4 Ürün yönetimi quick actions  
339.5 Sipariş yönetimi preview  
339.6 Sipariş durum aksiyonları disabled gate  
339.7 Stok / uygunluk yönetimi placeholder  
339.8 Teslimat / gel-al operasyon kartı  
339.9 Kampanya / vitrin yönetimi placeholder  
339.10 Satıcı performans KPI kartları  
339.11 Satıcı bildirim / uyarı paneli  
339.12 Tenant / seller / store scope guard  
339.13 Seller runtime data contract  
339.14 i18n-ready seller marker  
339.15 SEO / OpenGraph seller placeholder  
339.16 Satıcı yönetim smoke test  

## Teknik karar

Bu adım gerçek satıcı operasyon mutasyonu açmaz. Sipariş kabul/red, stok güncelleme, kampanya yayına alma, canlı ödeme/teslimat aksiyonları disabled gate altında kalır. Satıcı yönetim UI, fallback seller snapshot, seller/store scope guard, quick action placeholder ve smoke gate kurulur.

Sonraki adım:

- 340 — Son müşteri alışveriş yüzeyi

## Gate

PASS için:

- `market.pix2pi.com.tr/seller/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Satıcı app shell, seller/store context, mağaza profil, ürün quick actions, sipariş preview, disabled action gate, stok/uygunluk, teslimat/gel-al, kampanya/vitrin, KPI, uyarı paneli, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
