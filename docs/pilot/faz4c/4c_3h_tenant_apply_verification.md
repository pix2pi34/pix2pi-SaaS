# FAZ 4C — 4C-3H Tenant Apply Verification / Isolation Smoke

## Amaç

uzmanparcaci gerçek pilot tenant kaydının DB'de doğru oluştuğunu doğrulamak.

Bu adım kalıcı DB yazma yapmaz.

---

## 1. Tenant doğrulama

SCHEMA_COUNT=1
TENANT_COUNT_BY_SLUG=1
TENANT_COUNT_BY_CODE=1
TENANT_DUPLICATE_COUNT=1

---

## 2. Tenant row

```text
UZMANPARCACI | uzmanparcaci | uzmanparcaci | active
```

---

## 3. Tenant schema listesi

```text
tenant_uzmanparcaci
```

---

## 4. Isolation smoke

SEARCH_PATH_STATUS=PASS
SEARCH_PATH_OUTPUT=ROLLBACK
CODE_CAST_STATUS=PASS

---

## 5. Status

4C_3H_TENANT_VERIFICATION_STATUS=PASS
4C_3H_SCHEMA_EXISTS=YES
4C_3H_TENANT_METADATA_EXISTS=YES
4C_3H_DUPLICATE_TENANT_COUNT=1
4C_3H_SEARCH_PATH_SMOKE_STATUS=PASS
4C_3H_CODE_CAST_STATUS=PASS
4C_3H_DB_WRITE_APPLIED=NO
4C_3H_CRITICAL_BLOCKER_COUNT=0
4C_3H_WARNING_COUNT=0
4C_3I_READY=YES
