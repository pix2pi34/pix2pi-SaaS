# 161 — FAZ 3-11.4 — TDHP Mapping Görüntüleme ve Kontrol Ekranı

## Amaç

TDHP mapping kurallarını ERP web yüzeyinde görüntülemek, kontrol etmek ve versiyon geçişlerini readiness seviyesinde izlemek.

## Kapsam

- TDHP mapping kataloğu
- Belge tipi mapping görünümü
- İşlem tipi mapping görünümü
- TDHP hesap kodu ve hesap adı görünümü
- Debit / credit direction görünümü
- Active mapping version görünümü
- Account prefix guard görünümü
- Unmapped guard görünümü
- Debit / credit exclusive kontrolü
- Vergi ilişkili mapping görünümü
- Posting ready görünümü
- Voucher pipeline mapping görünümü
- Mapping validation yüzeyi
- Version compare yüzeyi
- Version switch yüzeyi
- Rollback yüzeyi
- Audit timeline

## TDHP Hesap Kapsamı

- 120 Alıcılar
- 600 Yurtiçi Satışlar
- 391 Hesaplanan KDV
- 191 İndirilecek KDV
- 320 Satıcılar
- 102 Bankalar
- 153 Ticari Mallar
- 610 Satıştan İadeler

## Canlı Politika

Bu ekran production mapping switch yapmaz.

Production approved FALSE kalır. Mapping switch dry-run seviyesindedir. Unmapped kayıtlar posting öncesi bloklanır. Active version switch için onay/evidence gereklidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Mapping catalog / document type / transaction type / account code yüzeyleri var
- TDHP 120 / 600 / 391 / 191 / 320 / 102 / 153 / 610 hesap izleri var
- Debit / credit direction ve exclusive kontrolü var
- Active version / compare / switch / rollback yüzeyleri var
- Mapping hash / config hash / audit hash izleri var
- Production approved FALSE
- Mapping switch dry-run TRUE
- Audit PASS
