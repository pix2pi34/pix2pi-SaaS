# 118 — FAZ 3-10.7.2 — Bank collection runtime

## Amaç

Bu adım, Türkiye ödeme / POS / banka runtime ailesi için banka tahsilat, banka ekstresi eşleme, reconciliation, settlement ve reversal runtime temelini oluşturur.

## Kapsam

- Bank collection runtime config
- Collection request / response modeli
- Register bank transfer
- Match bank statement
- Reconcile collection
- Build settlement
- Reverse collection
- Status check
- Production real bank gate
- Tenant / correlation / request / idempotency guard
- Bank account guard
- Provider bank code mismatch guard
- Bank reference guard
- Statement line / payload hash guard
- Reconciliation tolerance guard
- Reverse reason guard
- Simulation / sandbox safe runtime

## Production Politikası

Bu faz gerçek bankaya canlı tahsilat veya settlement çağrısı yapmaz.

Canlı banka erişimi kapalıdır:

- `real_bank_gate_open=false`
- `production_approved=false`
- raw secret tutulmaz
- credential reference kullanılır

Gerçek banka canlı modülü banka sözleşmesi, mali/hukuki/güvenlik onayı, secret yönetimi ve rollback onayından sonra ayrı açılır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Production real bank gate kapalı
