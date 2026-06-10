# FAZ 4 / 14.3.1 - DB Observability / Performance Evidence Discovery

Amac:
Primary PostgreSQL uzerinde DB gozlemlenebilirlik ve performans sinyallerini kanitlamak.

Bu adim:
- DB mutate etmez.
- Extension kurmaz.
- Config degistirmez.
- Query kill etmez.
- Vacuum/analyze calistirmaz.
- Sadece mevcut metrikleri okur ve raporlar.

Kontroller:
1. DB primary/write dogrulanir.
2. schema_migrations dirty=false dogrulanir.
3. max_connections okunur.
4. aktif connection sayilari okunur.
5. idle in transaction sayisi okunur.
6. long running query sayisi okunur.
7. waiting lock sayisi okunur.
8. deadlock sayisi okunur.
9. user table/index istatistikleri okunur.
10. dead tuple / live tuple sinyali okunur.
11. pg_stat_statements hazirligi kontrol edilir.
12. autovacuum, track_io_timing, shared_preload_libraries okunur.
13. risk seviyesi raporlanir.

Kapanis hedefi:
DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=PASS
DB_ROLE=PRIMARY_WRITE
DB_CONNECTION_CHECK=PASS
DB_PERF_RISK_LEVEL raporlanir
FAZ4_14_3_1_FINAL_STATUS=PASS
