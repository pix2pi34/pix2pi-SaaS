# 170 — FAZ 3-12.3 — Firma Bazlı Yetki Ekranı

## Amaç

Muhasebeci portalında her firma için rol/yetki kararlarını görünür hale getirmek ve tenant-safe permission enforcement yüzeyini kurmak.

## Kapsam

- Firma bazlı yetki matrisi
- VIEW / EXPORT / MANAGE / READ_ONLY izinleri
- ACCOUNTANT_MANAGER / ACCOUNTANT_EXPORTER / ACCOUNTANT_VIEWER / ACCOUNTANT_READ_ONLY rol setleri
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY_ALLOW kararları
- Tenant boundary görünümü
- Firma scope görünümü
- Abonelik durumu görünümü
- Allowed / denied resource görünümü
- Permission hash / decision hash / audit hash izleri
- Audit timeline

## Canlı Politika

Bu ekran cross-tenant erişim açmaz ve gerçek yetki güncellemesi yapmaz.

Production approved FALSE, cross tenant access allowed FALSE, tenant boundary required TRUE, firm scope required TRUE, subscription status required TRUE, permission hash required TRUE ve audit required TRUE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- VIEW / EXPORT / MANAGE / READ_ONLY görünür
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY_ALLOW görünür
- Role set kapsamı görünür
- Tenant boundary / firm scope / subscription guard görünür
- Permission hash / decision hash / audit hash / evidence izleri var
- Cross tenant access FALSE
- Audit PASS
