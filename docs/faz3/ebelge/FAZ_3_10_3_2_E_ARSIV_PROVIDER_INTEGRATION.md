# 111 — FAZ 3-10.3.2 — e-Arşiv provider entegrasyonu

## Amaç

Bu adım, e-Arşiv provider entegrasyonu için provider bağımsız runtime adapter temelini oluşturur.

## Kapsam

- Provider config modeli
- Provider request modeli
- Provider response modeli
- ProviderAdapter interface
- SendArchive
- CheckStatus
- CancelArchive
- DownloadPDF
- DownloadUBL
- Production real API gate
- Tenant / correlation / request / idempotency guard
- UBL hash zorunluluğu
- PDF hash zorunluluğu
- Cancel reason guard
- Simulation / sandbox safe runtime

## Production Politikası

Bu faz gerçek GİB veya özel entegratör canlı API çağrısı yapmaz.

Canlı provider API kapalıdır:

- `real_api_gate_open=false`
- `production_approved=false`
- raw secret tutulmaz
- credential reference kullanılır

Gerçek provider canlı entegrasyonu, provider sözleşmesi / hukuk / mali / güvenlik / secret / rollback onaylarından sonra ayrı live module olarak açılır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Production provider gate kapalı
