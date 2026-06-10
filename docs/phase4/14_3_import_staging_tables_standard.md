# FAZ 4B / 14.3 - Import / Staging Tabloları

Amaç:
Pilot öncesi dışarıdan gelecek cari, ürün, açılış stok ve fiyat listesi verilerini güvenli şekilde karşılayacak import/staging migration standardını oluşturmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak import schema:
- `import_pipeline`

Oluşturulacak tablolar:
1. `import_pipeline.import_batches`
2. `import_pipeline.import_files`
3. `import_pipeline.import_customers_staging`
4. `import_pipeline.import_vendors_staging`
5. `import_pipeline.import_products_staging`
6. `import_pipeline.import_opening_stocks_staging`
7. `import_pipeline.import_price_lists_staging`
8. `import_pipeline.import_validation_errors`
9. `import_pipeline.import_row_status_events`

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Tüm staging tablolarında `import_batch_id` bulunmalı.
- Tenant + batch index bulunmalı.
- Tenant-specific import apply, tenant_id olmadan yapılamamalı.

Kapanış hedefi:
IMPORT_STAGING_TABLES=PASS
IMPORT_STAGING_MIGRATION_PAIR=PASS
IMPORT_STAGING_TABLE_COUNT=9
IMPORT_STAGING_TENANT_ID_COLUMN_COUNT=9
IMPORT_STAGING_INDEX_COUNT>=10
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
QUERY_TEXT_PRINTED=NO
FAZ4B_14_3_FINAL_STATUS=PASS
