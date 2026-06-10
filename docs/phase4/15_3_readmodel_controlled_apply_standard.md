# FAZ 4 / 15.3 - Operational Readmodel Controlled Apply / Post-Apply Verification

Amac:
15.1 ile uretilen ve 15.2 apply gate'ten gecen operational readmodel migration dosyasini kontrollu sekilde DB'ye uygulamak.

Bu adim:
- Explicit APPLY_READMODEL=1 olmadan apply yapmaz.
- Fresh logical backup smoke PASS ister.
- 15.2 readmodel apply gate PASS ister.
- Sadece readmodel schema/table/index olusturur.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Vacuum/analyze calistirmaz.
- Query kill etmez.
- Query text rapora basmaz.
- Apply sonrasi readmodel schema/table/index dogrular.
- Apply sonrasi DB health sinyallerini okur.

Zorunlu kapilar:
1. 15.2 readmodel apply gate PASS olmali.
2. Fresh logical backup smoke PASS olmali.
3. DB connection PASS olmali.
4. DB role PRIMARY_WRITE olmali.
5. schema_migrations dirty state false olmali.
6. APPLY_READMODEL=1 explicit olmali.
7. readmodel target table count apply sonrasi 6 olmali.
8. tenant_id column count en az 6 olmali.
9. index count en az 7 olmali.

Kapanis hedefi:
READMODEL_CONTROLLED_APPLY=PASS
DB_APPLY_EXECUTED=YES
DB_MUTATION=YES
DB_MUTATION_SCOPE=READMODEL_SCHEMA_ONLY
READMODEL_TARGET_TABLE_COUNT=6
FAZ4_15_3_FINAL_STATUS=PASS
