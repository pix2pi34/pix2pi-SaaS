# FAZ 4B / 18.7 - Stock Valuation

Amaç:
Pilot öncesi stok maliyetleme / değerleme standardını tenant-safe şekilde kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Stok maliyetleme çalıştırmaz.
- Stok bakiyesi güncellemez.
- Stok hareketi üretmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `inventory`

Oluşturulacak tablolar:
1. `inventory.stock_valuation_profiles`
2. `inventory.stock_valuation_layers`
3. `inventory.stock_valuation_entries`
4. `inventory.stock_valuation_adjustments`
5. `inventory.stock_revaluation_runs`
6. `inventory.stock_valuation_validation_errors`

Desteklenecek değerleme yöntemleri:
- WEIGHTED_AVERAGE
- FIFO_READY
- LIFO_READY
- MANUAL_COST
- STANDARD_COST_READY

Pilot için varsayılan:
- WEIGHTED_AVERAGE

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Değerleme profile, layer, entry, adjustment ve revaluation kayıtları tenant bazlı izole olmalı.
- Cross-tenant valuation uygulanamaz.
- Gerçek valuation runtime sonraki controlled apply/runtime gate olmadan çalıştırılmaz.

Kapanış hedefi:
STOCK_VALUATION=PASS
STOCK_VALUATION_MIGRATION_PAIR=PASS
STOCK_VALUATION_TABLE_COUNT=6
STOCK_VALUATION_TENANT_ID_COLUMN_COUNT=6
STOCK_VALUATION_INDEX_COUNT>=12
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
STOCK_VALUATION_EXECUTED=NO
STOCK_BALANCE_MUTATION=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_7_FINAL_STATUS=PASS

## 18.7R Notu - Cost / scope evidence fix

18.7 test gate, stock valuation tarafında şu sayaçları en az 4 bekler:

- `period_key`
- `quantity`
- `total_cost_amount`

Bu nedenle `stock_valuation_validation_errors` tablosuna ayrıca:
- `period_key text`
- `quantity numeric(18,4) not null default 0`
- `total_cost_amount numeric(18,4) not null default 0`

alanları eklendi.

Amaç:
- Valuation hatalarının dönem bazında izlenebilmesi
- Hata kaydında ürün/lokasyon dışında miktar ve maliyet bağlamının da tutulması
- Valuation audit/debug sürecinde eksik maliyet kaynağının daha hızlı bulunması
