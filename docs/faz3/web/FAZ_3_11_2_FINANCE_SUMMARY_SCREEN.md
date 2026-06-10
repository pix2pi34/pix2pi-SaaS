# 164 — FAZ 3-11.2 — Finans Özet Ekranı

## Amaç

ERP Türkiye çekirdeğinden gelen TDHP, vergi, ödeme, mutabakat ve export verilerini tek finans özet ekranında toplamak.

## Kapsam

- Brüt satış görünümü
- Net satış / net gelir görünümü
- Gider görünümü
- Brüt kâr görünümü
- Net kâr görünümü
- KDV pozisyonu görünümü
- Stopaj pozisyonu görünümü
- Kasa / banka görünümü
- Borç / alacak görünümü
- Tahsilat görünümü
- Reconciliation status görünümü
- Export readiness görünümü
- Kaynak ekran bağlantıları
- Audit evidence görünümü
- Dönem filtresi
- Tenant finance scope görünümü
- Read-only karar destek yüzeyi

## Hesap Kapsamı

- 600 Gelir
- 153 Maliyet / stok
- 391 Hesaplanan KDV
- 191 İndirilecek KDV
- 360 Stopaj
- 120 Alıcılar
- 320 Satıcılar
- 102 Bankalar
- 100 Kasa
- 610 Satıştan iadeler

## Canlı Politika

Bu ekran read-only karar destek yüzeyidir.

Bu ekranda gerçek ödeme capture, gerçek export teslimi, canlı vergi rule değişimi veya ledger write yapılmaz. Production approved FALSE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Gelir / gider / kâr / vergi / ödeme / borç-alacak / kasa-banka / export özetleri var
- TDHP, tax, payment, reconciliation ve export kaynak ekran izleri var
- Audit hash / summary hash / evidence file izleri var
- Production approved FALSE
- Read-only summary TRUE
- Audit PASS
