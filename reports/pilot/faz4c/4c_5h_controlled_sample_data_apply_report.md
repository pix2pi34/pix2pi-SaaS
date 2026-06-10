# FAZ 4C — 4C-5H Controlled Sample Data Apply Report

Step: 4C-5H
Blok: Controlled Sample Data Apply
Test tarihi: 2026-05-01 08:11:35

## Test sonucu

4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=PASS
4C_5H_SQL_EXECUTION_STATUS=PASS
4C_5H_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5H_BEFORE_TABLE_EXISTS=0
4C_5H_AFTER_TABLE_EXISTS=1
4C_5H_BEFORE_ROW_COUNT=0
4C_5H_AFTER_ROW_COUNT=5
4C_5H_BEFORE_DUPLICATE_SKU_COUNT=0
4C_5H_AFTER_DUPLICATE_SKU_COUNT=0
4C_5H_DB_WRITE_APPLIED=YES
4C_5H_CRITICAL_BLOCKER_COUNT=0
4C_5H_WARNING_COUNT=0
4C_5I_READY=YES

## SQL output

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

## SQL error

```text

```

## Sonuc

Controlled sample data apply tamamlandi.
uzmanparcaci sample ürün verileri staging tabloya kalıcı olarak işlendi.
Sonraki adim: 4C-5I Sample Data Verification.
