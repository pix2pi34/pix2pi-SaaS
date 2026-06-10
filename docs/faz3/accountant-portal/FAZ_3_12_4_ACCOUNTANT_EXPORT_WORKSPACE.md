# 167 — FAZ 3-12.4 — Excel / PDF / TDHP Export Workspace

## Amaç

Muhasebeci portalında firma ve dönem bazlı Excel, PDF, TDHP ve muhasebe programı export paketlerini görüntülemek, önizlemek ve local artifact olarak indirme readiness yüzeyini kurmak.

## Kapsam

- Excel export görünümü
- PDF export görünümü
- TDHP export görünümü
- Logo export görünümü
- Mikro export görünümü
- Zirve export görünümü
- ETA export görünümü
- Firma / dönem filtreleri
- Yetkili firma filtresi
- Muhasebeci kimlik göstergesi
- Tenant / firma göstergesi
- Export permission görünümü
- Access decision görünümü
- Local artifact download görünümü
- External delivery görünümü
- Preview görünümü
- Audit timeline

## Canlı Politika

Bu workspace gerçek dış sistem teslimatı yapmaz.

Production approved FALSE, local artifact only TRUE, real external delivery allowed FALSE ve real accounting program write allowed FALSE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Excel / PDF / TDHP / Logo / Mikro / Zirve / ETA formatları görünür
- Tenant / accountant / firm guard görünür
- Permission / access decision / hash / evidence izleri görünür
- Real external delivery FALSE
- Local artifact only TRUE
- Audit PASS
