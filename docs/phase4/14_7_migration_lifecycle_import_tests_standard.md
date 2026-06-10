# FAZ 4B / 14.7 - Migration / Lifecycle / Import Testleri + Final Closure

Amaç:
FAZ 4B / 14 altında yapılan migration chain, seed standardı, import/staging, backfill/rebuild, retention ve backup/restore verification işlerini tek final test gate altında mühürlemek.

Bu adım:
- DB mutate etmez.
- Migration apply yapmaz.
- Seed apply yapmaz.
- Import apply yapmaz.
- Backfill/rebuild çalıştırmaz.
- Archive/partition/purge çalıştırmaz.
- Backup/restore/PITR çalıştırmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Sadece önceki evidence dosyalarını, manifestleri, migration pairleri ve candidate planları doğrular.
- Raw DSN, password, token veya query text rapora basmaz.

Kapanış hedefi:
MIGRATION_LIFECYCLE_IMPORT_TESTS=PASS
FAZ4B_14_7_FINAL_STATUS=PASS
FAZ4B_14_FINAL_STATUS=PASS
MIGRATION_CHAIN_TEST=PASS
REFERENCE_SEED_TEST=PASS
IMPORT_STAGING_TEST=PASS
BACKFILL_REBUILD_TEST=PASS
RETENTION_MODEL_TEST=PASS
BACKUP_RESTORE_TEST=PASS
SECRET_SAFETY_TEST=PASS
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
