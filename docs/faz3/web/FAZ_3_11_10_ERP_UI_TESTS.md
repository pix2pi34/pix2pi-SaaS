# 166 — FAZ 3-11.10 — ERP UI Testleri

## Amaç

FAZ 3 ERP web yüzeylerinin tamamını tek test suite altında doğrulamak.

## Test Kapsamı

- 157 e-Belge operasyon ekranı
- 158 Reconciliation ekranı
- 159 Vergi / KDV rule ekranı
- 160 Journal / ledger ekranı
- 161 TDHP mapping ekranı
- 162 Ödeme / mutabakat ekranı
- 163 Export center ekranı
- 164 Finans özet ekranı
- 165 Ana yönetim dashboard’u

## Zorunlu Kontroller

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Evidence artifact var
- Phase marker var
- Screen marker var
- Tenant guard görünür
- Correlation guard görünür
- Production approved FALSE görünür
- Read-only veya gate closed politikası görünür
- Route izi var
- Main dashboard tüm ekranlara bağlanıyor
- Gerçek dış sistem aksiyonu kapalı

## Canlı Politika

Bu test suite production aktivasyonu yapmaz.

Ledger write, tax rule activation, payment capture, export delivery ve e-Belge/GİB/provider çağrıları kapalı kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- 157–165 arası tüm ekran dosyaları, configleri ve evidence dosyaları var
- Ana dashboard tüm route/link izlerini içeriyor
- Tüm ekranlarda tenant/correlation/production false veya gate closed izleri var
- Config canlı politika kapalı
- Test suite PASS
- Audit PASS
