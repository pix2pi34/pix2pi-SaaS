# 124 — FAZ 3-10.2.1 — KDV runtime execution

## Amaç

Bu adım, Türkiye vergi runtime ailesi için KDV hesaplama runtime'ını ayrı iş numarasıyla oluşturur.

## Kapsam

- KDV runtime config
- KDV rule modeli
- KDV request modeli
- KDV result modeli
- Active rule version kontrolü
- Effective date kontrolü
- Output KDV
- Input KDV
- Return KDV
- KDV 0 / 1 / 10 / 20 / custom rate code desteği
- BPS bazlı KDV hesaplama
- KDV istisna path
- Reverse charge guard
- TDHP hesap kodu yönlendirme
- Tenant / correlation / request / idempotency guard
- Belge / cari / vergi no guard
- Brüt / net / matrah guard
- TRY currency guard
- Audit action / decision reason üretimi

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- KDV 20 / KDV 10 / KDV 0 / istisna / reverse charge / invalid path testleri PASS
