# 155 — FAZ 3-10.8.4 — Export smoke

## Amaç

Türkiye muhasebe export ailesinin hızlı smoke doğrulamasını yapar.

## Kapsam

- ETA gerçek format üretimi smoke
- Logo gerçek format üretimi smoke
- Mikro gerçek format üretimi smoke
- Zirve gerçek format üretimi smoke
- Format validation matrix smoke
- Export adapter tests smoke
- Tenant / correlation / idempotency guard kontrolü
- Target system / format version guard kontrolü
- Posting hash / audit trace guard kontrolü
- Package hash / file hash kontrolü
- Journal / ledger / summary file coverage kontrolü
- Real delivery closed kontrolü
- Smoke hash üretimi

## Canlı Politika

Bu smoke gerçek muhasebe programına dosya göndermez. Export dosya üretim ve adapter test zincirinin hazır olduğunu doğrular; production activation değildir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Export alt paket Go testleri PASS
- Smoke Go test PASS
- Real implementation audit PASS
- PASS_COUNT minimumu geçer
- FAIL_COUNT=0
