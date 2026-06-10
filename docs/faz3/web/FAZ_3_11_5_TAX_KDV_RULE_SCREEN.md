# 159 — FAZ 3-11.5 — Vergi / KDV Rule Ekranı

## Amaç

KDV, stopaj, istisna/muafiyet ve rule version rollout süreçlerini ERP web yüzeyinde yönetmek.

## Kapsam

- KDV 20 rule görünümü
- KDV 10 rule görünümü
- KDV 0 / istisna rule görünümü
- Stopaj rule görünümü
- Vergi istisna / muafiyet rule görünümü
- Rule version rollout görünümü
- Canary rollout görünümü
- Rollback görünümü
- Audit persistence görünümü
- TDHP hesap izleri: 391, 191, 360
- Legal reference görünümü
- Effective date görünümü
- Approval status görünümü
- Rule artifact hash / config artifact hash / audit hash görünümü

## Canlı Politika

Bu ekran production vergi rule aktivasyonu yapmaz.

Hukuk ve mali müşavir onayı olmadan canlı rule değişimi açılmaz. Production approved FALSE, real external provider calls CLOSED ve legal review REQUIRED kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- KDV / stopaj / exemption / rollout / audit persistence yüzeyleri var
- TDHP 391 / 191 / 360 hesap izleri var
- Legal reference / effective date / approval status görünür
- Production approved FALSE
- Legal review REQUIRED
- Real external calls CLOSED
- Audit PASS
