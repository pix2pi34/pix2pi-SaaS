# 145 — FAZ 3-10.5.6 — Muhasebeci portalı integration testleri

## Amaç

Muhasebeci portalı alt runtime'larını tek uçtan uca entegrasyon test suite altında doğrular.

## Kapsam

- Aylık abonelik activation flow
- Firma görünürlüğü flow
- Firma bazlı yetki enforcement flow
- Excel/PDF/TDHP export bundle flow
- Subscription runtime bridge
- Company visibility runtime bridge
- Company permission enforcement bridge
- Export runtime bridge
- Integration hash üretimi
- Validation guard testleri

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Suite dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Subscription flow PASS
- Visibility flow PASS
- Permission flow PASS
- Export flow PASS
- Validation failure paths PASS
