# FAZ 4C — 4C-4E-FIX1 Dry Run Error Diagnosis

## Amac

4C-4E dry-run neden FAIL oldu, gercek PostgreSQL hatasini yakalamak.

Bu adim kalici DB yazma yapmaz.

---

## 1. Dry-run sonucu

DRY_RUN_STATUS=FAIL
ROLLBACK_SAFE=YES
BEFORE_USER_COUNT=0
AFTER_USER_COUNT=0
BEFORE_ROLE_COUNT=0
AFTER_ROLE_COUNT=0
BEFORE_ASSIGNMENT_COUNT=0
AFTER_ASSIGNMENT_COUNT=0

---

## 2. SQL output
    BEGIN
    DO
    DO

---

## 3. SQL error
    psql:sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql:112: ERROR:  null value in column "password_hash" of relation "users" violates not-null constraint
    DETAIL:  Failing row contains (fa5753f6-be25-4f7a-a996-ec49111c211a, 6dfe8d22-035a-401f-807c-507408d2e439, uzmanparcaci1@gmail.com, mert_omur, null, t, f, null, 2026-05-01 04:47:59.526196+00, 2026-05-01 04:47:59.526196+00, null, null, 1, null).

---

## 4. auth.users kolonlari
    1. id | uuid | udt=pg_catalog.uuid | nullable=NO | default=gen_random_uuid()
    2. tenant_id | uuid | udt=pg_catalog.uuid | nullable=NO | default=
    3. email | text | udt=pg_catalog.text | nullable=NO | default=
    4. full_name | text | udt=pg_catalog.text | nullable=NO | default=
    5. password_hash | text | udt=pg_catalog.text | nullable=NO | default=
    6. is_active | boolean | udt=pg_catalog.bool | nullable=NO | default=true
    7. is_super_admin | boolean | udt=pg_catalog.bool | nullable=NO | default=false
    8. last_login_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=YES | default=
    9. created_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()
    10. updated_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()
    11. created_by | uuid | udt=pg_catalog.uuid | nullable=YES | default=
    12. updated_by | uuid | udt=pg_catalog.uuid | nullable=YES | default=
    13. row_version | bigint | udt=pg_catalog.int8 | nullable=NO | default=1
    14. deleted_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=YES | default=

auth.users required no default:
    tenant_id
    email
    full_name
    password_hash

auth.users constraints:
    17077_17264_10_not_null | CHECK |  | 
    17077_17264_13_not_null | CHECK |  | 
    17077_17264_1_not_null | CHECK |  | 
    17077_17264_2_not_null | CHECK |  | 
    17077_17264_3_not_null | CHECK |  | 
    17077_17264_4_not_null | CHECK |  | 
    17077_17264_5_not_null | CHECK |  | 
    17077_17264_6_not_null | CHECK |  | 
    17077_17264_7_not_null | CHECK |  | 
    17077_17264_9_not_null | CHECK |  | 
    users_pkey | PRIMARY KEY | id | auth.users.id
    users_tenant_id_email_key | UNIQUE | tenant_id | auth.users.tenant_id
    users_tenant_id_email_key | UNIQUE | tenant_id | auth.users.email
    users_tenant_id_email_key | UNIQUE | email | auth.users.email
    users_tenant_id_email_key | UNIQUE | email | auth.users.tenant_id
    users_tenant_id_fkey | FOREIGN KEY | tenant_id | 

---

## 5. auth.roles kolonlari
    1. id | uuid | udt=pg_catalog.uuid | nullable=NO | default=gen_random_uuid()
    2. tenant_id | uuid | udt=pg_catalog.uuid | nullable=NO | default=
    3. role_code | text | udt=pg_catalog.text | nullable=NO | default=
    4. role_name | text | udt=pg_catalog.text | nullable=NO | default=
    5. is_system | boolean | udt=pg_catalog.bool | nullable=NO | default=false
    6. created_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()
    7. updated_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()

auth.roles required no default:
    tenant_id
    role_code
    role_name

auth.roles constraints:
    17077_17284_1_not_null | CHECK |  | 
    17077_17284_2_not_null | CHECK |  | 
    17077_17284_3_not_null | CHECK |  | 
    17077_17284_4_not_null | CHECK |  | 
    17077_17284_5_not_null | CHECK |  | 
    17077_17284_6_not_null | CHECK |  | 
    17077_17284_7_not_null | CHECK |  | 
    roles_pkey | PRIMARY KEY | id | auth.roles.id
    roles_tenant_id_fkey | FOREIGN KEY | tenant_id | 
    roles_tenant_id_role_code_key | UNIQUE | tenant_id | auth.roles.role_code
    roles_tenant_id_role_code_key | UNIQUE | tenant_id | auth.roles.tenant_id
    roles_tenant_id_role_code_key | UNIQUE | role_code | auth.roles.role_code
    roles_tenant_id_role_code_key | UNIQUE | role_code | auth.roles.tenant_id

---

## 6. auth.user_role_assignments kolonlari
    1. id | uuid | udt=pg_catalog.uuid | nullable=NO | default=gen_random_uuid()
    2. tenant_id | uuid | udt=pg_catalog.uuid | nullable=NO | default=
    3. user_id | uuid | udt=pg_catalog.uuid | nullable=NO | default=
    4. role_id | uuid | udt=pg_catalog.uuid | nullable=NO | default=
    5. legal_entity_id | uuid | udt=pg_catalog.uuid | nullable=YES | default=
    6. branch_id | uuid | udt=pg_catalog.uuid | nullable=YES | default=
    7. created_at | timestamp with time zone | udt=pg_catalog.timestamptz | nullable=NO | default=now()

auth.user_role_assignments required no default:
    tenant_id
    user_id
    role_id

auth.user_role_assignments constraints:
    17077_17330_1_not_null | CHECK |  | 
    17077_17330_2_not_null | CHECK |  | 
    17077_17330_3_not_null | CHECK |  | 
    17077_17330_4_not_null | CHECK |  | 
    17077_17330_7_not_null | CHECK |  | 
    user_role_assignments_branch_id_fkey | FOREIGN KEY | branch_id | 
    user_role_assignments_legal_entity_id_fkey | FOREIGN KEY | legal_entity_id | 
    user_role_assignments_pkey | PRIMARY KEY | id | auth.user_role_assignments.id
    user_role_assignments_role_id_fkey | FOREIGN KEY | role_id | auth.roles.id
    user_role_assignments_tenant_id_fkey | FOREIGN KEY | tenant_id | 
    user_role_assignments_user_id_fkey | FOREIGN KEY | user_id | auth.users.id

---

## 7. Status

4C_4E_FIX1_DIAGNOSIS_STATUS=PASS
4C_4E_FIX1_DRY_RUN_STATUS=FAIL
4C_4E_FIX1_ROLLBACK_SAFE=YES
4C_4E_FIX1_DB_WRITE_APPLIED=NO
4C_4D_FIX4_READY=YES
