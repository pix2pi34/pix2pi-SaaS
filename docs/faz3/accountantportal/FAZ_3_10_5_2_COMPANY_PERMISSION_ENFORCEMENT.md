# 141 — FAZ 3-10.5.2 — Firma bazlı yetki enforcement

## Amaç

Muhasebeci portalında kullanıcıların firma bazlı hangi kaynağa ve hangi işlem yetkisine erişebileceğini runtime seviyesinde enforce eder.

## Kapsam

- Company permission grant modeli
- Enforcement request modeli
- Enforcement decision modeli
- Bulk enforcement request/result modeli
- Role → permission map
- Resource type → permission map
- Tenant scope guard
- Company scope guard
- Assignment scope guard
- Explicit grant guard
- Resource permission guard
- Role permission guard
- Audit subject guard
- Bulk permission enforcement

## Canlı Politika

Bu adım UI/API endpoint değildir. Muhasebeci portalı API ve export runtime çağrılarının arkasındaki izin karar çekirdeğidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Allowed path PASS
- Tenant/company/assignment mismatch deny path PASS
- Role permission deny path PASS
- Resource permission deny path PASS
- Explicit grant deny path PASS
- Bulk enforcement PASS
