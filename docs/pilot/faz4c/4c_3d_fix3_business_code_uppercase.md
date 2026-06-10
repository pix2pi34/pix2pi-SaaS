# FAZ 4C — 4C-3D-FIX3 business_code Uppercase Fix

## Amaç

core.code_text domain kuralına göre business_code değerini düzeltmek.

---

## Domain kuralı

core.code_text kabul formatı:

```text
^[A-Z0-9_\-]+$
```

---

## Karar

BUSINESS_CODE=UZMANPARCACI
SLUG=uzmanparcaci
NAME=uzmanparcaci
TENANT_SCHEMA=tenant_uzmanparcaci

---

## Status

4C_3D_FIX3_BUSINESS_CODE_UPPERCASE_STATUS=PASS
4C_3D_FIX3_BUSINESS_CODE_CAST_STATUS=PASS
4C_3D_FIX3_EXISTING_TENANT_COUNT=0
4C_3D_FIX3_SCHEMA_EXISTS_COUNT=0
4C_3D_FIX3_SQL_FILE_CREATED=YES
4C_3D_FIX3_DB_WRITE_APPLIED=NO
4C_3E_RETRY_READY=YES
