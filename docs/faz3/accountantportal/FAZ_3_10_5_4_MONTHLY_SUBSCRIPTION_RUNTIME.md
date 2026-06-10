# 143 — FAZ 3-10.5.4 — Aylık abonelik runtime

## Amaç

Muhasebeci portalında aylık abonelik yaşam döngüsünü runtime seviyesinde yönetir.

## Kapsam

- Subscription plan modeli
- Subscription account modeli
- Subscription command request modeli
- Subscription decision modeli
- Access check request modeli
- Trial başlatma
- Aylık abonelik aktivasyonu
- Aylık yenileme
- Plan değiştirme
- Askıya alma
- Devam ettirme
- İptal
- Abonelik erişim kontrolü
- Tenant scope guard
- Billing profile guard
- Monthly billing cycle guard
- Firm limit guard
- Audit actor guard
- Decision hash üretimi

## Canlı Politika

Bu runtime gerçek ödeme tahsilatı yapmaz. Muhasebeci portal abonelik state ve yetki karar çekirdeğidir. Gerçek billing/payment provider bağlantısı ayrı production-live aşamasına bırakılır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Trial path PASS
- Activate path PASS
- Renew path PASS
- Change plan path PASS
- Suspend/resume/cancel path PASS
- Access check path PASS
- Negative guard path PASS
