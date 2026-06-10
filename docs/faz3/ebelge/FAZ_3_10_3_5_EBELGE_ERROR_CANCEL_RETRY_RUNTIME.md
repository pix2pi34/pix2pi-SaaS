# 115 — FAZ 3-10.3.5 — e-Belge error / cancel / retry runtime

## Amaç

Bu adım, e-Belge provider family sonrasında hata sınıflandırma, retry planlama, DLQ kararı, manuel inceleme kararı ve cancel lifecycle karar runtime'ını oluşturur.

## Kapsam

- Provider error event modeli
- Retry decision modeli
- Cancel request modeli
- Cancel decision modeli
- Retryable / non-retryable / duplicate / manual-review error sınıflandırması
- Bounded retry backoff
- Max retry sonrası DLQ kararı
- Cancel reason guard
- Tenant / correlation / request / idempotency guard
- Provider document guard
- Provider payload hash guard
- e-Fatura / e-Arşiv / e-Adisyon desteği

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Retry / DLQ / manual review / cancel path testleri PASS
