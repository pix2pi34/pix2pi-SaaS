# FAZ 4 / 14.2.2 - Logical Backup Evidence / pg_dump Smoke Test

Amac:
Primary PostgreSQL uzerinden logical backup alinabildigini kanitlamak.

Bu adim:
- DB mutate etmez.
- Restore yapmaz.
- PITR ayari degistirmez.
- Full data dump yerine schema-only smoke dump alir.
- Dump dosyasinin olustugunu ve pg_restore tarafindan okunabildigini kanitlar.
- Raw DSN veya DB sifresi rapora basilmaz.

Kontroller:
1. DB_DSN / DB_WRITE_DSN okunur.
2. DB primary/write oldugu dogrulanir.
3. schema_migrations dirty=false oldugu dogrulanir.
4. pg_dump bulunur.
5. pg_restore bulunur.
6. schema-only custom format dump alinir.
7. dump dosyasi boyutu kontrol edilir.
8. sha256 checksum uretilir.
9. pg_restore --list ile dump okunabilirligi kontrol edilir.
10. Rapor uretilir.

Cikti dosyalari:
backups/db/logical/phase4_14_2_2_<timestamp>/pix2pi_schema_only.dump
backups/db/logical/phase4_14_2_2_<timestamp>/pix2pi_schema_only.dump.sha256
backups/db/logical/phase4_14_2_2_<timestamp>/pg_restore_list.txt

Kapanis hedefi:
LOGICAL_BACKUP_SMOKE=PASS
PG_DUMP_SMOKE=PASS
PG_RESTORE_LIST_CHECK=PASS
FAZ4_14_2_2_FINAL_STATUS=PASS
