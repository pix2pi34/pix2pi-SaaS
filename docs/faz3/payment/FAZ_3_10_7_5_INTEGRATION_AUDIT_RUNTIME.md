# 120 — FAZ 3-10.7.5 — Entegrasyon audit runtime

## Amaç

Bu adım, ödeme entegrasyon ailesindeki POS, banka tahsilat, mutabakat, iade/iptal, status sync, error/retry ve E2E test kanıtlarını tek audit runtime altında değerlendirir.

## Kapsam

- Audit event registration
- Evidence bundle evaluation
- Required scope coverage check
- Pass / fail / warn counter validation
- Evidence hash guard
- Artifact path guard
- Evidence file path guard
- Fail blocks closure policy
- Warn requires review policy
- Minimum pass count readiness policy
- Production real provider gate closed
- Tenant / correlation / request / idempotency guard

## Required Scopes

- POS provider runtime
- Bank collection runtime
- Reconciliation runtime
- Refund / cancel runtime
- Payment status sync
- Payment error / retry runtime
- Payment integration E2E

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Required scope coverage testleri PASS
- Fail / warn / pass policy testleri PASS
