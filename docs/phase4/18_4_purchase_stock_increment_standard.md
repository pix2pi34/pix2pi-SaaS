# FAZ 4B / 18.4 - Purchase Stock Increment

Amaç:
Pilot öncesi alış / tedarik / mal kabul gerçekleştiğinde stok artırma akışının tenant-safe altyapısını kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Alış stok artırma işlemi çalıştırmaz.
- Stok hareketi üretmez.
- Stok bakiyesi güncellemez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `inventory`

Oluşturulacak tablolar:
1. `inventory.purchase_stock_increment_batches`
2. `inventory.purchase_stock_increment_lines`
3. `inventory.purchase_stock_increment_allocations`
4. `inventory.purchase_stock_increment_movement_links`
5. `inventory.purchase_stock_increment_validation_errors`
6. `inventory.purchase_stock_increment_posting_runs`

Alış stok artırma mantığı:
- Alış faturası / irsaliye / mal kabul geldiğinde increment batch oluşturulur.
- Her alış satırı product + location + quantity bazında izlenir.
- Stok hareket motoruna PURCHASE / IN olarak bağlanır.
- Maliyet / valuation için unit_cost ve total_cost_amount taşınır.
- Gerçek posting controlled apply gate olmadan çalıştırılmaz.

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Purchase increment batch, line, allocation ve movement link kayıtları tenant bazlı izole olmalı.
- Idempotency key olmadan posting/run çalışmamalı.
- Cross-tenant stok artırma yasaktır.

Kapanış hedefi:
PURCHASE_STOCK_INCREMENT=PASS
PURCHASE_STOCK_INCREMENT_MIGRATION_PAIR=PASS
PURCHASE_STOCK_INCREMENT_TABLE_COUNT=6
PURCHASE_STOCK_INCREMENT_TENANT_ID_COLUMN_COUNT=6
PURCHASE_STOCK_INCREMENT_INDEX_COUNT>=12
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
PURCHASE_STOCK_INCREMENT_EXECUTED=NO
STOCK_BALANCE_MUTATION=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_4_FINAL_STATUS=PASS
