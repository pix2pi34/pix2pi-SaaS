# 114 — FAZ 3-10.3.4 — Belge durum callback / poll senkronu

## Amaç

Bu adım, e-Belge provider family sonrasında belge durumlarının callback ve poll üzerinden senkronize edilmesi için runtime temelini oluşturur.

## Kapsam

- Callback status sync
- Poll status sync
- Poll candidate planning
- Provider status → canonical status mapping
- Tenant guard
- Correlation guard
- Request guard
- Idempotency guard
- Provider document guard
- Provider payload hash guard
- Callback signature guard
- Retry scheduling hint
- Audit action / decision reason üretimi

## Desteklenen Belge Türleri

- e-Fatura
- e-Arşiv
- e-Adisyon

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Callback ve poll path ayrı doğrulanır
