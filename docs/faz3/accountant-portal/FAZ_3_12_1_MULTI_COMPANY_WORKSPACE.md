# 168 — FAZ 3-12.1 — Çok Firmalı Workspace

## Amaç

Muhasebeci portalında muhasebecinin yetkili olduğu firmaları tek workspace içinde göstermek; firma context, tenant boundary, yetki, abonelik, export ve audit readiness yüzeyini kurmak.

## Kapsam

- Muhasebeci portföy görünümü
- Yetkili firma listesi
- Seçili firma context görünümü
- Tenant boundary görünümü
- Firma scope görünümü
- Vergi no / vergi dairesi görünümü
- Sektör görünümü
- Abonelik durumu görünümü
- Yetki / rol set görünümü
- Access decision görünümü
- Dönem filtresi
- Firma durum filtresi
- Export workspace route görünümü
- Finance summary route görünümü
- Açık görev görünümü
- Audit timeline

## Canlı Politika

Bu workspace cross-tenant erişim yapmaz.

Production approved FALSE, cross tenant access allowed FALSE, accountant authorization required TRUE, firm scope required TRUE ve subscription status required TRUE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Authorized firm list görünür
- Tenant / accountant / firm guard görünür
- View / Export / Manage / Read Only yetki kapsamı görünür
- Active / Trial / Review / Blocked firma durumları görünür
- Tenant boundary hash / firm scope hash / permission hash / audit hash izleri var
- Cross tenant access FALSE
- Firm scope required TRUE
- Audit PASS
