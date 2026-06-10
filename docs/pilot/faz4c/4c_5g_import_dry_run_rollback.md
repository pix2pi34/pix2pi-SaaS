# FAZ 4C — 4C-5G Import Dry Run / ROLLBACK Verification

## Amaç

4C-5F SQL preview paketini çalıştırmak, staging insertlerinin transaction içinde başarılı olduğunu görmek ve ROLLBACK sonrası kalıcı DB yazma olmadığını doğrulamak.

Bu adım kalıcı DB yazma yapmaz.

---

## 1. SQL dosyası

SQL_FILE=sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql
STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
IMPORT_BATCH_CODE=UZMANPARCACI_SAMPLE_4C5E

---

## 2. Dry-run öncesi durum

BEFORE_TABLE_EXISTS=0
BEFORE_ROW_COUNT=0
BEFORE_DUPLICATE_SKU_COUNT=0

---

## 3. SQL execution

SQL_EXECUTION_STATUS=PASS

SQL output:

```text
BEGIN
DO
DO
CREATE TABLE
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
staging_row_count|5
duplicate_sku_count|0
ROLLBACK
```

SQL error:

```text

```

---

## 4. SQL output verification

SQL_OUTPUT_STAGING_ROW_COUNT=5
SQL_OUTPUT_DUPLICATE_SKU_COUNT=0

---

## 5. Dry-run sonrası durum

AFTER_TABLE_EXISTS=0
AFTER_ROW_COUNT=0
AFTER_DUPLICATE_SKU_COUNT=0

---

## 6. Rollback doğrulama

ROLLBACK_VERIFIED=YES

---

## 7. Status

4C_5G_IMPORT_DRY_RUN_STATUS=PASS
4C_5G_SQL_EXECUTION_STATUS=PASS
4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=5
4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=0
4C_5G_BEFORE_TABLE_EXISTS=0
4C_5G_AFTER_TABLE_EXISTS=0
4C_5G_BEFORE_ROW_COUNT=0
4C_5G_AFTER_ROW_COUNT=0
4C_5G_ROLLBACK_VERIFIED=YES
4C_5G_DB_WRITE_APPLIED=NO
4C_5G_CRITICAL_BLOCKER_COUNT=0
4C_5G_WARNING_COUNT=0
4C_5H_READY=YES
