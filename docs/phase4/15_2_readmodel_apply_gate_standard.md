# FAZ 4 / 15.2 - Operational Readmodel Migration Apply Gate / Dry-Run / Safety Check

Amac:
15.1 ile uretilen operational readmodel migration pair icin apply oncesi guvenlik kapisini kurmak.

Bu adim:
- Canli DB'ye migration apply etmez.
- DB mutate etmez.
- Config degistirmez.
- Container restart etmez.
- Index create/drop uygulamaz.
- Vacuum/analyze calistirmaz.
- Query kill etmez.
- Query text rapora basmaz.
- Migration dosyalarini statik olarak kontrol eder.
- DB connection / primary role / dirty state kontrolu yapar.
- Readmodel objelerinin mevcut durumunu raporlar.
- Apply icin blocked candidate execution file uretir.

Zorunlu kapilar:
1. 15.1 operational readmodel tables PASS olmali.
2. Up/down migration pair mevcut olmali.
3. Migration chain validator PASS olmali.
4. DB connection PASS olmali.
5. DB role PRIMARY_WRITE olmali.
6. schema_migrations dirty state false olmali.
7. readmodel schema/table mevcut durumu raporlanmali.
8. Apply script default olarak exit 99 ile bloklanmali.
9. Apply icin explicit APPLY_READMODEL=1 gerekir.

Kapanis hedefi:
READMODEL_APPLY_GATE=PASS
READMODEL_APPLY_DECISION=PLAN_READY_APPLY_NOT_EXECUTED
DB_APPLY_EXECUTED=NO
DB_MUTATION=NO
FAZ4_15_2_FINAL_STATUS=PASS
