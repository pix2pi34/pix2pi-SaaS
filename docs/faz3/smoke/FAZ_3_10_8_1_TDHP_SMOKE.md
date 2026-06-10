# 153 — FAZ 3-10.8.1 — TDHP smoke

## Amaç

TDHP runtime zincirinin hızlı smoke doğrulamasını yapar.

## Kapsam

- Gerçek fiş oluşturma pipeline smoke
- Hesap planı live version switch smoke
- Belge bazlı posting runtime smoke
- Audit trace persistence smoke
- TDHP reconciliation runtime smoke
- TDHP live tests smoke
- Tenant / correlation / idempotency guard kontrolü
- TDHP hesap izleri kontrolü
- Voucher balanced / posting ready kontrolü
- Audit hash kontrolü
- Real external closed kontrolü
- Smoke hash üretimi

## Canlı Politika

Bu smoke gerçek dış sisteme çağrı yapmaz. TDHP runtime zincirinin hazır olduğunu doğrular; production activation değildir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- TDHP alt paket Go testleri PASS
- Smoke Go test PASS
- Real implementation audit PASS
- PASS_COUNT minimumu geçer
- FAIL_COUNT=0
