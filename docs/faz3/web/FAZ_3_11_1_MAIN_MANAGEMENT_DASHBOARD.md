# 165 — FAZ 3-11.1 — Ana Yönetim Dashboard’u

## Amaç

FAZ 3 ERP web yüzeylerini tek merkezi yönetim ekranında toplamak.

## Kapsam

- Merkezi navigasyon
- 157 e-Belge operasyon ekranı bağlantısı
- 158 Reconciliation ekranı bağlantısı
- 159 Vergi / KDV rule ekranı bağlantısı
- 160 Journal / ledger ekranı bağlantısı
- 161 TDHP mapping ekranı bağlantısı
- 162 Ödeme / mutabakat ekranı bağlantısı
- 163 Export center ekranı bağlantısı
- 164 Finans özet ekranı bağlantısı
- Screen readiness KPI
- Finance health KPI
- Open review KPI
- Production gate KPI
- Modül detay drawer
- Gate health panel
- Audit timeline
- Read-only dashboard politikası

## Canlı Politika

Bu ekran read-only yönetim yüzeyidir.

Bu ekranda ledger write, tax rule activation, payment capture, export delivery veya e-Belge/GİB/provider canlı çağrısı yapılmaz. Production approved FALSE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- 157–164 tüm ekran bağlantıları görünür
- Tüm backend/UI gate isimleri config içinde izlenir
- Gate health panel görünür
- Evidence file izleri görünür
- Production approved FALSE
- Read-only dashboard TRUE
- Audit PASS
