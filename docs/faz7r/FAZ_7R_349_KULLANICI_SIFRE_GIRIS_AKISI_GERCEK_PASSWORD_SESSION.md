# FAZ 7-R / 349 — Kullanıcı şifre / giriş akışı gerçek password/session

## Amaç

İlk şifre oluşturma, şifre sıfırlama, e-posta/şifre ile giriş, tenant seçimi yönlendirmesi ve session validation zincirini gerçek runtime sözleşmesiyle kapatmak.

## Kapsam

349 Kullanıcı şifre / giriş akışı

Bu adımda kurulan gerçek parçalar:

- İlk şifre oluşturma
- Şifre politika kontrolü
- Şifre hash standardı
- Şifre sıfırlama token akışı
- E-posta / şifre login doğrulaması
- Tenant zorunluluğu
- Login session üretimi
- Session validation
- Login sonrası tenant seçimi yönlendirmesi
- Password flow audit event sözleşmesi
- Panel password-login ekranı
- Go unit testleri
- Panel smoke testleri

## PASS şartı

- Invite token ile ilk şifre oluşturulmalı.
- Zayıf şifre kabul edilmemeli.
- Şifre tekrar alanı eşleşmeli.
- Şifre sıfırlama tokenı ile yeni şifre kaydedilmeli.
- Hatalı şifre login üretmemeli.
- Doğru şifre login session üretmeli.
- Tenant ID olmadan login tamamlanmamalı.
- Session validation access token ID ile çalışmalı.
- Panel password-login route HTTP 200 dönmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Canlı URL

- https://panel.pix2pi.com.tr/password-login/

## Sonraki iş

FAZ 7-R / 350 — Panel erişim testi gerçek auth ile
