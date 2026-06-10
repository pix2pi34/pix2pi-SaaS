# 126 — FAZ 3-10.2.5 — Vergi audit persistence

## Amaç

Bu adım, KDV / Stopaj / Tax Exemption / Rule Rollout runtime kararlarının audit kayıtlarını append-only persistence contract ile tutar.

## Kapsam

- Tax audit record modeli
- Tax audit export modeli
- Tax audit repository contract
- In-memory repository implementation
- Append-only audit persistence
- Tenant-scoped lookup
- Tenant-scoped export
- Idempotency uniqueness guard
- Audit ID uniqueness guard
- Evidence file / hash guard
- Request hash / result hash guard
- Rule version guard
- Actor guard
- Amount non-negative guard
- KDV / Stopaj / Tax Exemption / Rollout audit action support
- Export aggregation totals
- Export hash üretimi

## Production Notu

Bu faz DB migration değildir. Runtime persistence contract ve test edilebilir repository davranışı kurulur. Gerçek PostgreSQL persistence gerekiyorsa sonraki DB/persistence implementation dalında ayrı migration ile bağlanır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Append-only / idempotency / tenant scope / export / validation testleri PASS
