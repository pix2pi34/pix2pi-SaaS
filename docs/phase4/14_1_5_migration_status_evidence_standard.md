# FAZ 4 / 14.1.5 - Migration Status / Current Version Evidence

Amac:
Primary DB uzerinde migration durumunu apply yapmadan kanitlamak.

Bu adim DB mutate etmez.

Kontroller:
1. DB_DSN / DB_WRITE_DSN .env icinden okunur.
2. Raw DSN ve password rapora basilmaz.
3. DB baglantisi test edilir.
4. pg_is_in_recovery() ile primary oldugu dogrulanir.
5. public.schema_migrations tablosu kontrol edilir.
6. dirty state okunur.
7. current version okunur.
8. db/migrations altindaki dosya zinciri ile DB version uyumu raporlanir.
9. Migration apply yapilmaz.

Kapanis hedefi:
MIGRATION_STATUS_EVIDENCE=PASS
DB_ROLE=PRIMARY_WRITE
SCHEMA_MIGRATIONS_DIRTY_STATE=f
FAZ4_14_1_5_FINAL_STATUS=PASS
