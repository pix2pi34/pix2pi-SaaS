# 122 — FAZ 3-10.2.2 — Stopaj runtime execution

## Amaç

Bu adım, Türkiye vergi runtime ailesi için stopaj hesaplama runtime'ını oluşturur.

## Kapsam

- Stopaj runtime config
- Stopaj kural modeli
- Stopaj request modeli
- Stopaj result modeli
- Active rule version kontrolü
- Effective date kontrolü
- Stopaj oranı bps üzerinden hesaplama
- Minimum matrah altında not-applied kararı
- İstisna / muafiyet guard
- Tenant / correlation / request / idempotency guard
- Belge / cari / vergi no guard
- Matrah / brüt tutar guard
- TRY currency guard
- Audit action / decision reason üretimi

## Desteklenen Konular

- Kira stopajı
- Serbest meslek / profesyonel hizmet
- Freelance
- İnşaat
- Temettü
- Custom

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Stopaj applied / not-applied / exemption / invalid path testleri PASS
