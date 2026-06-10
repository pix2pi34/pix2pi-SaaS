# FAZ 7-R / 349 — Kullanıcı şifre / giriş akışı

## Amaç

`panel.pix2pi.com.tr/password-login/` üzerinde ilk işletme kullanıcısı için şifre kurulum ve giriş akışı hazırlık yüzeyini kurar.

## Kapsam

349.1 Şifre / giriş app shell  
349.2 Invite token / user activation context  
349.3 Şifre kurulum formu  
349.4 Şifre politika kontrolü  
349.5 Şifre tekrar doğrulama  
349.6 İlk giriş formu  
349.7 JWT issuance disabled gate  
349.8 Session creation disabled gate  
349.9 Password reset placeholder  
349.10 MFA / OTP placeholder  
349.11 Login error state preview  
349.12 First login handoff to panel access test  
349.13 Auth audit timeline  
349.14 Tenant / user / auth scope guard  
349.15 Auth runtime data contract  
349.16 i18n-ready auth marker  
349.17 SEO / OpenGraph auth placeholder  
349.18 Kullanıcı şifre / giriş smoke test  

## Teknik karar

Bu adım gerçek parola kaydı, gerçek JWT üretimi, gerçek session oluşturma, gerçek e-posta doğrulama veya gerçek MFA açmaz. Şifre kurulum UI, login preview, policy validation, disabled auth gates ve 350 panel erişim testi handoff kurulur.

Sonraki adım:

- 350 — Panel erişim testi

## Gate

PASS için:

- `panel.pix2pi.com.tr/password-login/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Şifre/giriş app shell, invite/user activation context, şifre formu, policy checker, confirm validation, login form, JWT/session disabled gates, reset/MFA placeholders, login error preview, panel access handoff, audit timeline, auth scope guard, runtime contract, i18n ve SEO marker'ları bulunmalı.
