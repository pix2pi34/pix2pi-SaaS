# 130 — FAZ 3-10.1.3 — Belge bazlı posting runtime

## Amaç

Bu adım, 128 gerçek fiş pipeline çıktısı olan voucher'ı append-only ledger posting entry haline getirir.

## Kapsam

- Posting request modeli
- Posting entry modeli
- Posting line modeli
- Posting repository contract
- In-memory repository implementation
- Prepare posting
- Post document
- Reverse posting
- Tenant-scoped lookup
- Tenant-scoped document listing
- Idempotency uniqueness guard
- Posting ID uniqueness guard
- Voucher posting-ready guard
- Voucher balanced guard
- Debit / credit totals guard
- Line account guard
- Audit trace guard
- Append-only ledger guard

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Prepare / post / reverse / duplicate / tenant-scope / invalid path testleri PASS
