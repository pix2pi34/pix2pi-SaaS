# FAZ 4 / 14.2.1 - DB Backup / Restore / PITR Readiness Discovery

Amac:
Primary PostgreSQL icin backup, restore ve PITR hazirlik seviyesini kanitlamak.

Bu adim:
- DB mutate etmez.
- Backup silmez.
- Restore yapmaz.
- PITR ayari degistirmez.
- Sadece mevcut durumu okur ve raporlar.

Kontroller:
1. DB DSN bulunur ama raw password rapora basilmaz.
2. DB primary/write mi kontrol edilir.
3. schema_migrations dirty=false mi kontrol edilir.
4. PostgreSQL wal_level okunur.
5. archive_mode okunur.
6. archive_command okunur.
7. max_wal_senders okunur.
8. backup dizinleri tespit edilir.
9. restic var mi kontrol edilir.
10. pg_dump var mi kontrol edilir.
11. pg_restore var mi kontrol edilir.
12. restore drill icin eksikler raporlanir.

Durum mantigi:
- Bu adim discovery oldugu icin eksiklerde script fail olmaz.
- Eksikler WARN olarak raporlanir.
- Kritik DB baglantisi / primary kontrolu bozuksa FAIL olur.

Kapanis hedefi:
DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS
DB_ROLE=PRIMARY_WRITE
DB_CONNECTION_CHECK=PASS
RESTORE_DRILL_READY raporlanir
PITR_READY raporlanir
FAZ4_14_2_1_FINAL_STATUS=PASS
