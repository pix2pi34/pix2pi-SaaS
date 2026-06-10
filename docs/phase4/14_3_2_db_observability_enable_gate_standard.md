# FAZ 4 / 14.3.2 - pg_stat_statements / track_io_timing Enable Gate

Amac:
DB performans gozlemlenebilirligi icin pg_stat_statements ve track_io_timing enable kapisini kurmak.

Bu adim:
- DB mutate etmez.
- Extension kurmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Query kill etmez.
- Vacuum/analyze calistirmaz.
- Sadece mevcut durumu okur, riskleri raporlar ve aday uygulama plani uretir.

Gerekli hedefler:
1. pg_stat_statements shared_preload_libraries icinde olmali.
2. pg_stat_statements extension DB icinde kurulu olmali.
3. track_io_timing on olmali.
4. log_min_duration_statement icin plan uretilmeli.
5. Restart gerekip gerekmedigi raporlanmali.
6. Candidate execution dosyasi exit 99 ile bloklu olmali.

Default guvenlik:
APPLY_DB_OBSERVABILITY=0

Kapanis hedefi:
DB_OBSERVABILITY_ENABLE_GATE=PASS
DB_OBSERVABILITY_ENABLE_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
EXTENSION_CREATED=NO
CONTAINER_RESTARTED=NO
FAZ4_14_3_2_FINAL_STATUS=PASS
