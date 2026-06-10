# FAZ 4C — 4C-4D User Role SQL Package / Dry Run Plan

## Amac

uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve user-role assignment icin SQL preview paketi uretmek.

Bu adim DB'ye yazmaz.
SQL dosyasi ROLLBACK ile biter.

---

## 1. Secilen tablolar

SELECTED_USER_TABLE=auth.users
SELECTED_ROLE_TABLE=auth.roles
SELECTED_MAPPING_TABLE=auth.user_role_assignments

---

## 2. Kolon secimleri

USER_ID_COL=id
USER_EMAIL_COL=email
ROLE_ID_COL=id
ROLE_CODE_COL=role_code
ASSIGN_USER_ID_COL=user_id
ASSIGN_ROLE_ID_COL=role_id
ASSIGN_TENANT_ID_COL=tenant_id

---

## 3. Tenant ve kullanici

TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN

---

## 4. Existing kontrol

EXISTING_USER_COUNT=0
EXISTING_ROLE_COUNT=0

---

## 5. Insert mapping

USER_COLUMN_COUNT=7
- tenant_id <= '6dfe8d22-035a-401f-807c-507408d2e439'::uuid
- email <= 'uzmanparcaci1@gmail.com'
- full_name <= 'mert_omur'
- password_hash <= 'PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED'
- is_active <= true
- created_at <= now()
- updated_at <= now()


ROLE_COLUMN_COUNT=5
- tenant_id <= '6dfe8d22-035a-401f-807c-507408d2e439'::uuid
- role_code <= 'PILOT_ADMIN'
- role_name <= 'Pilot Admin'
- created_at <= now()
- updated_at <= now()


ASSIGN_COLUMN_COUNT=4
- tenant_id <= '6dfe8d22-035a-401f-807c-507408d2e439'::uuid
- user_id <= u.user_id
- role_id <= r.role_id
- created_at <= now()


---

## 6. Zorunlu default olmayan kolonlar

USER_REQUIRED_COUNT=4
tenant_id
email
full_name
password_hash

ROLE_REQUIRED_COUNT=3
tenant_id
role_code
role_name

ASSIGN_REQUIRED_COUNT=3
tenant_id
user_id
role_id

---

## 7. SQL dosyasi

SQL_FILE=sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql

---

## 8. Status

4C_4D_SQL_PACKAGE_STATUS=PASS
4C_4D_SELECTED_USER_TABLE=auth.users
4C_4D_SELECTED_ROLE_TABLE=auth.roles
4C_4D_SELECTED_MAPPING_TABLE=auth.user_role_assignments
4C_4D_USER_ID_COL=id
4C_4D_USER_EMAIL_COL=email
4C_4D_ROLE_ID_COL=id
4C_4D_ROLE_CODE_COL=role_code
4C_4D_ASSIGN_USER_ID_COL=user_id
4C_4D_ASSIGN_ROLE_ID_COL=role_id
4C_4D_SQL_FILE_CREATED=YES
4C_4D_USER_COLUMN_COUNT=7
4C_4D_ROLE_COLUMN_COUNT=5
4C_4D_ASSIGN_COLUMN_COUNT=4
4C_4D_EXISTING_USER_COUNT=0
4C_4D_EXISTING_ROLE_COUNT=0
4C_4D_USER_REQUIRED_COLUMN_COUNT=4
4C_4D_ROLE_REQUIRED_COLUMN_COUNT=3
4C_4D_ASSIGN_REQUIRED_COLUMN_COUNT=3
4C_4D_DB_WRITE_APPLIED=NO
4C_4D_CRITICAL_BLOCKER_COUNT=0
4C_4D_WARNING_COUNT=3
4C_4E_READY=YES
