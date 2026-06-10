# FAZ 4B / 15.3 - e-Belge / Export Reporting Mart

Amaç:
Pilot öncesi e-Fatura, e-Arşiv, e-Adisyon ve muhasebe export durumlarının tenant-safe raporlama martını oluşturmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `reporting_mart`

Oluşturulacak tablolar:
1. `reporting_mart.ebelge_daily_summaries`
2. `reporting_mart.ebelge_document_status_summaries`
3. `reporting_mart.ebelge_error_summaries`
4. `reporting_mart.accounting_export_batch_summaries`
5. `reporting_mart.accounting_export_provider_summaries`
6. `reporting_mart.accounting_export_error_summaries`
7. `reporting_mart.accounting_export_tenant_kpis`

Kapsanan e-Belge tipleri:
- EFATURA
- EARSIV
- EADISYON

Kapsanan export sağlayıcıları:
- LOGO
- MIKRO
- ZIRVE
- ETA

Tarih/dönem mantığı:
- Günlük raporlar `summary_date` ile tutulur.
- Aylık/dönemsel raporlar `period_key` ile tutulur.
- Bu yapı tüm ayları ve yılları destekler.

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Rapor tabloları tenant + dönem/tarih + tip/provider bazlı indexlenmeli.
- Mart tabloları canlı transactional tabloyu değiştirmez.
- Apply sonraki controlled apply gate olmadan çalıştırılmaz.

Kapanış hedefi:
EBELGE_EXPORT_REPORTING_MART=PASS
EBELGE_EXPORT_MIGRATION_PAIR=PASS
EBELGE_EXPORT_TABLE_COUNT=7
EBELGE_EXPORT_TENANT_ID_COLUMN_COUNT=7
EBELGE_EXPORT_INDEX_COUNT>=14
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_15_3_FINAL_STATUS=PASS

## 15.3R Notu - Status ve tutar metrikleri

15.3 test gate, export reporting mart içinde yeterli status ve tutar metriği bekler.

Bu nedenle export provider ve tenant KPI tablolarında:
- `status_code`
- export debit / credit / balance amount
- total / successful export amount

alanları tutulur.

Amaç:
- Logo / Mikro / Zirve / ETA exportlarının sadece adet bazlı değil, tutar bazlı da raporlanması
- provider + status bazlı filtreleme
- tenant + dönem + provider + status bazlı analiz
