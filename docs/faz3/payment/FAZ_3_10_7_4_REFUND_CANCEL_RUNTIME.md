# 119 — FAZ 3-10.7.4 — İade / iptal runtime

## Amaç

Bu adım, ödeme runtime ailesi içinde iade, iptal, void ve reversal işlemlerini ayrı runtime olarak mühürler.

## Kapsam

- Prepare refund
- Register refund accepted
- Prepare cancel
- Register cancel accepted
- Prepare void
- Register void accepted
- Prepare reversal
- Register reversal accepted
- Status check
- Partial refund / full refund guard
- Remaining refundable amount guard
- Cancel before capture guard
- Void before settlement guard
- Reversal after settlement guard
- Tenant / correlation / request / idempotency guard
- Provider transaction / provider payload hash guard
- Reason code guard
- TRY currency guard
- Production real payment gate closed

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Refund / cancel / void / reversal path testleri PASS
