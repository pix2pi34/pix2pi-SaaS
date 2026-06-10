# 160 — FAZ 3-11.3 — Journal / Ledger Ekranı

## Amaç

TDHP journal, voucher, posting ve ledger kayıtlarını ERP web yüzeyinde görüntülemek ve kontrol etmek.

## Kapsam

- Journal listesi
- Ledger entry görünümü
- Voucher detay görünümü
- Posting detay görünümü
- Journal line görünümü
- TDHP hesap satırları
- Debit / credit toplamları
- Balance difference kontrolü
- Append-only ledger görünümü
- Reversal görünümü
- Reversal reason görünümü
- Audit trace görünümü
- Reconciliation link görünümü
- Posting ready görünümü
- Blocked balance görünümü

## Canlı Politika

Bu ekran production ledger activation yapmaz.

Ledger append-only politikası açık görünür. Hard delete kapalıdır. Reversal için neden zorunludur. UI aksiyonları final web runtime’a kadar dry-run/readiness yüzeyidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Journal / ledger / voucher / posting / line yüzeyleri var
- TDHP 120 / 600 / 391 / 191 / 320 / 102 hesap izleri var
- Debit / credit / balance kontrolü var
- Append-only / reversal / audit trace / reconciliation link yüzeyi var
- Production approved FALSE
- Hard delete FALSE
- Audit PASS
