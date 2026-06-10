# 132 — FAZ 3-10.1.5 — TDHP reconciliation runtime

## Amaç

TDHP belge/fiş/posting/ledger zincirinde tutar mutabakatı sağlar.

## Kapsam

- Reconciliation request modeli
- Reconciliation result modeli
- Expected debit/credit balance guard
- Actual debit/credit balance guard
- Posting hash guard
- Audit trace hash guard
- Ledger ready guard
- Currency guard
- Difference review decision
- Result hash üretimi

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- FAIL_COUNT=0
