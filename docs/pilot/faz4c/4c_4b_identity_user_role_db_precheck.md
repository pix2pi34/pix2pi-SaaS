# FAZ 4C — 4C-4B Identity User / Role DB Precheck

## Amac

uzmanparcaci tenant icin kullanici, rol ve user-role mapping tablolarini kesfetmek.

Bu adim DB'ye yazmaz.

---

## 1. Tenant kontrolu

TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_COUNT=1
TENANT_SCHEMA_COUNT=1

---

## 2. Pilot kullanici / rol

PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN

---

## 3. User tablo adaylari

USER_TABLE_COUNT=11

auth.user_role_assignments
auth.user_scopes
auth.users
public.erp_account_mapping_rules
public.erp_account_movements
public.erp_bank_accounts
public.erp_cash_accounts
public.erp_chart_accounts
public.read_user_projection
public.read_users
public.users

---

## 4. User tablo detaylari

### auth.user_role_assignments

id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
user_id:uuid:nullable=NO:default=
role_id:uuid:nullable=NO:default=
legal_entity_id:uuid:nullable=YES:default=
branch_id:uuid:nullable=YES:default=
created_at:timestamp with time zone:nullable=NO:default=now()

### auth.user_scopes

id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
user_id:uuid:nullable=NO:default=
scope_level:USER-DEFINED:nullable=NO:default=
legal_entity_id:uuid:nullable=YES:default=
branch_id:uuid:nullable=YES:default=
can_view:boolean:nullable=NO:default=true
can_edit:boolean:nullable=NO:default=false
can_export:boolean:nullable=NO:default=false
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()

### auth.users

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

### public.erp_account_mapping_rules

account_mapping_rule_id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:text:nullable=NO:default=
mapping_key:text:nullable=NO:default=
source_module:text:nullable=NO:default=
source_document_type:text:nullable=YES:default=
event_type:text:nullable=YES:default=
line_type:text:nullable=YES:default=
account_code:text:nullable=NO:default=
account_name:text:nullable=YES:default=
vat_rate:numeric:nullable=YES:default=
priority:integer:nullable=NO:default=100
is_default:boolean:nullable=NO:default=false
is_active:boolean:nullable=NO:default=true
description:text:nullable=YES:default=
status:text:nullable=NO:default='active'::text
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
deleted_at:timestamp with time zone:nullable=YES:default=
created_by:text:nullable=YES:default=
updated_by:text:nullable=YES:default=

### public.erp_account_movements

account_movement_id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:text:nullable=NO:default=
journal_entry_id:uuid:nullable=NO:default=
journal_line_id:uuid:nullable=NO:default=
movement_date:date:nullable=NO:default=CURRENT_DATE
posting_date:date:nullable=NO:default=CURRENT_DATE
fiscal_year:integer:nullable=NO:default=
fiscal_period:text:nullable=NO:default=
account_code:text:nullable=NO:default=
account_name:text:nullable=YES:default=
description:text:nullable=YES:default=
debit_amount:numeric:nullable=NO:default=0
credit_amount:numeric:nullable=NO:default=0
currency_code:text:nullable=NO:default='TRY'::text
exchange_rate:numeric:nullable=NO:default=1
local_debit_amount:numeric:nullable=NO:default=0
local_credit_amount:numeric:nullable=NO:default=0
direction:text:nullable=NO:default=
source_module:text:nullable=NO:default='manual'::text
source_document_type:text:nullable=YES:default=
source_document_id:uuid:nullable=YES:default=
party_id:uuid:nullable=YES:default=
customer_id:uuid:nullable=YES:default=
vendor_id:uuid:nullable=YES:default=
item_id:uuid:nullable=YES:default=
cost_center_code:text:nullable=YES:default=
project_code:text:nullable=YES:default=
status:text:nullable=NO:default='posted'::text
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
deleted_at:timestamp with time zone:nullable=YES:default=
created_by:text:nullable=YES:default=
updated_by:text:nullable=YES:default=

### public.erp_bank_accounts

bank_account_id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:text:nullable=NO:default=
bank_code:text:nullable=NO:default=
bank_name:text:nullable=NO:default=
branch_code:text:nullable=YES:default=
branch_name:text:nullable=YES:default=
iban:text:nullable=YES:default=
account_no:text:nullable=YES:default=
account_code:text:nullable=YES:default=
account_name:text:nullable=YES:default=
currency_code:text:nullable=NO:default='TRY'::text
opening_balance:numeric:nullable=NO:default=0
current_balance:numeric:nullable=NO:default=0
is_active:boolean:nullable=NO:default=true
description:text:nullable=YES:default=
status:text:nullable=NO:default='active'::text
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
deleted_at:timestamp with time zone:nullable=YES:default=
created_by:text:nullable=YES:default=
updated_by:text:nullable=YES:default=

### public.erp_cash_accounts

