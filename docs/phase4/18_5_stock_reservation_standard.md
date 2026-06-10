# FAZ 4B / 18.5 - Stock Reservation

Amaç:
Pilot öncesi satıştan önce stok ayırma / rezerve etme altyapısını tenant-safe şekilde kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Stok rezervasyonu oluşturmaz.
- Stok hareketi üretmez.
- Stok bakiyesi güncellemez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `inventory`

Oluşturulacak tablolar:
1. `inventory.stock_reservation_batches`
2. `inventory.stock_reservations`
3. `inventory.stock_reservation_lines`
4. `inventory.stock_reservation_allocations`
5. `inventory.stock_reservation_releases`
6. `inventory.stock_reservation_validation_errors`
7. `inventory.stock_reservation_expiry_runs`

Reservation lifecycle:
- PLANNED
- RESERVED
- PARTIAL
- RELEASED
- EXPIRED
- CONSUMED
- CANCELLED
- FAILED

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Reservation batch, reservation, line, allocation ve release kayıtları tenant bazlı izole olmalı.
- Idempotency key olmadan reservation/release/expiry run çalışmamalı.
- Cross-tenant stok rezervasyonu yasaktır.
- Gerçek reservation apply controlled gate olmadan çalıştırılmaz.

Kapanış hedefi:
STOCK_RESERVATION=PASS
STOCK_RESERVATION_MIGRATION_PAIR=PASS
STOCK_RESERVATION_TABLE_COUNT=7
STOCK_RESERVATION_TENANT_ID_COLUMN_COUNT=7
STOCK_RESERVATION_INDEX_COUNT>=14
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
STOCK_RESERVATION_EXECUTED=NO
STOCK_BALANCE_MUTATION=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_5_FINAL_STATUS=PASS

## 18.5R Notu - Reservation lifecycle status fix

18.5 test gate, reservation lifecycle izinin en az 4 yerde bulunmasını bekler.

Bu nedenle `stock_reservation_releases` tablosuna ayrıca:
- `reservation_status text not null default 'release_planned'`

alanı eklendi.

Amaç:
- Reservation header
- Reservation line
- Allocation
- Release

katmanlarında lifecycle durumunun izlenebilmesi.
