# FAZ 4 / 15.4 - Readmodel Post-Apply Contract / Query Evidence / Final Closure

Amac:
15.1-15.3 ile kurulan operational readmodel tablolarini DB uzerinde sozlesme, index, tenant izolasyonu ve query evidence seviyesinde dogrulamak.

Bu adim:
- Yeni schema/table/index olusturmaz.
- Config degistirmez.
- Container restart etmez.
- Vacuum/analyze calistirmaz.
- Query kill etmez.
- Query text rapora basmaz.
- Kalici veri yazmaz.
- Smoke test gerekiyorsa transaction icinde insert/select yapar ve rollback eder.
- Readmodel final closure raporu uretir.

Kontroller:
1. 15.3 controlled apply PASS olmali.
2. readmodel schema mevcut olmali.
3. Hedef 6 tablo mevcut olmali.
4. Her hedef tabloda tenant_id olmali.
5. Her hedef tabloda primary key olmali.
6. Readmodel indexleri mevcut olmali.
7. projection_state kontrati dogrulanmali.
8. document_work_queue kontrati dogrulanmali.
9. inventory_status_snapshot kontrati dogrulanmali.
10. Rollback smoke test kalici veri birakmadan PASS olmali.
11. Final readmodel closure PASS olmali.

Kapanis hedefi:
READMODEL_CONTRACT_QUERY_EVIDENCE=PASS
READMODEL_ROLLBACK_SMOKE=PASS
READMODEL_FINAL_CLOSURE=PASS
DB_PERSISTENT_MUTATION=NO
FAZ4_15_4_FINAL_STATUS=PASS
