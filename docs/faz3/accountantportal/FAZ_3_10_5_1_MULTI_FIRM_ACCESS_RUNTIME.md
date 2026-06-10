# 140 — FAZ 3-10.5.1 — Çok firmalı erişim runtime

## Amaç

Muhasebeci portalında bir muhasebeci kullanıcısının birden fazla firmaya tenant-safe, abonelik kontrollü ve yetki kontrollü erişmesini sağlar.

## Kapsam

- Accountant subscription modeli
- Firm assignment modeli
- Access request modeli
- Access decision modeli
- Visible firms request/result modeli
- Çok firmalı erişim kararı
- Firma görünürlük listesi
- Active subscription guard
- Active assignment guard
- Tenant scope guard
- Company scope guard
- Permission match guard
- Assignment validity date guard
- Subscription firm limit guard
- Audit hash üretimi

## Canlı Politika

Bu runtime gerçek muhasebeci portalı erişim kararının çekirdeğidir. UI veya API endpoint değildir; access decision runtime seviyesidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Allowed access path PASS
- Subscription deny path PASS
- Assignment deny path PASS
- Tenant/company mismatch deny path PASS
- Permission deny path PASS
- Visible firms filtering PASS
