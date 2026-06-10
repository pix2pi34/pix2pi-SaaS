# FAZ 4 / 14.1.2 - Migration Apply / Dry-Run / Dirty Check Standardi

Amac:
Migration calistirma oncesi guvenlik kapisini standart hale getirmek.

Bu adim canli DB'ye migration apply etmez.

Aktif migration root:
db/migrations

Zorunlu apply oncesi kontroller:
1. Aktif migration root dogrulanir.
2. Migration chain validator PASS olmali.
3. Up/down pair kontrolu PASS olmali.
4. Migration tool durumu raporlanmali.
5. DB_DSN / DB_WRITE_DSN / DATABASE_URL durumu raporlanmali.
6. Dirty state kontrolu yapilmali veya neden yapilamadigi raporlanmali.
7. Apply icin APPLY=1 zorunludur.
8. Apply icin BACKUP_GATE=CONFIRMED zorunludur.

Desteklenen modlar:
status
dry-run
apply-check

Kapanis kriteri:
PHASE4_MIGRATION_APPLY_GATE_STATUS_TEST=PASS
PHASE4_MIGRATION_APPLY_GATE_DRY_RUN_TEST=PASS
PHASE4_MIGRATION_APPLY_GATE_BAD_FIXTURE_TEST=PASS
PHASE4_MIGRATION_APPLY_GATE_APPLY_LOCK_TEST=PASS
MIGRATION_APPLY_GATE=PASS
FAZ4_14_1_2_FINAL_STATUS=PASS
