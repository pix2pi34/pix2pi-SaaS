# FAZ 4 / 14.3.5 - DB Observability Final Baseline / pg_stat_statements Evidence

Amac:
14.3.4 ile aktif edilen DB observability ayarlarinin kalici ve calisir oldugunu kanitlamak.

Bu adim:
- DB config degistirmez.
- Extension kurmaz.
- Container restart etmez.
- Query kill etmez.
- Vacuum/analyze calistirmaz.
- Query text rapora basmaz.
- Sadece read-only kanit toplar.

Kontroller:
1. DB primary/write dogrulanir.
2. shared_preload_libraries icinde pg_stat_statements dogrulanir.
3. pg_stat_statements extension kurulu dogrulanir.
4. pg_stat_statements view okunabilir dogrulanir.
5. track_io_timing=on dogrulanir.
6. log_min_duration_statement aktif dogrulanir.
7. pg_stat_statements aggregate metrikleri query text basmadan okunur.
8. DB perf risk LOW dogrulanir.
9. 14.3 final closure raporu uretilir.

Kapanis hedefi:
DB_OBSERVABILITY_FINAL_BASELINE=PASS
PG_STAT_STATEMENTS_EVIDENCE=PASS
DB_PERF_RISK_LEVEL=LOW
FAZ4_14_3_5_FINAL_STATUS=PASS
FAZ4_14_3_FINAL_STATUS=PASS
