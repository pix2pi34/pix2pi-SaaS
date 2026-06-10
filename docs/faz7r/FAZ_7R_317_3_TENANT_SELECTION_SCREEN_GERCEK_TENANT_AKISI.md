# FAZ 7-R / 317.3 — Tenant selection screen gerçek tenant akışı

## Amaç

JWT login sonrası kullanıcının erişebildiği gerçek tenant listesini üretmek, tenant seçimini membership kontrolüyle doğrulamak ve tenant tercih kaydını yapmak.

## Kapsam

317.3 Tenant selection screen

Bu adımda kurulan gerçek parçalar:

- Access token zorunlu tenant listesi
- User ID üzerinden aktif tenant membership listesi
- Tenant durum kontrolü
- Tenant seçimi membership doğrulaması
- Tenant preference kayıt sözleşmesi
- Panel tenant selection ekranı
- API client runtime
- HTTP handler sözleşmesi
- Unit testleri
- Panel smoke testi

## PASS şartı

- Tenant listesi token içindeki user ID ile alınmalı.
- Sadece aktif membership ve aktif tenant döndürülmeli.
- Kullanıcının üye olmadığı tenant seçilememeli.
- Tenant tercihi kayıt fonksiyonu çalışmalı.
- HTTP handler JSON sözleşmesi testten geçmeli.
- Panel ekranı gerçek access token ve API cevabı olmadan tenant üretmemeli.

## Sonraki iş

FAZ 7-R / 317.4 — Multi-tenant user destek gerçek akış
