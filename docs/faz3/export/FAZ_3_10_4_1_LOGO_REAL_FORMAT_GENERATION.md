# 135 — FAZ 3-10.4.1 — Logo gerçek format üretimi

## Amaç

Bu adım, TDHP posting kayıtlarını Logo muhasebe aktarımı için gerçek CSV/TXT dosya paketi formatına dönüştürür.

## Kapsam

- Logo export request modeli
- Logo journal row modeli
- Logo export file modeli
- Logo export package modeli
- Logo validation issue modeli
- Posting entry → Logo journal rows
- Journal CSV üretimi
- Ledger CSV üretimi
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

- `*_LOGO_JOURNAL.csv`
- `*_LOGO_LEDGER.csv`
- `*_LOGO_SUMMARY.txt`

## Canlı Politika

Bu adım Logo sistemine gerçek dosya göndermez. Logo format paketini üretir ve validasyonunu yapar.

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
