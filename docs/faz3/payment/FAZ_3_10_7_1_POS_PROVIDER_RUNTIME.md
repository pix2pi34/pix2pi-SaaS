# 117 — FAZ 3-10.7.1 — POS provider runtime

## Amaç

Bu adım, Türkiye ödeme / POS / banka runtime ailesi için POS provider runtime temelini oluşturur.

## Kapsam

- POS provider config modeli
- POS request modeli
- POS response modeli
- POSProviderAdapter interface
- Authorize
- Capture
- Sale
- Refund
- Void
- Status check
- 3DS init
- 3DS complete
- Production real payment gate
- Tenant / correlation / request / idempotency guard
- Merchant / terminal guard
- Provider code mismatch guard
- Masked PAN guard
- Card token guard
- Refund reason guard
- Void reason guard
- Simulation / sandbox safe runtime

## Production Politikası

Bu faz gerçek banka/POS sağlayıcısına canlı ödeme çağrısı yapmaz.

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
- Production real payment gate kapalı
