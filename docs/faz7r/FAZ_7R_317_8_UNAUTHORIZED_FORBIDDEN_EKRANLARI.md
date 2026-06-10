# FAZ 7-R / 317.8 — Unauthorized / forbidden ekranları

## Amaç

Login, tenant selection, session validation ve permission akışlarında 401/403 durumlarını standart erişim reddi karar modeli, audit event ve panel ekranlarıyla yönetmek.

## Kapsam

317.8 Unauthorized / forbidden ekranları

Bu adımda kurulan gerçek parçalar:

- 401 unauthorized karar modeli
- 403 forbidden karar modeli
- Access denial event kayıt sözleşmesi
- Correlation ID standardı
- Tenant / user / role / route context taşıma
- Güvenli kullanıcı mesajı
- Panel unauthorized ekranı
- Panel forbidden ekranı
- Panel access denial runtime
- Go unit testleri
- Panel smoke testleri

## PASS şartı

- Unauthorized kararları HTTP 401 ile eşleşmeli.
- Forbidden kararları HTTP 403 ile eşleşmeli.
- Access denial event correlation ID ile kaydedilmeli.
- Kullanıcıya güvenli mesaj dönmeli.
- Unauthorized ve forbidden ekranları canlı panel route üzerinde 200 dönmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Canlı URL

- https://panel.pix2pi.com.tr/unauthorized/
- https://panel.pix2pi.com.tr/forbidden/

## Sonraki iş

FAZ 7-R / 317.9 — Login smoke test gerçek E2E
