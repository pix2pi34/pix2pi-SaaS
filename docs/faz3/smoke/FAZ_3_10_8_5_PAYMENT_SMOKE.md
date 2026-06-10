# 156 — FAZ 3-10.8.5 — Ödeme smoke

## Amaç

Türkiye ödeme runtime zincirinin hızlı smoke doğrulamasını yapar.

## Kapsam

- POS provider runtime smoke
- Banka tahsilat runtime smoke
- Mutabakat runtime smoke
- İade / iptal runtime smoke
- Payment status sync smoke
- Payment error / retry / reversal smoke
- Payment integration audit runtime smoke
- Payment integration tests smoke
- Tenant / correlation / idempotency guard kontrolü
- Real payment gate closed kontrolü
- Real bank gate closed kontrolü
- Production approved false kontrolü
- Smoke hash üretimi

## Canlı Politika

Bu smoke gerçek ödeme, gerçek banka, gerçek POS veya canlı ödeme sağlayıcı çağrısı yapmaz. Ödeme zincirinin hazır olduğunu doğrular; production activation değildir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Payment alt paket Go testleri PASS
- Smoke Go test PASS
- Real implementation audit PASS
- PASS_COUNT minimumu geçer
- FAIL_COUNT=0
