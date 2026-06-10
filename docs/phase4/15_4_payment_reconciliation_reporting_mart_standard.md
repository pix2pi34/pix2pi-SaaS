# FAZ 4B / 15.4 - Payment / Reconciliation Reporting Mart

Amaç:
Pilot öncesi ödeme denemeleri, settlement, reconciliation farkları, komisyon ve merchant payout durumlarının tenant-safe raporlama martını oluşturmak.

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
1. `reporting_mart.payment_attempt_summaries`
2. `reporting_mart.payment_provider_summaries`
3. `reporting_mart.settlement_summaries`
4. `reporting_mart.reconciliation_difference_summaries`
5. `reporting_mart.commission_summaries`
6. `reporting_mart.merchant_payout_summaries`
7. `reporting_mart.payment_reconciliation_tenant_kpis`

Tarih/dönem mantığı:
- Günlük raporlar `summary_date` ile tutulur.
- Settlement/payout raporları kendi operasyon tarihleriyle takip edilir.
- Aylık/dönemsel raporlar `period_key` ile tutulur.
- Bu yapı tüm ayları, yılları ve özel tarih aralıklarını destekler.

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Rapor tabloları tenant + dönem/tarih + provider/status bazlı indexlenmeli.
- Payment/reconciliation mart canlı transactional tabloyu değiştirmez.
- Apply sonraki controlled apply gate olmadan çalıştırılmaz.

Kapanış hedefi:
PAYMENT_RECONCILIATION_REPORTING_MART=PASS
PAYMENT_RECONCILIATION_MIGRATION_PAIR=PASS
PAYMENT_RECONCILIATION_TABLE_COUNT=7
PAYMENT_RECONCILIATION_TENANT_ID_COLUMN_COUNT=7
PAYMENT_RECONCILIATION_INDEX_COUNT>=14
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_15_4_FINAL_STATUS=PASS
