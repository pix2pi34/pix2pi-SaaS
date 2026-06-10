# 163 — FAZ 3-11.7 — Export Center Ekranı

## Amaç

Logo, Mikro, Zirve ve ETA için gerçek format export paketlerini ERP web yüzeyinde görüntülemek, validasyon durumunu izlemek ve evidence paketlerini kontrol etmek.

## Kapsam

- Logo export görünümü
- Mikro export görünümü
- Zirve export görünümü
- ETA export görünümü
- Journal file görünümü
- Ledger file görünümü
- Summary file görünümü
- Format version görünümü
- Format validation matrix görünümü
- Adapter test görünümü
- Negative test görünümü
- Tenant scope validation görünümü
- Posting hash validation görünümü
- Package hash görünümü
- File hash görünümü
- Evidence export görünümü
- Download görünümü
- External delivery görünümü
- Audit timeline

## Canlı Politika

Bu ekran gerçek muhasebe programına dosya teslimi yapmaz.

Production approved FALSE, real external delivery allowed FALSE ve real accounting program write allowed FALSE kalır. Download sadece local artifact/readiness yüzeyidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Logo / Mikro / Zirve / ETA hedefleri görünür
- Journal / ledger / summary dosyaları görünür
- Format validation matrix ve adapter tests görünür
- Package hash / file hash / evidence hash izleri var
- Real external delivery CLOSED
- Production approved FALSE
- Audit PASS
