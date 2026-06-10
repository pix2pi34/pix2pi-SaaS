# 118 — FAZ 3-10.7.3 — Mutabakat runtime

## Amaç

Bu adım, ödeme runtime ailesi içinde mutabakat işlemlerini ayrı runtime olarak mühürler.

## Kapsam

- POS / Virtual POS ödeme capture mutabakatı
- Banka ekstresi mutabakatı
- Marketplace settlement mutabakatı
- Refund / reversal mutabakatı
- Manual review register
- Amount difference / tolerance hesaplama
- Net settlement hesaplama
- Ledger posting readiness
- Payment closure readiness
- Tenant / correlation / request / idempotency guard
- Provider transaction guard
- Provider payload hash guard
- Bank account / bank reference / statement hash guard
- Marketplace settlement id guard
- TRY currency guard

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Mutabakat matched / difference review / manual review path testleri PASS
