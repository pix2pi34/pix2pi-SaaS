# FAZ 4 / 14.1.5B - Migration Timestamp Anomaly / Latest Order Guard

Amac:
Migration dosya adlarindaki timestamp anomalilerini yakalamak ve latest migration hesabinin yanlis dosyayi secmesini engellemek.

Bu adim:
- DB mutate etmez.
- Migration apply yapmaz.
- Migration dosyalarini rename etmez.
- Sadece analiz ve rapor uretir.

Gecerli yeni timestamp standardi:
YYYYMMDDHHMMSS_slug.up.sql

Gecerli legacy split timestamp standardi:
YYYYMMDD_HHMMSS_slug.up.sql

Anomaly kabul edilen format:
YYYYMMDD_HHMMSSX_slug.up.sql
Ornek:
20260426_0911001_erp_fiscal_sequence.up.sql

Kural:
7 haneli saat bolumu latest hesabina dahil edilmez.
Guvenli latest hesabi sadece valid sequence, valid split timestamp ve yeni 14 haneli timestamp uzerinden yapilir.

Kapanis hedefi:
MIGRATION_TIMESTAMP_ORDER_GUARD=PASS
SAFE_LATEST_FILE dogru hesaplanir
TIMESTAMP_ANOMALY_COUNT raporlanir
FAZ4_14_1_5B_FINAL_STATUS=PASS
