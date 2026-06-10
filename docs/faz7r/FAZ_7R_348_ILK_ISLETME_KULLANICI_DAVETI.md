# FAZ 7-R / 348 — İlk işletme kullanıcı daveti

## Amaç

`panel.pix2pi.com.tr/user-invite/` üzerinde ilk işletme kullanıcısı / owner admin daveti için kontrollü davet yüzeyini kurar.

## Kapsam

348.1 İlk kullanıcı daveti app shell  
348.2 Pilot tenant / owner invite context  
348.3 Davet edilecek kullanıcı kimlik formu  
348.4 Owner admin rol seçimi  
348.5 Tenant scope validation  
348.6 E-posta davet kanalı placeholder  
348.7 SMS / WhatsApp davet kanalı placeholder  
348.8 Invite token preview disabled gate  
348.9 Şifre kurulum akışı handoff  
348.10 Davet gönder disabled guard  
348.11 Duplicate invitation guard  
348.12 Invitation audit timeline  
348.13 User activation status preview  
348.14 Invite runtime data contract  
348.15 i18n-ready invite marker  
348.16 SEO / OpenGraph invite placeholder  
348.17 İlk kullanıcı daveti smoke test  

## Teknik karar

Bu adım gerçek e-posta/SMS/WhatsApp gönderimi, gerçek kullanıcı oluşturma, gerçek invite token üretimi veya gerçek şifre setleme açmaz. İlk işletme kullanıcısı davet ekranı, owner role binding, tenant scope, duplicate guard, disabled invite send ve şifre kurulum handoff kurulur.

Sonraki adım:

- 349 — Kullanıcı şifre / giriş akışı

## Gate

PASS için:

- `panel.pix2pi.com.tr/user-invite/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Invite app shell, tenant/owner context, user form, role selection, tenant scope validation, email/SMS placeholders, invite token disabled gate, password setup handoff, invite send disabled guard, duplicate guard, audit timeline, activation preview, runtime contract, i18n ve SEO marker'ları bulunmalı.
