# 134 — FAZ 3-10.4.4 — ETA gerçek format üretimi

## Amaç

Bu adım, TDHP posting kayıtlarını ETA muhasebe aktarımı için gerçek dosya paketi formatına dönüştürür.

## Kapsam

- ETA export request modeli
- ETA journal row modeli
- ETA export file modeli
- ETA export package modeli
- ETA validation issue modeli
- Posting entry → ETA journal rows
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

- `*_ETA_JOURNAL.txt`
- `*_ETA_LEDGER.txt`
- `*_ETA_SUMMARY.txt`

## Canlı Politika

Bu adım dış sisteme gerçek dosya göndermez. ETA format paketini üretir ve validasyonunu yapar.

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
