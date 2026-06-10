# FAZ 4B / 14.5 - Archive / Partition / Retention Modeli

Amac:
Pilot oncesi buyuyen veri aileleri icin archive, partition ve retention modelini standartlastirmak.

Bu adim:
- DB mutate etmez.
- Partition olusturmaz.
- Archive calistirmaz.
- Purge/delete calistirmaz.
- SQL apply calistirmaz.
- Migration olusturmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Sadece retention manifest, partition aday modeli, archive/purge gate standardi ve candidate execution plan uretir.
- Raw DSN, password, token veya query text rapora basmaz.

Kapsam:
1. Event store / event log retention
2. Audit log retention
3. Application/runtime log retention
4. Import batch/file/staging retention
5. Notification/webhook/job history retention
6. Reporting mart / readmodel snapshot retention
7. Tenant bazli retention standardi
8. KVKK/data retention uyum notu
9. Legal hold / delete request davranisi
10. Apply gate olmadan gercek purge/archive calistirmama kuralı

Kapanis hedefi:
ARCHIVE_PARTITION_RETENTION_MODEL=PASS
RETENTION_MANIFEST_STATUS=PASS
RETENTION_PARTITION_CANDIDATE_STATUS=PASS
RETENTION_TENANT_SAFETY_STATUS=PASS
RETENTION_KVKK_STATUS=PASS
RETENTION_LEGAL_HOLD_STATUS=PASS
RETENTION_CANDIDATE_PLAN_STATUS=PASS
DB_MUTATION=NO
ARCHIVE_APPLY_EXECUTED=NO
PARTITION_APPLY_EXECUTED=NO
RETENTION_PURGE_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_14_5_FINAL_STATUS=PASS
