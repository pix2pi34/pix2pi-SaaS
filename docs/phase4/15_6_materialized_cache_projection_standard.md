# FAZ 4B / 15.6 - Materialized View / Cache Projection Standardı

Amaç:
Pilot öncesi reporting/readmodel tarafında materialized view, cache projection, Redis key namespace, refresh/rebuild ve invalidation standardını oluşturmak.

Bu adım:
- DB mutate etmez.
- Materialized view oluşturmaz.
- Materialized view refresh çalıştırmaz.
- Redis’e veri yazmaz.
- Cache key üretip set etmez.
- SQL apply çalıştırmaz.
- Migration oluşturmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Sadece manifest, refresh/rebuild standardı ve candidate execution plan üretir.
- Raw DSN, password, token veya query text rapora basmaz.

Kapsam:
1. Finance dashboard projection
2. Finance period KPI cache
3. e-Belge status dashboard cache
4. Payment / reconciliation dashboard cache
5. Party search cache
6. Product search cache
7. Inventory balance cache
8. Global search cache
9. Reporting home snapshot
10. Pilot ops health cache

Tenant güvenliği:
- Tüm projection/cache keyleri tenant bazlı namespace kullanmalı.
- Cache key standardı `tenant:{tenant_id}:...` formatında olmalı.
- Cross-tenant cache key yasaktır.
- Refresh/rebuild controlled apply gate olmadan çalıştırılmaz.

Kapanış hedefi:
MATERIALIZED_CACHE_PROJECTION_STANDARD=PASS
MATERIALIZED_CACHE_MANIFEST_STATUS=PASS
MATERIALIZED_CACHE_TENANT_KEY_STATUS=PASS
MATERIALIZED_CACHE_REFRESH_STATUS=PASS
MATERIALIZED_CACHE_REBUILD_STATUS=PASS
MATERIALIZED_CACHE_INVALIDATION_STATUS=PASS
MATERIALIZED_CACHE_CANDIDATE_PLAN_STATUS=PASS
DB_MUTATION=NO
REDIS_MUTATION=NO
MATERIALIZED_VIEW_REFRESH_EXECUTED=NO
CACHE_WRITE_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_15_6_FINAL_STATUS=PASS
