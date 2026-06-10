# FAZ 7-R / 317.6 — Session timeout gerçek davranış

## Amaç

Login sonrası oluşan oturumların access expiry, refresh expiry, idle timeout, absolute timeout, session touch ve logout davranışlarını gerçek runtime sözleşmesiyle kurmak.

## Kapsam

317.6 Session timeout davranışı

Bu adımda kurulan gerçek parçalar:

- Oturum kayıt modeli
- Access token süresi kontrolü
- Refresh token süresi kontrolü
- Idle timeout kontrolü
- Absolute timeout kontrolü
- Session touch / last seen update
- Logout / revoke sözleşmesi
- Timeout event audit sözleşmesi
- HTTP validation handler sözleşmesi
- Go unit testleri

## PASS şartı

- Süresi geçmiş access token kabul edilmemeli.
- Refresh süresi geçmiş oturum kabul edilmemeli.
- Idle timeout aşılmış oturum kabul edilmemeli.
- Absolute timeout aşılmış oturum kabul edilmemeli.
- Revoked oturum kabul edilmemeli.
- Geçerli oturum last seen bilgisini güncellemeli.
- Logout oturumu revoke etmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Sonraki iş

FAZ 7-R / 317.7 — Login error messages gerçek hata mesajları
