# 133 — FAZ 3-10.1.6 — TDHP live testleri

## Amaç

Bu adım, TDHP core runtime zincirinin canlıya hazır şekilde uçtan uca çalıştığını test eder.

## Kapsam

- Hesap planı live version switch
- Account resolve
- Gerçek fiş oluşturma pipeline
- Belge bazlı posting runtime
- Audit trace persistence
- Reconciliation runtime
- Audit trace export
- Difference detection
- Currency mismatch rejection
- Missing audit trace rejection

## Canlı Politika

Bu adım dış sisteme gerçek çağrı yapmaz. Live-ready simulation modunda TDHP internal runtime zincirini test eder.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Suite dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Sales invoice E2E PASS
- Purchase invoice E2E PASS
- Audit export PASS
- Difference scenario PASS
- Negative guard tests PASS
