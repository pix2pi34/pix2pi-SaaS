# FAZ 4 / 14.1.6A - Index Parser Correction / Schema-Aware Drift Evidence

Amac:
14.1.6 drift evidence scriptindeki index parser hatasini duzeltmek.

Sorun:
CREATE INDEX idx_name ON schema.table ifadesinde eski parser index adini
"idx_name ON schema.table" seklinde yakalayabiliyordu.

Dogru model:
INDEX_NAME = idx_name
INDEX_TABLE = schema.table

DB kontrolu:
Index varligi pg_indexes uzerinden kontrol edilir.

Bu adim:
- DB mutate etmez.
- Migration apply yapmaz.
- Migration dosyalarini rename etmez.
- Sadece drift evidence scriptini daha dogru hale getirir.

Kapanis hedefi:
PHASE4_INDEX_PARSER_CORRECTION_TEST=PASS
MIGRATION_DRIFT_EVIDENCE=PASS
INDEX_PARSE_CORRECTION=PASS
FAZ4_14_1_6A_FINAL_STATUS=PASS
