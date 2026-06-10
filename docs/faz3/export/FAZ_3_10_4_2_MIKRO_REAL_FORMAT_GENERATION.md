# 136 — FAZ 3-10.4.2 — Mikro gerçek format üretimi

## Amaç

Bu adım, TDHP posting kayıtlarını Mikro muhasebe aktarımı için gerçek CSV/TXT dosya paketi formatına dönüştürür.

## Kapsam

- Mikro export request modeli
- Mikro journal row modeli
- Mikro export file modeli
- Mikro export package modeli
- Mikro validation issue modeli
- Posting entry → Mikro journal rows
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

- `*_MIKRO_JOURNAL.csv`
- `*_MIKRO_LEDGER.csv`
- `*_MIKRO_SUMMARY.txt`

## Canlı Politika

Bu adım Mikro sistemine gerçek dosya göndermez. Mikro format paketini üretir ve validasyonunu yapar.

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
