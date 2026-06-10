# FAZ 7-R / 342 — Kullanım hakkı / kota ekranı

## Amaç

`panel.pix2pi.com.tr/quota/` üzerinde işletme müşterisi için kullanım hakkı, kota ve entitlement preview ekranını kurar.

## Kapsam

342.1 Kullanım hakkı / kota app shell  
342.2 Tenant / merchant / plan context  
342.3 Entitlement özet kartları  
342.4 Ürün limiti kota kartı  
342.5 Kullanıcı limiti kota kartı  
342.6 Mağaza / şube limiti kota kartı  
342.7 POS cihaz / kasa kota kartı  
342.8 Marketplace görünür ürün kotası  
342.9 API / event / import kota placeholder  
342.10 Kullanım ilerleme barları  
342.11 Kota aşımı uyarı paneli  
342.12 Plan upgrade handoff  
342.13 Enforcement disabled gate  
342.14 Tenant / plan / quota scope guard  
342.15 Quota runtime data contract  
342.16 i18n-ready quota marker  
342.17 SEO / OpenGraph quota placeholder  
342.18 Kullanım hakkı / kota smoke test  

## Teknik karar

Bu adım gerçek enforcement, gerçek billing, gerçek plan değişikliği veya gerçek tahsilat açmaz. Kota/entitlement görünümü, fallback usage snapshot, upgrade handoff ve enforcement disabled gate kurulur.

Sonraki adım:

- 343 — Ödeme / billing ekranı

## Gate

PASS için:

- `panel.pix2pi.com.tr/quota/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Kota app shell, tenant/plan context, entitlement kartları, usage progress, warning panel, upgrade handoff, enforcement disabled gate, scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
