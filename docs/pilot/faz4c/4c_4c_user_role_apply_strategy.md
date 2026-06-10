# FAZ 4C — 4C-4C User / Role Apply Strategy Decision

## Amac

uzmanparcaci pilot kullanicisi ve rol atamasi icin DB apply stratejisini belirlemek.

Bu adim DB'ye yazmaz.

---

## 1. Onceki precheck

4C_4B_DB_PRECHECK_STATUS=PASS
4C_4B_USER_TABLE_COUNT=11
4C_4B_ROLE_TABLE_COUNT=6
4C_4B_MAPPING_TABLE_COUNT=1
4C_4B_EXISTING_USER_COUNT=0
4C_4B_EXISTING_ROLE_COUNT=0

---

## 2. Tenant

TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_SCHEMA=tenant_uzmanparcaci

---

## 3. Secilen user table

SELECTED_USER_TABLE=auth.users
SELECTED_USER_TABLE_SCORE=185

User score details:
auth.user_role_assignments=score:85
auth.user_scopes=score:85
auth.users=score:185
public.erp_account_mapping_rules=score:33
public.erp_account_movements=score:33
public.erp_bank_accounts=score:33
public.erp_cash_accounts=score:33
public.erp_chart_accounts=score:33
public.read_user_projection=score:5
public.read_users=score:20
public.users=score:135


User columns:
id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
email:text:nullable=NO:default=
full_name:text:nullable=NO:default=
password_hash:text:nullable=NO:default=
is_active:boolean:nullable=NO:default=true
is_super_admin:boolean:nullable=NO:default=false
last_login_at:timestamp with time zone:nullable=YES:default=
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
created_by:uuid:nullable=YES:default=
updated_by:uuid:nullable=YES:default=
row_version:bigint:nullable=NO:default=1
deleted_at:timestamp with time zone:nullable=YES:default=

User required no default columns:
tenant_id
email
full_name
password_hash

---

## 4. Secilen role table

SELECTED_ROLE_TABLE=auth.roles
SELECTED_ROLE_TABLE_SCORE=160
ROLE_CODE_COLUMN=role_code

Role score details:
auth.permissions=score:60
auth.role_permissions=score:40
auth.roles=score:160
auth.user_role_assignments=score:75
public.role_permissions=score:0
public.roles=score:115


Role columns:
id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
role_code:text:nullable=NO:default=
role_name:text:nullable=NO:default=
is_system:boolean:nullable=NO:default=false
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()

Role required no default columns:
tenant_id
role_code
role_name

---

## 5. Secilen mapping table

SELECTED_MAPPING_TABLE=auth.user_role_assignments
SELECTED_MAPPING_TABLE_SCORE=205

Mapping score details:
auth.user_role_assignments=score:205


Mapping columns:
id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
user_id:uuid:nullable=NO:default=
role_id:uuid:nullable=NO:default=
legal_entity_id:uuid:nullable=YES:default=
branch_id:uuid:nullable=YES:default=
created_at:timestamp with time zone:nullable=NO:default=now()

Mapping required no default columns:
tenant_id
user_id
role_id

---

## 6. Apply karari

PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN
EXISTING_USER_COUNT=0
EXISTING_ROLE_COUNT=0
USER_CREATE_NEEDED=YES
ROLE_CREATE_NEEDED=YES
ASSIGNMENT_CREATE_NEEDED=YES

---

## 7. Status

4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS=PASS
4C_4C_SELECTED_USER_TABLE=auth.users
4C_4C_SELECTED_ROLE_TABLE=auth.roles
4C_4C_SELECTED_MAPPING_TABLE=auth.user_role_assignments
4C_4C_TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
4C_4C_EXISTING_USER_COUNT=0
4C_4C_EXISTING_ROLE_COUNT=0
4C_4C_USER_CREATE_NEEDED=YES
4C_4C_ROLE_CREATE_NEEDED=YES
4C_4C_ASSIGNMENT_CREATE_NEEDED=YES
4C_4C_USER_REQUIRED_COLUMN_COUNT=4
4C_4C_ROLE_REQUIRED_COLUMN_COUNT=3
4C_4C_MAPPING_REQUIRED_COLUMN_COUNT=3
4C_4C_DB_WRITE_APPLIED=NO
4C_4C_CRITICAL_BLOCKER_COUNT=0
4C_4C_WARNING_COUNT=3
4C_4D_READY=YES
