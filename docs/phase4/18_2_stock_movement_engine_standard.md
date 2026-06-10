# FAZ 4B / 18.2 - Stock Movement Engine

Amaç:
Pilot öncesi stok giriş, çıkış, transfer, adjustment ve açılış stok posting hareketlerini taşıyacak tenant-safe stok hareket motoru altyapısını kurmak.

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
1. `inventory.stock_movement_batches`
2. `inventory.stock_movement_documents`
3. `inventory.stock_movements`
4. `inventory.stock_movement_lines`
5. `inventory.stock_movement_allocations`
6. `inventory.stock_movement_validation_errors`
7. `inventory.stock_movement_posting_runs`

Desteklenecek hareket tipleri:
- OPENING
- SALE
- PURCHASE
- TRANSFER
- ADJUSTMENT
- RETURN
- REVERSAL

Hareket yönleri:
- IN
- OUT
- TRANSFER
- NEUTRAL

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Hareket batch, document, movement ve line kayıtları tenant bazlı izole olmalı.
- Idempotency key olmadan posting/run çalışmamalı.
- Stok hareket apply controlled gate olmadan çalıştırılmaz.

Kapanış hedefi:
STOCK_MOVEMENT_ENGINE=PASS
STOCK_MOVEMENT_MIGRATION_PAIR=PASS
STOCK_MOVEMENT_TABLE_COUNT=7
STOCK_MOVEMENT_TENANT_ID_COLUMN_COUNT=7
STOCK_MOVEMENT_INDEX_COUNT>=14
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
STOCK_MOVEMENT_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_2_FINAL_STATUS=PASS

## 18.2R Notu - Movement reference / location / quantity güçlendirme

18.2 test gate, stok hareket motorunda şu alanların yeterli seviyede bulunmasını bekler:

- `stock_movement_id`
- `stock_movement_line_id`
- düz `location_code`
- düz `quantity`

Bu nedenle movement header, document, allocation ve validation alanları güçlendirildi.

Amaç:
- Hareket header ile line/allocation/error ilişkisinin daha net kurulması
- Transfer ve normal stok hareketlerinde ortak `location_code` izinin bulunması
- Balance delta üretiminde hem `quantity` hem `quantity_delta` bilgisinin tutulması
- Validation error kayıtlarının movement ve line seviyesine bağlanabilmesi
