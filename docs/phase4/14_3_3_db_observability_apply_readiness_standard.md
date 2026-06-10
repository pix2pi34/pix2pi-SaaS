# FAZ 4 / 14.3.3 - DB Observability Apply Readiness / Config Patch Plan

Amac:
pg_stat_statements, track_io_timing ve slow query log icin kontrollu apply oncesi hazirlik ve rollback planini uretmek.

Bu adim:
- DB mutate etmez.
- Extension kurmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Query kill etmez.
- Vacuum/analyze calistirmaz.
- Sadece apply readiness raporu, candidate patch plan ve rollback plan uretir.

Hedef konfigurasyon:
1. shared_preload_libraries='pg_stat_statements'
2. track_io_timing=on
3. log_min_duration_statement=1000
4. CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

Guvenlik:
- APPLY_DB_OBSERVABILITY=0 default kalir.
- Candidate plan exit 99 ile bloklu uretilir.
- Rollback plan exit 99 ile bloklu uretilir.
- Restart sadece sonraki kontrollu apply adiminda yapilir.

Kapanis hedefi:
DB_OBSERVABILITY_APPLY_READINESS=PASS
CONFIG_PATCH_PLAN_CREATED=YES
ROLLBACK_PLAN_CREATED=YES
DB_OBSERVABILITY_APPLY_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
EXTENSION_CREATED=NO
CONTAINER_RESTARTED=NO
FAZ4_14_3_3_FINAL_STATUS=PASS
