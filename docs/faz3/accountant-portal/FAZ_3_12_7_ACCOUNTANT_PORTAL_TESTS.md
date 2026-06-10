# 173 — FAZ 3-12.7 — Muhasebeci Portal Testleri

## Amaç

Muhasebeci portalı web yüzeylerinin tamamını tek test suite altında doğrulamak.

## Test Kapsamı

- 167 Excel / PDF / TDHP export workspace
- 168 Çok firmalı workspace
- 169 Firma değiştirici
- 170 Firma bazlı yetki ekranı
- 171 Abonelik / durum görünümü
- 172 Portal audit / işlem geçmişi

## Zorunlu Kontroller

- HTML ekran dosyası var
- Config artifact var
- Evidence artifact var
- Phase marker var
- Screen marker var
- Tenant guard görünür
- Accountant guard görünür
- Firm scope / firm indicator görünür
- Cross tenant closed policy görünür
- Production false veya read-only policy görünür
- Audit hash ve evidence trace görünür
- Route trace var
- Real billing kapalı
- External delivery kapalı
- Append-only audit policy açık

## Canlı Politika

Bu test suite production aktivasyonu yapmaz.

Gerçek billing, ödeme alma, fatura kesme, dış sisteme teslimat, audit silme/değiştirme ve cross-tenant erişim kapalı kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- 167–172 arası tüm muhasebeci portal ekranları, configleri ve evidence dosyaları var
- Her ekranda tenant/accountant/firm-scope/audit izleri var
- Canlı risk kapıları kapalı
- Test suite PASS
- Audit PASS
