# FAZ 4 / 14.3.4 - Controlled DB Observability Apply / Restart / Verification

Amac:
pg_stat_statements, track_io_timing ve slow query log ayarlarini kontrollu sekilde aktif etmek.

Bu adim:
- Canli PostgreSQL config degistirir.
- Canli PostgreSQL container restart eder.
- pg_stat_statements extension kurar.
- Islem oncesi fresh logical backup alir.
- Islem oncesi config evidence alir.
- Islem sonrasi DB health ve observability verification yapar.

Guvenlik:
- APPLY_DB_OBSERVABILITY=1 olmadan apply yapmaz.
- Fresh logical backup basarisizsa apply yapmaz.
- DB primary/write degilse apply yapmaz.
- Config patch ALTER SYSTEM ile yapilir.
- Rollback plani 14.3.3 tarafinda uretilmistir.
- Raw DSN / password rapora basilmaz.

Hedef ayarlar:
1. shared_preload_libraries contains pg_stat_statements
2. track_io_timing=on
3. log_min_duration_statement=1000ms veya 1s
4. CREATE EXTENSION IF NOT EXISTS pg_stat_statements

Kapanis hedefi:
DB_OBSERVABILITY_CONTROLLED_APPLY=PASS
POSTGRES_CONFIG_CHANGED=YES
CONTAINER_RESTARTED=YES
EXTENSION_CREATED_OR_EXISTS=YES
DB_OBSERVABILITY_VERIFICATION=PASS
FAZ4_14_3_4_FINAL_STATUS=PASS
