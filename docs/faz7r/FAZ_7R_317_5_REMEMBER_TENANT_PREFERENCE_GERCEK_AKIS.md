# FAZ 7-R / 317.5 — Remember tenant preference gerçek akış

## Amaç

Kullanıcının son seçtiği tenant bilgisini gerçek kalıcı tercih kaydı olarak saklamak ve sonraki login / tenant selection akışında aktif membership kontrolüyle geri yüklemek.

## Kapsam

317.5 Remember tenant preference

Bu adımda kurulan gerçek parçalar:

- Kullanıcı bazlı kalıcı tenant tercih tablosu
- Session bazlı current tenant preference tablosu ile uyum
- Tenant tercih kaydetme runtime fonksiyonu
- Tenant tercih geri yükleme runtime fonksiyonu
- Tercih edilen tenant hâlâ erişilebilir mi kontrolü
- Erişim kalkmışsa ilk aktif tenant seçimi
- Tenant tercih HTTP okuma/yazma sözleşmesi
- Go unit testleri

## PASS şartı

- Kullanıcı tenant seçince kalıcı tercih kaydedilmeli.
- Sonraki login akışında tercih edilen tenant geri dönmeli.
- Kullanıcı artık tenant üyesi değilse tercih kullanılmamalı.
- Aktif tenant yoksa hata dönmeli.
- HTTP okuma/yazma handler testleri geçmeli.
- Go test gerçek runtime davranışını doğrulamalı.

## Sonraki iş

FAZ 7-R / 317.6 — Session timeout gerçek davranış
