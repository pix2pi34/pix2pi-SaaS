# 142 — FAZ 3-10.5.3 — Excel / PDF / TDHP export runtime

## Amaç

Muhasebeci portalı içinde firma bazlı yetki enforcement sonrası Excel, PDF ve TDHP export dosyalarının runtime seviyesinde üretilmesini sağlar.

## Kapsam

- Portal export request modeli
- Portal export file modeli
- Portal export result modeli
- Export bundle request/result modeli
- Ledger export row modeli
- Excel CSV export üretimi
- PDF simulation export üretimi
- TDHP TXT export üretimi
- Company permission enforcement bridge
- Format → permission map
- Tenant scope guard
- Company scope guard
- Ledger row validation
- Balance guard
- Export hash guard
- Bundle export support

## Canlı Politika

Bu runtime muhasebeci portalındaki export dosya üretim çekirdeğidir. Gerçek dış sisteme gönderim yapmaz; dosya içeriği üretir ve permission kararını enforce eder.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Excel export PASS
- PDF export PASS
- TDHP export PASS
- Bundle export PASS
- Permission denied path PASS
- Company mismatch path PASS
- Unbalanced ledger path PASS
- Tenant mismatch ledger path PASS
