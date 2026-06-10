# FAZ 4 / 14.1.6 - Migration Drift / DB Object Existence Evidence

Amac:
Migration dosyalarinda beklenen DB objeleri ile gercek primary DB semasi arasinda drift var mi kanitlamak.

Bu adim:
- DB mutate etmez.
- Migration apply yapmaz.
- Migration dosyalarini rename etmez.
- Sadece analiz ve rapor uretir.

Kontrol edilen objeler:
1. CREATE SCHEMA
2. CREATE TABLE
3. CREATE INDEX
4. CREATE UNIQUE INDEX

Kritik sebep:
schema_migrations version 2 gorunuyor olabilir ama Faz 3 ERP tablolarinin gercek DB'de var oldugu kanitlanmis olabilir.
Bu yuzden migration state ile real DB object state ayri ayri kanitlanmalidir.

Kapanis hedefi:
MIGRATION_DRIFT_EVIDENCE=PASS
DB_ROLE=PRIMARY_WRITE
EXPECTED_OBJECT_COUNT raporlanir
EXISTING_OBJECT_COUNT raporlanir
MISSING_OBJECT_COUNT raporlanir
DRIFT_STATUS raporlanir
FAZ4_14_1_6_FINAL_STATUS=PASS
