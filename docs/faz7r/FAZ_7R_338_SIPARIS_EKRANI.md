# FAZ 7-R / 338 — Sipariş ekranı

## Amaç

`market.pix2pi.com.tr/orders/` üzerinde son müşteri sipariş hazırlık ve takip yüzeyini kurar.

## Kapsam

338.1 Sipariş app shell  
338.2 Store / customer session context  
338.3 Sepet / sipariş taslak context  
338.4 Teslimat / gel-al seçimi  
338.5 Adres / teslimat notu placeholder  
338.6 Sipariş ürün satırları  
338.7 Ara toplam / KDV / teslimat / genel toplam contract  
338.8 Sipariş durum timeline taslağı  
338.9 Gerçek sipariş oluşturma disabled gate  
338.10 Payment handoff disabled gate  
338.11 Tenant / store / customer / order scope guard  
338.12 Order runtime data contract  
338.13 i18n-ready order marker  
338.14 SEO / OpenGraph order placeholder  
338.15 Sipariş smoke test  

## Teknik karar

Bu adım gerçek sipariş oluşturma, gerçek ödeme, gerçek stok rezervasyonu, gerçek kurye/teslimat entegrasyonu veya müşteri hesap doğrulaması açmaz. Sipariş UI, order draft contract, teslimat/gel-al seçimi, order total hesaplama, timeline taslağı, scope guard ve smoke gate kurulur.

Sonraki adım:

- 339 — Satıcı yönetim ekranı

## Gate

PASS için:

- `market.pix2pi.com.tr/orders/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Sipariş app shell, store/customer context, basket/order draft, teslimat/gel-al, adres placeholder, ürün satırları, total contract, status timeline, gerçek order disabled, payment handoff disabled, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
