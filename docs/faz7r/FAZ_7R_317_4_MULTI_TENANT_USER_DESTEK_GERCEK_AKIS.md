# FAZ 7-R / 317.4 — Multi-tenant user destek gerçek akış

## Amaç

Bir kullanıcının birden fazla tenant içinde farklı rollerle çalışmasını gerçek membership, tenant context ve session preference sözleşmesiyle desteklemek.

## Kapsam

317.4 Multi-tenant user destek

Bu adımda kurulan gerçek parçalar:

- User ID üzerinden aktif tenant membership listesi
- Tenant statüsü ile membership statüsü birlikte kontrol edilir
- Aynı user için birden fazla tenant ve farklı rol desteği
- Aktif session için current tenant preference kaydı
- Tenant switch işlemi membership doğrulamasıyla yapılır
- Tenant context resolve fonksiyonu
- Cross-tenant erişim reddi
- DB migration sözleşmesi
- Go unit testleri

## PASS şartı

- Kullanıcı birden fazla aktif tenant görebilmeli.
- Kullanıcı tenant değiştirince session preference kaydedilmeli.
- Üye olmadığı tenant seçilememeli.
- Pasif tenant veya pasif membership sonuçlara girmemeli.
- Current tenant context session üzerinden çözümlenmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Sonraki iş

FAZ 7-R / 317.5 — Remember tenant preference gerçek akış
