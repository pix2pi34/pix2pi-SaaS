# FAZ 7-R / 354 — Localization customer smoke

## Amaç

`panel.pix2pi.com.tr/localization-customer-smoke/` üzerinde kontrollü müşteri açılışı öncesi dil / alfabe / yön / format müşteri smoke yüzeyini kurar.

## Kapsam

354.1 Localization customer smoke app shell  
354.2 Tenant default language context  
354.3 User language preference context  
354.4 Language registry smoke  
354.5 Latin Türkçe smoke — tr-TR  
354.6 Osmanlıca Türkçesi / Arap harfli Türkçe smoke — ota / tr-Arab  
354.7 Arapça smoke — ar  
354.8 Farsça smoke — fa  
354.9 İngilizce smoke — en  
354.10 Ahmed Hüsrev Altınbaşak hat referansı binding check  
354.11 RTL / LTR layout smoke  
354.12 Date / time / number / currency format smoke  
354.13 Panel / POS / Marketplace localization readiness  
354.14 Notification / email / error localization readiness  
354.15 Missing translation fallback preview  
354.16 Hardcoded UI text guard preview  
354.17 Translation completeness customer smoke  
354.18 Localization audit timeline  
354.19 Localization runtime data contract  
354.20 i18n-ready smoke marker  
354.21 SEO / OpenGraph localization placeholder  
354.22 Localization customer smoke test  

## Teknik karar

Bu adım gerçek production müşteri dil ayarını değiştirmez. FAZ 7-R / 318 i18n altyapısı üstünden müşteri smoke preview kurar. Osmanlıca / Arapça / Farsça için Ahmed Hüsrev Altınbaşak referansı sadece `https://oku.risale.online/osm` olarak bağlanır; başka hat referans kaynağı kullanılmaz.

Sonraki adım:

- 355 — İlk gerçek kullanım smoke testi

## Gate

PASS için:

- `panel.pix2pi.com.tr/localization-customer-smoke/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- tr-TR, ota/tr-Arab, ar, fa, en dilleri; RTL/LTR; format; panel/POS/marketplace readiness; notification/email/error readiness; fallback; hardcoded text guard; translation completeness; Ahmed Hüsrev reference binding; runtime contract; i18n ve SEO marker'ları bulunmalı.
