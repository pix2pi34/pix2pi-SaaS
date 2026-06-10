# FAZ 4C — 4C-3E-FIX1 Dry Run Error Diagnosis

## Amaç

4C-3E dry-run neden FAIL oldu, gerçek PostgreSQL hatasını yakalamak.

Bu adım kalıcı DB yazma yapmaz.

---

## 1. DB bağlantı

4C_3E_FIX1_DB_CONNECT_STATUS=PASS

---

## 2. platform.tenants kolonları

```text
1. id | uuid | nullable=NO | default=gen_random_uuid()
2. business_code | text | nullable=NO | default=
3. name | text | nullable=NO | default=
4. slug | text | nullable=NO | default=
5. timezone | text | nullable=NO | default='Europe/Istanbul'::text
6. country_code | character | nullable=NO | default='TR'::bpchar
7. status | USER-DEFINED | nullable=NO | default='active'::core.record_status
8. owner_legal_entity_id | uuid | nullable=YES | default=
9. data_partition_key | text | nullable=YES | default=
10. created_at | timestamp with time zone | nullable=NO | default=now()
11. updated_at | timestamp with time zone | nullable=NO | default=now()
12. created_by | uuid | nullable=YES | default=
13. updated_by | uuid | nullable=YES | default=
14. row_version | bigint | nullable=NO | default=1
15. deleted_at | timestamp with time zone | nullable=YES | default=
```

---

## 3. Zorunlu olup default değeri olmayan kolonlar

```text
business_code
name
slug
```

NOT_NULL_NO_DEFAULT_COLUMN_COUNT=3

---

## 4. Dry-run sonucu

DRY_RUN_STATUS=FAIL

SQL output:

```text
BEGIN
DO
DO
CREATE SCHEMA
```

SQL error:

```text
psql:sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql:87: ERROR:  value for domain core.code_text violates check constraint "code_text_check"
```

---

## 5. Rollback güvenliği

BEFORE_SCHEMA_COUNT=0
AFTER_SCHEMA_COUNT=0
BEFORE_TENANT_COUNT=0
AFTER_TENANT_COUNT=0
ROLLBACK_SAFE=YES

---

## 6. Karar

4C_3E_FIX1_DIAGNOSIS_STATUS=PASS
4C_3E_FIX1_DRY_RUN_STATUS=FAIL
4C_3E_FIX1_ROLLBACK_SAFE=YES
4C_3E_FIX1_DB_WRITE_APPLIED=NO
4C_3E_FIX1_NEXT_STEP_READY=YES
