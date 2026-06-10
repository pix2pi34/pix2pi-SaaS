# 121 — FAZ 3-10.7.6 — Ödeme entegrasyon testleri

## Amaç

Bu adım, ödeme entegrasyon ailesindeki runtime parçalarını uçtan uca test paketiyle doğrular.

## Kapsam

- POS provider runtime
- Bank collection runtime
- Reconciliation runtime
- Refund / cancel runtime
- Payment status sync
- Payment error / retry runtime
- Integration audit runtime

## Test Senaryoları

1. POS sale → status sync → refund → refund reconciliation → retry decision → audit bundle
2. Bank transfer → bank statement match → bank reconciliation → manual status recheck
3. Failure path: invalid POS masked PAN, reconciliation difference review, audit missing scope blocks closure

## Üretim Politikası

Bu test gerçek banka/POS çağrısı yapmaz.

- real payment gate kapalı
- real bank gate kapalı
- production approved false
- simulation-only provider akışı

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Integration suite dosyası var
- Integration test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- E2E happy path ve failure path testleri PASS
