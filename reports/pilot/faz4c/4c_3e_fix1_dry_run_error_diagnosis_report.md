# FAZ 4C — 4C-3E-FIX1 Dry Run Error Diagnosis Report

Step: 4C-3E-FIX1B
Blok: Dry Run Error Diagnosis
Test tarihi: 2026-05-01 07:21:12

## Test sonucu

4C_3E_FIX1_DIAGNOSIS_STATUS=PASS
4C_3E_FIX1_DB_CONNECT_STATUS=PASS
4C_3E_FIX1_DRY_RUN_STATUS=FAIL
4C_3E_FIX1_NOT_NULL_NO_DEFAULT_COLUMN_COUNT=3
4C_3E_FIX1_ROLLBACK_SAFE=YES
4C_3E_FIX1_DB_WRITE_APPLIED=NO
4C_3E_FIX1_NEXT_STEP_READY=YES

## SQL error

```text
psql:sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql:87: ERROR:  value for domain core.code_text violates check constraint "code_text_check"
```

## Zorunlu default olmayan kolonlar

```text
business_code
name
slug
```

## Sonuç

Dry-run hatası yakalandı.
Kalıcı DB yazma yapılmadı.
Bir sonraki adımda SQL mapping düzeltilecek.
