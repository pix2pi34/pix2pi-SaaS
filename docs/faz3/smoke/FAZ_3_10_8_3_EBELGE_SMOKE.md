# 151 — FAZ 3-10.8.3 — e-Belge smoke

## Amaç

FAZ 3 e-Belge ailesinin hızlı smoke doğrulamasını yapar.

## Kapsam

- e-Fatura provider smoke
- e-Arşiv provider smoke
- e-Adisyon provider smoke
- e-Belge status sync smoke
- e-Belge error / cancel / retry smoke
- e-Belge live integration tests smoke
- Production real provider gate closed kontrolü
- Tenant / correlation / idempotency guard kontrolü
- Status callback / poll coverage kontrolü
- Retry / DLQ coverage kontrolü
- Smoke hash üretimi

## Canlı Politika

Bu smoke gerçek GİB veya özel entegratör çağrısı yapmaz. Gerçek provider API gate kapalı kalır. Canlı entegrasyon gerçek onay ve provider-live modülü gelene kadar kapalıdır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- e-Belge alt paket Go testleri PASS
- Smoke Go test PASS
- Real implementation audit PASS
- PASS_COUNT > minimum
- FAIL_COUNT=0
