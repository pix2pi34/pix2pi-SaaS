# FAZ 4C — 4C-5H Controlled Sample Data Apply

## Amaç

uzmanparcaci sample CSV verisini staging/import tablosuna kontrollü şekilde kalıcı olarak uygulamak.

Bu adım gerçek DB write yapar.

---

## 1. SQL dosyası

COMMIT_SQL=sql/pilot/faz4c/4c_5h_commit_product_import_staging_uzmanparcaci.sql
STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
IMPORT_BATCH_CODE=UZMANPARCACI_SAMPLE_4C5E

---

## 2. Apply öncesi durum

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
DO
COMMIT
```

SQL error:

```text

```

---

## 4. Apply sonrası durum

AFTER_TABLE_EXISTS=1
AFTER_ROW_COUNT=5
AFTER_DUPLICATE_SKU_COUNT=0

---

## 5. Status

4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=PASS
4C_5H_SQL_EXECUTION_STATUS=PASS
4C_5H_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5H_BEFORE_TABLE_EXISTS=0
4C_5H_AFTER_TABLE_EXISTS=1
4C_5H_BEFORE_ROW_COUNT=0
4C_5H_AFTER_ROW_COUNT=5
4C_5H_AFTER_DUPLICATE_SKU_COUNT=0
4C_5H_DB_WRITE_APPLIED=YES
4C_5H_CRITICAL_BLOCKER_COUNT=0
4C_5H_WARNING_COUNT=0
4C_5I_READY=YES
