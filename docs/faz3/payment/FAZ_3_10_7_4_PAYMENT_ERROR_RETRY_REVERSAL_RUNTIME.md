# 120 — FAZ 3-10.7.4 — Payment error / retry / reversal runtime

## Amaç

Bu adım, POS provider runtime, bank collection runtime ve payment status sync sonrasında ödeme hataları, retry kararları, DLQ, manuel inceleme ve reversal lifecycle karar runtime'ını oluşturur.

## Kapsam

- Payment provider error event modeli
- Retry decision modeli
- Reversal request modeli
- Reversal decision modeli
- Retryable / non-retryable / duplicate / manual-review sınıflandırması
- Bounded retry backoff
- Max retry sonrası DLQ kararı
- Reversal prepare
- Reversal accepted registration
- Production real payment gate
- Tenant / correlation / request / idempotency guard
- Payment transaction guard
- Provider transaction guard
- Provider payload hash guard
- Reversal reason guard
- POS / Virtual POS / Bank collection / Bank transfer / Marketplace settlement desteği

## Production Politikası

Bu faz gerçek banka/POS sağlayıcısına canlı ödeme, retry veya reversal çağrısı yapmaz.

Canlı ödeme kapalıdır:

- `real_payment_gate_open=false`
- `production_approved=false`
- raw secret tutulmaz
- credential reference kullanılır

Gerçek banka/POS canlı modülü provider sözleşmesi, mali/hukuki/güvenlik onayı, secret yönetimi ve rollback onayından sonra ayrı açılır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Retry / DLQ / manual review / duplicate / reversal path testleri PASS
