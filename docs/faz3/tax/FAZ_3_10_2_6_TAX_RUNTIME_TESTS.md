# 127 — FAZ 3-10.2.6 — Vergi runtime testleri

## Amaç

Bu adım, Türkiye vergi runtime ailesini uçtan uca test eder.

## Kapsam

- KDV runtime execution
- Stopaj runtime execution
- Tax exemption runtime execution
- Tax rule version rollout
- Tax audit persistence
- Audit trail export
- Failure path protection

## Test Senaryoları

1. KDV hesaplama → Stopaj hesaplama → İstisna hesaplama → Rule rollout prepare → Audit persistence → Audit export
2. Failure path:
   - KDV currency mismatch
   - Stopaj tenant missing
   - Exemption reason missing
   - Canary allowlist missing
   - Audit duplicate idempotency

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Suite dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- E2E happy path ve failure path testleri PASS
