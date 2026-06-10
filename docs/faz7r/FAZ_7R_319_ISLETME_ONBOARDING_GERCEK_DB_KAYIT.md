# FAZ 7-R / 319 — İşletme onboarding ekranı gerçek DB kayıt akışı

## Amaç

İşletme onboarding formundan gelen işletme adı, vergi/TCKN, adres, sektör, şube, para birimi, dil ve ilk kullanıcı rolünü gerçek tenant onboarding kayıt sözleşmesine bağlamak.

## Kapsam

319 İşletme onboarding ekranı

Bu adımda kurulan parçalar:

- İşletme adı doğrulama
- Vergi numarası / TCKN doğrulama
- Adres doğrulama
- Sektör seçimi doğrulama
- İlk şube bilgisi
- Varsayılan para birimi
- Varsayılan dil
- İlk kullanıcı rolü
- Onboarding tamamlandı işareti
- Tenant slug üretimi
- Legal entity kaydı
- Branch kaydı
- Owner role binding kaydı
- Onboarding audit event kaydı
- Panel onboarding ekranı
- Go unit testleri
- Panel smoke testleri

## PASS şartı

- Eksik işletme adı kabul edilmemeli.
- Geçersiz vergi/TCKN kabul edilmemeli.
- Eksik adres kabul edilmemeli.
- Desteklenmeyen dil kabul edilmemeli.
- Desteklenmeyen para birimi kabul edilmemeli.
- Onboarding tamamlandığında tenant, legal entity, branch ve owner role binding kayıtları üretilmeli.
- Tenant slug deterministik üretilmeli.
- Onboarding audit event correlation ID ile kaydedilmeli.
- Panel onboarding route HTTP 200 dönmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Canlı URL

- https://panel.pix2pi.com.tr/onboarding/

## Sonraki iş

FAZ 7-R / 347 — Pilot müşteri tenant açılışı gerçek provisioning
