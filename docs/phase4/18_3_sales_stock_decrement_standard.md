# FAZ 4B / 18.3 - Sales Stock Decrement

Amaç:
Pilot öncesi satış gerçekleştiğinde stok düşme akışının tenant-safe altyapısını kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Satış stok düşme işlemi çalıştırmaz.
- Stok hareketi üretmez.
- Stok bakiyesi güncellemez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `inventory`

Oluşturulacak tablolar:
1. `inventory.sales_stock_decrement_batches`
2. `inventory.sales_stock_decrement_lines`
3. `inventory.sales_stock_decrement_allocations`
4. `inventory.sales_stock_decrement_movement_links`
5. `inventory.sales_stock_decrement_validation_errors`
6. `inventory.sales_stock_decrement_posting_runs`

Satış stok düşme mantığı:
- Satış belgesi / POS satışı geldiğinde decrement batch oluşturulur.
- Her satış satırı product + location + quantity bazında izlenir.
- Stok hareket motoruna SALE / OUT olarak bağlanır.
- Negative stock policy bu aşamada sadece alan olarak hazırlanır; karar 18.6’da kapatılır.
- Gerçek posting controlled apply gate olmadan çalıştırılmaz.

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Sales decrement batch, line, allocation ve movement link kayıtları tenant bazlı izole olmalı.
- Idempotency key olmadan posting/run çalışmamalı.
- Cross-tenant stok düşme yasaktır.

Kapanış hedefi:
SALES_STOCK_DECREMENT=PASS
SALES_STOCK_DECREMENT_MIGRATION_PAIR=PASS
SALES_STOCK_DECREMENT_TABLE_COUNT=6
SALES_STOCK_DECREMENT_TENANT_ID_COLUMN_COUNT=6
SALES_STOCK_DECREMENT_INDEX_COUNT>=12
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
SALES_STOCK_DECREMENT_EXECUTED=NO
STOCK_BALANCE_MUTATION=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_3_FINAL_STATUS=PASS

## 18.3R Notu - Sales document line trace fix

18.3 test gate, satış stok düşme akışında `sales_document_line_id` izinin en az 4 yerde bulunmasını bekler.

Bu nedenle allocation tablosuna da:
- `sales_document_id`
- `sales_document_line_id`

alanları eklendi.

Amaç:
- Satış satırı → decrement line → allocation → stock movement link zincirini uçtan uca izlemek
- Hangi satış satırının hangi stok düşme adayını ürettiğini netleştirmek
- Audit ve hata çözümleme tarafında satış satırı seviyesinde takip sağlamak
