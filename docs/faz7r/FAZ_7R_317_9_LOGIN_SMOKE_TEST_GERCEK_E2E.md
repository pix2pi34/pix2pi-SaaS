# FAZ 7-R / 317.9 — Login smoke test gerçek E2E

## Amaç

317 login / tenant seçimi zincirinin gerçek runtime parçalarını tek E2E smoke içinde doğrulamak.

## Kapsam

317.9 Login smoke test

Bu adımda doğrulanan gerçek parçalar:

- 317.2 JWT login bağlantısı
- 317.3 Tenant selection screen gerçek tenant akışı
- 317.4 Multi-tenant user destek
- 317.5 Remember tenant preference
- 317.6 Session timeout davranışı
- 317.7 Login error messages
- 317.8 Unauthorized / forbidden ekranları
- Panel canlı route smoke

## PASS şartı

- Doğru e-posta/şifre ile access token ve refresh token oluşmalı.
- Access token ile tenant listesi alınmalı.
- Tenant seçimi membership kontrolüyle yapılmalı.
- Multi-tenant switch çalışmalı.
- Tenant preference kaydedilmeli ve geri yüklenmeli.
- Session validation last seen bilgisini güncellemeli.
- Logout session revoke etmeli.
- Hatalı şifre güvenli login error mesajına dönüşmeli.
- Unauthorized ve forbidden kararları doğru HTTP status üretmeli.
- Panel login / tenant-select / unauthorized / forbidden URL’leri HTTP 200 dönmeli.
- Go test gerçek E2E zinciri doğrulamalı.

## Canlı URL

- https://panel.pix2pi.com.tr/login/
- https://panel.pix2pi.com.tr/tenant-select/
- https://panel.pix2pi.com.tr/unauthorized/
- https://panel.pix2pi.com.tr/forbidden/

## Sonraki iş

FAZ 7-R / 349 — Kullanıcı şifre / giriş akışı gerçek password/session
