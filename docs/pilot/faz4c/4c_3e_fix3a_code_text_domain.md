# FAZ 4C — 4C-3E-FIX3A code_text Domain Discovery

## Amaç

platform.tenants.business_code için gerekli core.code_text formatını keşfetmek.

Bu adım DB'ye yazmaz.

---

## 1. DB bağlantı

4C_3E_FIX3A_DB_CONNECT_STATUS=PASS

---

## 2. Domain bilgisi

```text
core.code_text | base=text | notnull=false
```

---

## 3. Domain constraint

```text
code_text_check | CHECK ((VALUE ~ '^[A-Z0-9_\-]+$'::text))
```

---

## 4. platform.tenants kolonları

```text
1. id | uuid | udt=pg_catalog.uuid | nullable=NO | default=gen_random_uuid()
2. business_code | text | udt=pg_catalog.text | nullable=NO | default=
3. name | text | udt=pg_catalog.text | nullable=NO | default=
4. slug | text | udt=pg_catalog.text | nullable=NO | default=
5. timezone | text | udt=pg_catalog.text | nullable=NO | default='Europe/Istanbul'::text
6. country_code | character | udt=pg_catalog.bpchar | nullable=NO | default='TR'::bpchar
7. status | USER-DEFINED | udt=core.record_status | nullable=NO | default='active'::core.record_status
8. owner_legal_entity_id | uuid | udt=pg_catalog.uuid | nullable=YES | default=
9. data_partition_key | text | udt=pg_catalog.text | nullable=YES | default=
10. created_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()
11. updated_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()
12. created_by | uuid | udt=pg_catalog.uuid | nullable=YES | default=
13. updated_by | uuid | udt=pg_catalog.uuid | nullable=YES | default=
14. row_version | bigint | udt=pg_catalog.int8 | nullable=NO | default=1
15. deleted_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=YES | default=
```

---

## 5. Mevcut tenant code örnekleri

```text

```

---

## 6. Domain cast testleri

```text
uzmanparcaci => FAIL
UZMANPARCACI => PASS
UZMAN_PARCACI => PASS
TENANT_UZMANPARCACI => PASS
UZMAN-PARCACI => PASS
uzman_parcaci => FAIL
UZMAN PARCACI => FAIL

```

---

## 7. Önerilen business_code

BEST_BUSINESS_CODE=UZMANPARCACI

---

## 8. Status

4C_3E_FIX3A_DOMAIN_DISCOVERY_STATUS=PASS
4C_3E_FIX3A_DB_WRITE_APPLIED=NO
4C_3D_FIX3_READY=YES
