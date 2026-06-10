# FAZ 4B / 18.1 - Opening Stock

Amaç:
Pilot öncesi tenant-safe açılış stok altyapısını kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Stok hareketi üretmez.
- Stok bakiyesi güncellemez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `inventory`

Oluşturulacak tablolar:
1. `inventory.opening_stock_batches`
2. `inventory.opening_stock_lines`
3. `inventory.opening_stock_validation_errors`
4. `inventory.opening_stock_posting_runs`
5. `inventory.opening_stock_balance_snapshots`

Pilot açılış stok mantığı:
- Tenant bazlı açılış stok batch’i oluşturulur.
- Her batch altında ürün/lokasyon bazlı açılış stok satırları tutulur.
- Import/staging tarafı ile `import_batch_id` ve `import_row_id` üzerinden bağ kurulabilir.
- Posting/apply sonraki kontrollü adımda yapılacaktır.
- Bu adım sadece tablo ve güvenlik standardını hazırlar.

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Her unique/index tenant bazlı tasarlanmalı.
- Cross-tenant stok kaydı yasaktır.
- Stok apply controlled gate olmadan çalıştırılmaz.

Kapanış hedefi:
OPENING_STOCK=PASS
OPENING_STOCK_MIGRATION_PAIR=PASS
OPENING_STOCK_TABLE_COUNT=5
OPENING_STOCK_TENANT_ID_COLUMN_COUNT=5
OPENING_STOCK_INDEX_COUNT>=10
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
STOCK_POSTING_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_1_FINAL_STATUS=PASS
