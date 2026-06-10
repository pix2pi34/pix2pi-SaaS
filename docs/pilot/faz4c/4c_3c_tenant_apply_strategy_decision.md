# FAZ 4C — 4C-3C Tenant Apply Strategy Decision

## Blok

4C-3C — Tenant Apply Strategy Decision

## Amac

Bu adim uzmanparcaci tenant kurulumu icin uygulanacak DB stratejisini belirler.

Bu adim DB'ye yazmaz.
Bu adim schema olusturmaz.
Bu adim tenant kaydi olusturmaz.
Bu adim sadece strateji karari uretir.

---

## 1. Onceki adim durumu

4C_3B_DB_TENANT_PRECHECK_STATUS=PASS
4C_3B_DB_CONNECT_STATUS=PASS
4C_3B_TENANT_SCHEMA_STATUS=MISSING
4C_3B_TENANT_TABLE_COUNT=3

---

## 2. Tenant identity

TENANT_DISPLAY_NAME=uzmanparcaci
TENANT_CODE=uzmanparcaci
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_OWNER_EMAIL=uzmanparcaci1@gmail.com
TENANT_OWNER_PHONE=5377457536

---

## 3. Tenant tablo adaylari

Aday tenant tablolar:

```text
platform.tenants
public.tenants
readmodel.tenant_operational_snapshot
```

Detay ve skor:


## platform.tenants

SCORE=84

```text
id:uuid
business_code:text
name:text
slug:text
timezone:text
country_code:character
status:USER-DEFINED
owner_legal_entity_id:uuid
data_partition_key:text
created_at:timestamp with time zone
updated_at:timestamp with time zone
created_by:uuid
updated_by:uuid
row_version:bigint
deleted_at:timestamp with time zone
```

## public.tenants

SCORE=71

```text
id:bigint
name:text
created_at:timestamp with time zone
active:boolean
plan:text
features:jsonb
org_root_id:uuid
```

## readmodel.tenant_operational_snapshot

SCORE=30

```text
tenant_id:text
legal_entity_count:integer
branch_count:integer
active_user_count:integer
customer_count:integer
vendor_count:integer
product_count:integer
open_sales_document_count:integer
open_purchase_document_count:integer
stock_alert_count:integer
pending_document_count:integer
pending_payment_count:integer
last_event_time:timestamp with time zone
refreshed_at:timestamp with time zone
updated_at:timestamp with time zone
```


---

## 4. Secilen strateji

En uygun tenant metadata tablo adayi:

SELECTED_TENANT_TABLE=platform.tenants
SELECTED_TENANT_TABLE_SCORE=84

Karar:

TENANT_TABLE_STRATEGY=USE_EXISTING_CANDIDATE_TABLE
TENANT_METADATA_INSERT_NEEDED=YES
TENANT_SCHEMA_APPLY_NEEDED=YES
TENANT_SCHEMA_CREATE_NEEDED=YES

---

## 5. Apply sirasi

4C-3D adiminda sadece apply paketi hazirlanacak.

Onerilen apply sirasi:

1. DB yedek/guard kontrolu
2. Tenant metadata tablo kolon mapping kontrolu
3. Tenant zaten var mi tekrar kontrolu
4. Tenant schema zaten var mi tekrar kontrolu
5. CREATE SCHEMA guardli SQL hazirligi
6. Tenant metadata INSERT guardli SQL hazirligi
7. Verification SQL hazirligi
8. Dry-run / preview
9. Sonra ayri adimda apply

---

## 6. SQL apply preview

Bu adimda apply yoktur.

Gelecek adimda hazirlanacak SQL mantigi:

```sql
-- 1. tenant schema guard
CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci;

-- 2. tenant metadata insert
-- selected table: platform.tenants
-- kolon mapping 4C-3D adiminda netlestirilecek
```

---

## 7. Risk karari

Schema missing durumu normaldir.
Bu, yeni pilot tenant icin beklenen durumdur.

Tenant table count 3 oldugu icin dogrudan insert yapilmaz.
Once selected table kolonlari netlestirilecek.

---

## 8. Status

4C_3C_TENANT_APPLY_STRATEGY_STATUS=PASS
4C_3C_SELECTED_TENANT_TABLE=platform.tenants
4C_3C_SELECTED_TENANT_TABLE_SCORE=84
4C_3C_TENANT_SCHEMA_STATUS=MISSING
4C_3C_TENANT_SCHEMA_CREATE_NEEDED=YES
4C_3C_TENANT_METADATA_INSERT_NEEDED=YES
4C_3C_TENANT_TABLE_STRATEGY=USE_EXISTING_CANDIDATE_TABLE
4C_3C_DB_WRITE_APPLIED=NO
4C_3C_CRITICAL_BLOCKER_COUNT=0
4C_3C_WARNING_COUNT=1
4C_3C_NEXT_STEP_READY=YES
4C_3D_READY=YES

---

## 9. Sonraki adim

Sonraki adim:

4C-3D — Tenant Apply SQL Package / Dry Run Plan

Bu adimda DB apply scripti hazirlanacak ama dogrudan apply edilmeyecek.