cash_account_id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:text:nullable=NO:default=
cash_code:text:nullable=NO:default=
cash_name:text:nullable=NO:default=
account_code:text:nullable=YES:default=
account_name:text:nullable=YES:default=
currency_code:text:nullable=NO:default='TRY'::text
opening_balance:numeric:nullable=NO:default=0
current_balance:numeric:nullable=NO:default=0
is_active:boolean:nullable=NO:default=true
description:text:nullable=YES:default=
status:text:nullable=NO:default='active'::text
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
deleted_at:timestamp with time zone:nullable=YES:default=
created_by:text:nullable=YES:default=
updated_by:text:nullable=YES:default=

### public.erp_chart_accounts

chart_account_id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:text:nullable=NO:default=
account_code:text:nullable=NO:default=
account_name:text:nullable=NO:default=
parent_account_code:text:nullable=YES:default=
account_level:integer:nullable=NO:default=1
account_class:text:nullable=YES:default=
account_group:text:nullable=YES:default=
account_type:text:nullable=NO:default=
normal_balance:text:nullable=NO:default=
is_postable:boolean:nullable=NO:default=true
is_active:boolean:nullable=NO:default=true
currency_code:text:nullable=NO:default='TRY'::text
tax_code:text:nullable=YES:default=
vat_rate:numeric:nullable=YES:default=
description:text:nullable=YES:default=
status:text:nullable=NO:default='active'::text
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()
deleted_at:timestamp with time zone:nullable=YES:default=
created_by:text:nullable=YES:default=
updated_by:text:nullable=YES:default=

### public.read_user_projection

user_id:text:nullable=NO:default=
username:text:nullable=NO:default=
created_at:timestamp with time zone:nullable=NO:default=now()

### public.read_users

id:integer:nullable=NO:default=
total_count:bigint:nullable=NO:default=0

### public.users

id:bigint:nullable=NO:default=nextval('users_id_seq'::regclass)
tenant_id:bigint:nullable=NO:default=
email:text:nullable=NO:default=
password_hash:text:nullable=YES:default=
role:text:nullable=NO:default='user'::text
permissions:jsonb:nullable=NO:default='[]'::jsonb
scopes:jsonb:nullable=NO:default='[]'::jsonb
created_at:timestamp with time zone:nullable=NO:default=now()


---

## 5. Role tablo adaylari

ROLE_TABLE_COUNT=6

auth.permissions
auth.role_permissions
auth.roles
auth.user_role_assignments
public.role_permissions
public.roles

---

## 6. Role tablo detaylari

### auth.permissions

id:uuid:nullable=NO:default=gen_random_uuid()
permission_code:text:nullable=NO:default=
module_code:text:nullable=NO:default=
action_code:text:nullable=NO:default=
description:text:nullable=NO:default=
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()

### auth.role_permissions

role_id:uuid:nullable=NO:default=
permission_id:uuid:nullable=NO:default=
created_at:timestamp with time zone:nullable=NO:default=now()

### auth.roles

id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
role_code:text:nullable=NO:default=
role_name:text:nullable=NO:default=
is_system:boolean:nullable=NO:default=false
created_at:timestamp with time zone:nullable=NO:default=now()
updated_at:timestamp with time zone:nullable=NO:default=now()

### auth.user_role_assignments

id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
user_id:uuid:nullable=NO:default=
role_id:uuid:nullable=NO:default=
legal_entity_id:uuid:nullable=YES:default=
branch_id:uuid:nullable=YES:default=
created_at:timestamp with time zone:nullable=NO:default=now()

### public.role_permissions

role_id:bigint:nullable=NO:default=
permission:text:nullable=NO:default=

### public.roles

id:bigint:nullable=NO:default=nextval('roles_id_seq'::regclass)
tenant_id:bigint:nullable=NO:default=
name:text:nullable=NO:default=


---

## 7. Mapping tablo adaylari

MAPPING_TABLE_COUNT=1

auth.user_role_assignments

---

## 8. Mapping tablo detaylari

### auth.user_role_assignments

id:uuid:nullable=NO:default=gen_random_uuid()
tenant_id:uuid:nullable=NO:default=
user_id:uuid:nullable=NO:default=
role_id:uuid:nullable=NO:default=
legal_entity_id:uuid:nullable=YES:default=
branch_id:uuid:nullable=YES:default=
created_at:timestamp with time zone:nullable=NO:default=now()


---

## 9. Existing user / role kontrolu

EXISTING_USER_COUNT=0
EXISTING_USER_MATCHES:


EXISTING_ROLE_COUNT=0
EXISTING_ROLE_MATCHES:


---

## 10. Status

4C_4B_DB_PRECHECK_STATUS=PASS
4C_4B_DB_CONNECT_STATUS=PASS
4C_4B_TENANT_COUNT=1
4C_4B_TENANT_SCHEMA_COUNT=1
4C_4B_USER_TABLE_COUNT=11
4C_4B_ROLE_TABLE_COUNT=6
4C_4B_MAPPING_TABLE_COUNT=1
4C_4B_EXISTING_USER_COUNT=0
4C_4B_EXISTING_ROLE_COUNT=0
4C_4B_DB_WRITE_APPLIED=NO
4C_4B_CRITICAL_BLOCKER_COUNT=0
4C_4B_WARNING_COUNT=0
4C_4C_READY=YES
