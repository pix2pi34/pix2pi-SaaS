# FAZ 4C — 4C-5F Import SQL Package / Dry Run Plan

## Amaç

uzmanparcaci sample CSV verisini staging/import tablosuna alacak SQL preview paketini üretmek.

Bu adım DB'ye yazmaz.

---

## Ön koşullar

4C_5E_SAMPLE_CSV_VALIDATION_STATUS=PASS
4C_5E_SAMPLE_ROW_COUNT=5
4C_5E_ROW_ERROR_COUNT=0
4C_5F_READY=YES

---

## Seçilen strateji

SELECTED_IMPORT_MAPPING_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING
CORE_DIRECT_APPLY_NOW=NO
STAGING_TABLE_CREATE_NEEDED=YES
STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging

---

## SQL preview

SQL_FILE=sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql

Bu SQL:

- BEGIN ile başlar
- tenant doğrulaması yapar
- tenant schema doğrulaması yapar
- staging tabloyu CREATE TABLE IF NOT EXISTS ile hazırlar
- 5 sample CSV satırını staging tabloya INSERT eder
- staging row count doğrulaması yapar
- duplicate SKU kontrolü yapar
- ROLLBACK ile biter

---

## Güvenlik kararı

4C-5F sadece SQL dosyası üretir.
4C-5F SQL çalıştırmaz.
4C-5F DB write yapmaz.
Dry-run execution 4C-5G içinde yapılacaktır.

---

## Status

4C_5F_IMPORT_SQL_PACKAGE_STATUS=PASS
4C_5F_SQL_FILE_CREATED=YES
4C_5F_SQL_FILE=sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql
4C_5F_SQL_HAS_BEGIN=YES
4C_5F_SQL_HAS_ROLLBACK=YES
4C_5F_SQL_HAS_COMMIT=NO
4C_5F_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES
4C_5F_SAMPLE_INSERT_COUNT=5
4C_5F_EXPECTED_INSERT_COUNT=5
4C_5F_DB_WRITE_APPLIED=NO
4C_5F_CRITICAL_BLOCKER_COUNT=0
4C_5F_WARNING_COUNT=0
4C_5G_READY=YES
