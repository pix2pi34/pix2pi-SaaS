# FAZ 4C — 4C-3D Tenant Apply SQL Package / Dry Run Plan

## Blok

4C-3D — Tenant Apply SQL Package / Dry Run Plan

## Amac

Bu adim uzmanparcaci tenant kurulumu icin SQL paketini hazirlar.

Bu adim DB'ye yazmaz.
Bu adim schema olusturmaz.
Bu adim tenant kaydi olusturmaz.
Bu adim sadece SQL preview paketi uretir.

---

## 1. Onceki karar

4C_3C_SELECTED_TENANT_TABLE=platform.tenants
4C_3C_TENANT_SCHEMA_CREATE_NEEDED=YES
4C_3C_TENANT_METADATA_INSERT_NEEDED=YES

---

## 2. Selected tenant table

SELECTED_TENANT_TABLE=platform.tenants
TABLE_EXISTS=1

Kolonlar:

```text
id:uuid:nullable=NO:default=gen_random_uuid()
business_code:text:nullable=NO:default=
name:text:nullable=NO:default=
slug:text:nullable=NO:default=
timezone:text:nullable=NO:default='Europe/Istanbul'::text
country_code:character:nullable=NO:default='TR'::bpchar
status:USER-DEFINED:nullable=NO:default='active'::core.record_status
owner_legal_entity_id:uuid:nullable=YES:default=
data_partition_key:text:nullable=YES:default=
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
created_by:uuid:nullable=YES:default=
updated_by:uuid:nullable=YES:default=
row_version:bigint:nullable=NO:default=1
deleted_at:timestamp with time zone:nullable=YES:default=
```

---

## 3. Tenant identity

TENANT_CODE=uzmanparcaci
TENANT_SLUG=uzmanparcaci
TENANT_DISPLAY_NAME=uzmanparcaci
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_SECTOR=OTO_YEDEK_PARCA
TENANT_OWNER_EMAIL=uzmanparcaci1@gmail.com
TENANT_OWNER_PHONE=5377457536

---

## 4. Existing kontrol

EXISTING_TENANT_COUNT_BY_CODE=0
TENANT_SCHEMA_EXISTS_COUNT=0

---

## 5. Insert mapping

INSERT_COLUMN_COUNT=5

Mapping:

- slug <= uzmanparcaci
- name <= uzmanparcaci
- status <= active
- created_at <= now()
- updated_at <= now()


---

## 6. SQL package

SQL preview dosyasi:

sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql

Bu dosya ROLLBACK ile biter.
Bu adimda apply yoktur.

---

## 7. Karar

4C_3D_SQL_PACKAGE_STATUS=PASS
4C_3D_SELECTED_TENANT_TABLE=platform.tenants
4C_3D_TENANT_SCHEMA=tenant_uzmanparcaci
4C_3D_INSERT_COLUMN_COUNT=5
4C_3D_EXISTING_TENANT_COUNT_BY_CODE=0
4C_3D_TENANT_SCHEMA_EXISTS_COUNT=0
4C_3D_SQL_FILE_CREATED=YES
4C_3D_DB_WRITE_APPLIED=NO
4C_3D_CRITICAL_BLOCKER_COUNT=0
4C_3D_WARNING_COUNT=0
4C_3D_NEXT_STEP_READY=YES
4C_3E_READY=YES

---

## 8. Sonraki adim

Sonraki adim:

4C-3E — Tenant SQL Dry Run Execution / ROLLBACK Verification

Bu adimda SQL preview ROLLBACK ile calistirilacak, kalici yazma yapilmadan dogrulanacak.
