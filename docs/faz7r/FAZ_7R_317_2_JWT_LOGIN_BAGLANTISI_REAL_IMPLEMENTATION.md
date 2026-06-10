# FAZ 7-R / 317.2 — JWT login bağlantısı gerçek implementasyon

## Amaç

Panel login akışında kullanılacak gerçek JWT üretme, doğrulama, tenant membership kontrolü ve login session kayıt sözleşmesini kurmak.

## Kapsam

317.2 JWT login bağlantısı

Bu adımda kurulan gerçek parçalar:

- HS256 JWT imzalama
- JWT doğrulama
- Access token claim standardı
- Refresh token claim standardı
- Tenant membership kontrolü
- User store arayüzü
- Password verifier arayüzü
- Login session kayıt sözleşmesi
- Session expiry hesabı
- Unauthorized / forbidden hata tipleri
- Unit testleri

## PASS şartı

- Go runtime dosyası gerçek token üretmeli.
- Go test gerçek token doğrulamalı.
- Tenant membership yoksa login izin vermemeli.
- Hatalı şifre login izin vermemeli.
- Expired token doğrulanmamalı.
- Evidence sayaçları gerçek kontrol sonucundan gelmeli.

## Sonraki iş

FAZ 7-R / 317.3 — Tenant selection screen gerçek tenant akışı
