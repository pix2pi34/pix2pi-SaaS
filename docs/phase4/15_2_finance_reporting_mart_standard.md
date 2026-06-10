# FAZ 4B / 15.2 - Finance Reporting Mart

Amaç:
Pilot öncesi finansal raporlama için tenant-safe finance mart migration pair oluşturmak.

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
1. `reporting_mart.finance_daily_summaries`
2. `reporting_mart.finance_journal_summaries`
3. `reporting_mart.finance_tax_summaries`
4. `reporting_mart.finance_tenant_kpis`

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Rapor tabloları tenant + dönem/tarih bazlı indexlenmeli.
- Finans martları canlı transactional tabloyu değiştirmez.
- Finance mart apply sonraki controlled apply gate olmadan çalıştırılmaz.

Kapanış hedefi:
FINANCE_REPORTING_MART=PASS
FINANCE_REPORTING_MIGRATION_PAIR=PASS
FINANCE_REPORTING_TABLE_COUNT=4
FINANCE_REPORTING_TENANT_ID_COLUMN_COUNT=4
FINANCE_REPORTING_INDEX_COUNT>=8
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_15_2_FINAL_STATUS=PASS

## Not: Mart kelimesi ay anlamında değildir

Buradaki `finance reporting mart`, Mart ayı raporu değildir.
`mart` kelimesi data mart / reporting mart anlamındadır.

Bu yapı tüm dönemleri destekler:
- Günlük raporlar `summary_date` ile tutulur.
- Aylık/dönemsel raporlar `period_key` ile tutulur.
- Örnek period_key değerleri: `2026-01`, `2026-02`, `2026-03`, `2026-04`, `2026-12`.

Yani sistem sadece Mart ayını değil, tüm ayları ve yılları destekleyecek şekilde tasarlanmıştır.
