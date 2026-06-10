# FAZ 4 / 14.4.3 - Table Bloat / Dead Tuple / Vacuum Readiness

Amac:
PostgreSQL tablolarinda dead tuple, vacuum/analyze ve autovacuum hazirligini kanitlamak.

Bu adim:
- DB mutate etmez.
- VACUUM calistirmaz.
- ANALYZE calistirmaz.
- Extension kurmaz.
- Config degistirmez.
- Container restart etmez.
- Query kill etmez.
- Sadece pg_stat_user_tables ve PostgreSQL config metriklerini okur.

Not:
Bu adim gercek fiziksel bloat olcumu degil, dead tuple proxy baseline uretir.
Gercek bloat icin pgstattuple/pgstattuple_approx ayri bir gate ile degerlendirilir.

Kontroller:
1. 14.4.2 index usage baseline PASS olmali.
2. DB primary/write dogrulanir.
3. autovacuum durumu okunur.
4. track_counts durumu okunur.
5. live/dead tuple toplam metrikleri okunur.
6. dead tuple ratio tablo bazli raporlanir.
7. son vacuum/autovacuum/analyze zamanlari okunur.
8. vacuum/analyze calistirilmadigi kanitlanir.
9. risk seviyesi raporlanir.

Kapanis hedefi:
VACUUM_BLOAT_READINESS=PASS
VACUUM_EXECUTED=NO
ANALYZE_EXECUTED=NO
DB_MUTATION=NO
FAZ4_14_4_3_FINAL_STATUS=PASS
