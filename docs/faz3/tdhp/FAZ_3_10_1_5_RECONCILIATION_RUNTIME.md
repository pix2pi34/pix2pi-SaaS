# 132 — FAZ 3-10.1.5 — Reconciliation runtime

## Amaç

Bu adım, TDHP tarafında document / posting / audit trace eşleştirme ve fark tespit runtime'ını kurar.

## Kapsam

- Reconciliation request modeli
- Expected document modeli
- Reconciliation result modeli
- Reconciliation difference modeli
- Reconciliation repository contract
- In-memory repository implementation
- Posting vs document reconciliation
- Posting vs audit trace reconciliation
- Amount difference detection
- Posting hash difference detection
- Tenant-scoped lookup/listing
- Idempotency uniqueness guard
- Reconciliation ID uniqueness guard
- Manual review register
- Ledger closure readiness decision

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Matched / difference / audit trace difference / duplicate / tenant-scope / manual-review / validation testleri PASS
