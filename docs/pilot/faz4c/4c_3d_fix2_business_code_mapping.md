# FAZ 4C — 4C-3D-FIX2 business_code Mapping

## Amaç

4C-3E dry-run hatasında eksik görülen business_code mapping eklendi.

---

## Teşhis

Zorunlu kolonlar:

- business_code
- name
- slug

name ve slug önceki SQL paketinde vardı.
business_code eksikti.

---

## Yeni SQL paketi

SQL_FILE=sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql

Yeni insert kolonları:

- business_code
- slug
- name
- status
- created_at
- updated_at

---

## Durum

4C_3D_FIX2_MAPPING_STATUS=PASS
4C_3D_FIX2_SQL_FILE_CREATED=YES
4C_3D_FIX2_EXISTING_TENANT_COUNT=0
4C_3D_FIX2_SCHEMA_EXISTS_COUNT=0
4C_3D_FIX2_DB_WRITE_APPLIED=NO
4C_3E_RETRY_READY=YES
