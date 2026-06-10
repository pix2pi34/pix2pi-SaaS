# FAZ 4B / 18.6 - Negative Stock Policy

Amaç:
Pilot öncesi stok eksiye düşme kararlarının tenant, ürün, lokasyon, kanal ve belge bazında güvenli şekilde yönetilmesini sağlayacak policy altyapısını kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Stok eksiye düşürmez.
- Stok hareketi üretmez.
- Stok bakiyesi güncellemez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `inventory`

Oluşturulacak tablolar:
1. `inventory.negative_stock_policy_profiles`
2. `inventory.negative_stock_policy_rules`
3. `inventory.negative_stock_policy_exceptions`
4. `inventory.negative_stock_policy_evaluations`
5. `inventory.negative_stock_policy_decisions`
6. `inventory.negative_stock_policy_validation_errors`

Policy modları:
- BLOCK
- WARN
- ALLOW
- APPROVAL_REQUIRED

Karar aksiyonları:
- BLOCK_DECREMENT
- ALLOW_DECREMENT
- WARN_AND_ALLOW
- REQUIRE_APPROVAL

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Policy profile, rule, exception, evaluation ve decision kayıtları tenant bazlı izole olmalı.
- Cross-tenant policy uygulanamaz.
- Gerçek policy evaluation runtime sonraki controlled apply/runtime gate olmadan çalıştırılmaz.

Kapanış hedefi:
NEGATIVE_STOCK_POLICY=PASS
NEGATIVE_STOCK_POLICY_MIGRATION_PAIR=PASS
NEGATIVE_STOCK_POLICY_TABLE_COUNT=6
NEGATIVE_STOCK_POLICY_TENANT_ID_COLUMN_COUNT=6
NEGATIVE_STOCK_POLICY_INDEX_COUNT>=12
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
NEGATIVE_STOCK_POLICY_EXECUTED=NO
STOCK_BALANCE_MUTATION=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_18_6_FINAL_STATUS=PASS
