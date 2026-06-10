# 137 — FAZ 3-10.4.3 — Zirve gerçek format üretimi

## Amaç

Bu adım, TDHP posting kayıtlarını Zirve muhasebe aktarımı için gerçek TXT dosya paketi formatına dönüştürür.

## Kapsam

- Zirve export request modeli
- Zirve journal row modeli
- Zirve export file modeli
- Zirve export package modeli
- Zirve validation issue modeli
- Posting entry → Zirve journal rows
- Journal TXT üretimi
- Ledger TXT üretimi
- Summary TXT üretimi
- Package hash üretimi
- File hash üretimi
- Tenant scope guard
- Balance guard
- Posting hash guard
- Audit trace guard
- Account prefix validation
- Turkish char normalization
- TRY currency guard

## Dosya Çıktıları

- `*_ZIRVE_JOURNAL.txt`
- `*_ZIRVE_LEDGER.txt`
- `*_ZIRVE_SUMMARY.txt`

## Canlı Politika

Bu adım Zirve sistemine gerçek dosya göndermez. Zirve format paketini üretir ve validasyonunu yapar.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Journal / ledger / summary üretimi PASS
- Tenant mismatch / unbalanced / missing hash / invalid account prefix rejection PASS
