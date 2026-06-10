# FAZ 7-R / 319 — İşletme onboarding ekranı

## Amaç

`panel.pix2pi.com.tr` üzerinde yeni işletme/merchant ilk kurulum ekranını hazırlar.

## Kapsam

319.1 Onboarding app shell  
319.2 İşletme kimlik bilgileri  
319.3 Vergi / ticari kayıt bilgileri  
319.4 Adres / iletişim bilgileri  
319.5 Tenant default language seçimi  
319.6 Owner / ilk yönetici bilgisi  
319.7 Onboarding validation contract  
319.8 Tenant bootstrap payload contract  
319.9 Draft save / continue later davranışı  
319.10 Onboarding smoke test  

## Teknik karar

Bu adım gerçek tenant oluşturma backend çağrısını production olarak açmaz. Panel frontend onboarding sözleşmesini, ekranını, validation runtime'ını ve bootstrap payload standardını kurar.

Backend entegrasyon endpoint sözleşmesi:

- Draft save: `/api/onboarding/business/draft`
- Submit: `/api/onboarding/business/submit`
- Tenant bootstrap payload key: `pix2pi.panel.onboarding.draft`
- Default language integration: 318 i18n registry ile uyumlu

## Gate

PASS için:

- `/onboarding/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Form step marker'ları bulunmalı.
- Tenant default language alanı bulunmalı.
- Tax/contact/owner validation marker'ları bulunmalı.
- Draft save runtime bulunmalı.
- Bootstrap payload runtime bulunmalı.
