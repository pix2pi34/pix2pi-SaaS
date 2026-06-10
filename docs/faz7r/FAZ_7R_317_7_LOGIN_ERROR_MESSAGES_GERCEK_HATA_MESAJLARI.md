# FAZ 7-R / 317.7 — Login error messages gerçek hata mesajları

## Amaç

Login, tenant selection ve session validation akışlarında dönen hata durumlarını standart hata kodu, HTTP status, kullanıcı mesajı ve audit event sözleşmesiyle yönetmek.

## Kapsam

317.7 Login error messages

Bu adımda kurulan gerçek parçalar:

- Login hata kodu kataloğu
- Türkçe ve İngilizce kullanıcı mesajları
- HTTP status eşleme standardı
- Güvenli mesaj / iç hata ayrımı
- Login hata event kayıt sözleşmesi
- Correlation ID taşıma
- Tenant ID ve user ID context desteği
- Validation, credential, tenant, token, session ve rate limit hata aileleri
- Go unit testleri

## PASS şartı

- Her hata kodu HTTP status ile eşleşmeli.
- Her hata kodu tr-TR ve en mesajına sahip olmalı.
- İç hata detayı kullanıcıya sızmamalı.
- Audit event sözleşmesi hata kodunu ve correlation ID değerini taşımalı.
- Bilinmeyen hata güvenli genel hata mesajına dönüşmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Sonraki iş

FAZ 7-R / 317.8 — Unauthorized / forbidden ekranları
