# 154 — FAZ 3-10.8.2 — Vergi smoke

## Amaç

Türkiye vergi runtime zincirinin hızlı smoke doğrulamasını yapar.

## Kapsam

- KDV runtime smoke
- Stopaj runtime smoke
- Vergi istisna / muafiyet runtime smoke
- Vergi rule version rollout smoke
- Vergi audit persistence smoke
- Vergi runtime tests smoke
- Tenant / correlation / idempotency guard kontrolü
- TRY currency guard kontrolü
- TDHP vergi hesap izleri kontrolü
- Audit hash kontrolü
- Real external closed kontrolü
- Smoke hash üretimi

## Canlı Politika

Bu smoke gerçek dış vergi/GİB çağrısı yapmaz. Vergi runtime zincirinin hazır olduğunu doğrular; production activation değildir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Vergi alt paket Go testleri PASS
- Smoke Go test PASS
- Real implementation audit PASS
- PASS_COUNT minimumu geçer
- FAIL_COUNT=0
