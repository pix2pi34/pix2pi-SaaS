# FAZ 7-R / 347 — Pilot müşteri tenant açılışı gerçek provisioning

## Amaç

319 işletme onboarding kaydından sonra pilot müşterinin tenant config, varsayılan dil, varsayılan paket, şube ve kasa başlangıç kurulumunu gerçek runtime ve DB kayıt sözleşmesiyle tamamlamak.

## Kapsam

347 Pilot müşteri tenant açılışı

Bu adımda kurulan parçalar:

- Pilot tenant config kaydı
- Varsayılan dil tr-TR kaydı
- Varsayılan paket kaydı
- İlk şube kaydı
- İlk kasa / register kaydı
- Owner membership doğrulama
- Tenant provisioning run kaydı
- Tenant opening audit event kaydı
- Panel pilot tenant opening ekranı
- Go unit testleri
- Panel smoke testleri

## PASS şartı

- Tenant ID zorunlu olmalı.
- Owner user ID zorunlu olmalı.
- Varsayılan dil tr-TR olmalı.
- Varsayılan paket boş olmamalı.
- Şube adı boş olmamalı.
- Kasa adı boş olmamalı.
- Tenant config kaydı oluşmalı.
- Plan binding kaydı oluşmalı.
- Branch kaydı oluşmalı.
- Register kaydı oluşmalı.
- Owner membership doğrulanmalı.
- Provisioning run completed olmalı.
- Audit event correlation ID ile kaydedilmeli.
- Panel route HTTP 200 dönmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Canlı URL

- https://panel.pix2pi.com.tr/pilot-tenant-opening/

## Sonraki iş

FAZ 7-R / 348 — İlk işletme kullanıcı daveti gerçek invite akışı
