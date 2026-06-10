# 169 — FAZ 3-12.2 — Firma Değiştirici

## Amaç

Muhasebeci portalında yetkili firmalar arasında güvenli, tenant-safe ve audit izli firma context değişimi yüzeyini kurmak.

## Kapsam

- Firma değiştirici görünümü
- Aktif firma context görünümü
- Yetkili firma listesi
- Switch decision görünümü
- Tenant boundary görünümü
- Firm scope görünümü
- Context token görünümü
- Target route / export route / finance route görünümü
- Permission ve subscription görünümü
- Audit timeline

## Canlı Politika

Firma değiştirici cross-tenant erişim açmaz.

Production approved FALSE, cross tenant access allowed FALSE, accountant authorization required TRUE, firm scope required TRUE, context token required TRUE ve switch audit required TRUE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Switch allowed / review / blocked kararları görünür
- Context token / context hash / permission hash / audit hash izleri var
- Target/export/finance route izleri var
- Cross tenant access FALSE
- Firm scope required TRUE
- Audit PASS
