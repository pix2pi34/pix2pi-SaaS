# FAZ 4 / 14.4.1 - pg_stat_statements Query Performance Baseline

Amac:
pg_stat_statements uzerinden query performans baseline kaniti uretmek.

Bu adim:
- DB mutate etmez.
- Config degistirmez.
- Extension kurmaz.
- Container restart etmez.
- Query kill etmez.
- Vacuum/analyze calistirmaz.
- Query text rapora basmaz.
- Sadece aggregate metrik ve queryid bazli performans kaniti toplar.

Kontroller:
1. DB primary/write dogrulanir.
2. pg_stat_statements preload aktif dogrulanir.
3. pg_stat_statements extension kurulu dogrulanir.
4. track_io_timing=on dogrulanir.
5. log_min_duration_statement aktif dogrulanir.
6. pg_stat_statements toplam satir/call/exec time okunur.
7. En yuksek total_exec_time queryid listesi uretilir.
8. En yuksek mean_exec_time queryid listesi uretilir.
9. temp block / shared read sinyalleri okunur.
10. Query text basilmadigi kanitlanir.
11. Query performance risk seviyesi raporlanir.

Default esikler:
- mean exec warning: 100ms
- total exec warning: 1000ms
- temp blocks warning: > 0

Kapanis hedefi:
QUERY_PERFORMANCE_BASELINE=PASS
PG_STAT_STATEMENTS_QUERY_BASELINE=PASS
QUERY_TEXT_PRINTED=NO
FAZ4_14_4_1_FINAL_STATUS=PASS
