# 123 — FAZ 3-10.2.3 — Tax exemption runtime execution

## Amaç

Bu adım, Türkiye vergi runtime ailesi için vergi istisna / muafiyet / oran override runtime'ını oluşturur.

## Kapsam

- Tax exemption runtime config
- Exemption rule modeli
- Exemption request modeli
- Exemption result modeli
- Active rule version kontrolü
- Effective date kontrolü
- Full exemption
- Partial exemption
- Rate override
- Zero rate
- Minimum matrah altında not-applied kararı
- Exemption reason required guard
- Tenant / correlation / request / idempotency guard
- Belge / cari / vergi no guard
- Matrah / brüt tutar guard
- TRY currency guard
- Audit action / decision reason üretimi

## Desteklenen Vergi Türleri

- KDV
- Stopaj
- ÖTV
- Damga
- Custom

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Full exemption / partial exemption / rate override / invalid path testleri PASS
