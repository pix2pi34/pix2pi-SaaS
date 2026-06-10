# 119 — FAZ 3-10.7.3 — Payment status sync

## Amaç

Bu adım, POS provider runtime ve bank collection runtime sonrasında ödeme durumlarının callback, webhook, poll ve manual recheck üzerinden canonical ödeme statüsüne senkronize edilmesi için runtime temelini oluşturur.

## Kapsam

- Payment status callback sync
- Payment status webhook sync
- Payment status poll sync
- Manual recheck sync
- Poll candidate planning
- Provider payment status → canonical payment status mapping
- POS / Virtual POS / Bank transfer / Bank collection / Marketplace settlement channel desteği
- Tenant guard
- Correlation guard
- Request guard
- Idempotency guard
- Payment transaction guard
- Provider transaction guard
- Provider payload hash guard
- Callback signature guard
- Webhook signature guard
- Bank collection için bank reference guard
- Retry scheduling hint
- Audit action / decision reason üretimi

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Callback / webhook / poll / manual recheck path ayrı doğrulanır
