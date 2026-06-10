# FAZ 4B / 14.1 - Migration Chain Standardı

Amaç:
Pilot öncesi migration zincirinin güvenli, izlenebilir, idempotent ve rollback mantığına uygun olduğunu kanıtlamak.

Bu adım:
- DB migration apply yapmaz.
- DB mutate etmez.
- SQL apply çalıştırmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Sadece migration dosyalarını ve varsa schema_migrations durumunu okur.
- Raw DSN, password, token veya query text rapora basmaz.

Desteklenen migration isim formatları:

1) Legacy format:
- `<seq>_<name>.up.sql`
- `<seq>_<name>.down.sql`

Örnek:
- `001_phase1_foundation.up.sql`
- `001_phase1_foundation.down.sql`

2) Modern timestamp format:
- `<yyyymmdd>_<seq>_<name>.up.sql`
- `<yyyymmdd>_<seq>_<name>.down.sql`

Örnek:
- `20260425_090101_erp_master_party.up.sql`
- `20260425_090101_erp_master_party.down.sql`

Standart:
1. Migration dosyaları `db/migrations` altında olmalı.
2. Her `up.sql` için eşleşen `down.sql` olmalı.
3. Her `down.sql` için eşleşen `up.sql` olmalı.
4. Duplicate migration version olmamalı.
5. Duplicate base name olmamalı.
6. `up.sql` içinde shell/system/config komutu olmamalı.
7. `down.sql` rollback dosyası boş olmamalı.
8. Migration chain inventory üretilmeli.
9. Final reconciliation raporu üretilmeli.
10. Eski legacy migration dosyaları rename edilmeden desteklenmeli.

Kapanış hedefi:
MIGRATION_CHAIN_STANDARD=PASS
MIGRATION_PAIRING_STATUS=PASS
MIGRATION_NAMING_STATUS=PASS
MIGRATION_DUPLICATE_STATUS=PASS
MIGRATION_ROLLBACK_FILE_STATUS=PASS
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_14_1_FINAL_STATUS=PASS
