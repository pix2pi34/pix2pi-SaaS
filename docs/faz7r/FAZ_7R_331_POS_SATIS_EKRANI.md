# FAZ 7-R / 331 — POS satış ekranı

## Amaç

`pos.pix2pi.com.tr/sale/` üzerinde kasiyer satış yüzeyini kurar.

## Kapsam

331.1 POS satış app shell  
331.2 Kasiyer/session guard  
331.3 Ürün arama / barkod girişi  
331.4 Hızlı ürün listesi  
331.5 Sepet önizleme  
331.6 Miktar artır / azalt / sil davranışı  
331.7 KDV / ara toplam / genel toplam hesap contract  
331.8 Satış taslak payload contract  
331.9 Ödeme adımına yönlendirme placeholder  
331.10 Offline queue placeholder  
331.11 Tenant / device / cashier scoped guard  
331.12 i18n-ready POS sale marker  
331.13 POS satış smoke test  

## Teknik karar

Bu adım gerçek satış kaydı, ödeme tahsilatı veya stok düşümü yapmaz. POS satış UI, runtime adapter, sepet taslak contract, tenant/device/cashier guard, fallback product catalog ve smoke gate kurulur.

Ödeme ve sepet/ödeme akışı sonraki adımda genişletilir:

- 332 — Sepet / ödeme akışı

Backend endpoint sözleşmesi:

- Product search: `/api/pos/products/search`
- Sale draft: `/api/pos/sales/draft`
- Session verify: `/api/pos/auth/session`
- Tenant header: `X-Tenant-ID`
- Device header: `X-POS-Device-ID`
- Cashier header: `X-POS-Cashier-Code`

## Gate

PASS için:

- `/sale/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- App shell, session guard, ürün arama, barkod, hızlı ürünler, sepet, miktar davranışı, toplam hesaplama, satış draft payload, ödeme placeholder, offline placeholder, tenant/device/cashier guard ve i18n marker'ları bulunmalı.
