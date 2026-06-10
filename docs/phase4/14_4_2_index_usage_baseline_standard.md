# FAZ 4 / 14.4.2 - Index Usage / Unused Index / Scan Ratio Evidence

Amac:
PostgreSQL uzerinde table scan, index scan ve unused index sinyallerini kanitlamak.

Bu adim:
- DB mutate etmez.
- Index create etmez.
- Index drop etmez.
- Vacuum/analyze calistirmaz.
- Query kill etmez.
- Config degistirmez.
- Container restart etmez.
- Sadece pg_stat_user_tables, pg_stat_user_indexes ve pg_index uzerinden read-only kanit toplar.

Kontroller:
1. 14.4.1 query performance baseline PASS olmali.
2. DB primary/write dogrulanir.
3. pg_stat_statements aktifligi dogrulanir.
4. Kullanici table/index sayilari okunur.
5. Seq scan / index scan toplam metriği okunur.
6. Tablo bazli scan ratio listesi uretilir.
7. Index bazli usage listesi uretilir.
8. Unused indexler sadece raporlanir.
9. Primary/unique indexler drop adayi olarak isaretlenmez.
10. Low-data / low-traffic durumu dikkate alinir.
11. Index drop uygulanmadigi kanitlanir.

Kapanis hedefi:
INDEX_USAGE_BASELINE=PASS
INDEX_DROP_EXECUTED=NO
INDEX_CREATE_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4_14_4_2_FINAL_STATUS=PASS
