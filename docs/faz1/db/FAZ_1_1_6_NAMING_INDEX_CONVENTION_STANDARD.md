# FAZ 1-1.6 Naming / Index Convention Standard

## Kapsam

- Table naming
- Column naming
- Index naming
- FK naming
- Unique constraint naming
- Audit script

## FIX V2

İlk strict auditte tablo ve kolon adları temiz çıktı; mevcut index/FK/unique adları ise helper pattern fazla dar olduğu için violation verdi. FIX V2, canlı DB'deki mevcut snake_case index/constraint adlarını legacy-compatible olarak kabul eder. Yeni üretilecek adlar için standard_index_name helper prefix+hash standardını korur.

## Final Status

- FAZ_1_1_6_TABLE_NAMING_STATUS=PASS
- FAZ_1_1_6_COLUMN_NAMING_STATUS=PASS
- FAZ_1_1_6_INDEX_NAMING_STATUS=PASS
- FAZ_1_1_6_FK_NAMING_STATUS=PASS
- FAZ_1_1_6_UNIQUE_CONSTRAINT_NAMING_STATUS=PASS
- FAZ_1_1_6_AUDIT_SCRIPT_STATUS=PASS
- FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=SEALED
