# FAZ 4C — 4C-4G User Role Apply Execution

## Amac

uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve user-role assignment kaydini DB'ye uygulamak.

Bu adim gercek DB write yapar.

---

## 1. Apply oncesi durum

TENANT_COUNT=1
BEFORE_USER_COUNT=0
BEFORE_ROLE_COUNT=0
BEFORE_ASSIGNMENT_COUNT=0

---

## 2. SQL execution

APPLY_SQL_EXECUTION_STATUS=PASS

SQL output:
    BEGIN
    DO
    DO
         check_name     | check_value 
    --------------------+-------------
     preview_user_count | 0
    (1 row)
    
         check_name     | check_value 
    --------------------+-------------
     preview_role_count | 1
    (1 row)
    
    DO
    COMMIT

SQL error:
    

---

## 3. Apply sonrasi durum

AFTER_USER_COUNT=1
AFTER_ROLE_COUNT=1
AFTER_ASSIGNMENT_COUNT=1

---

## 4. User row
    331dda2d-c44d-46e1-84c8-9549e7291e1a | 6dfe8d22-035a-401f-807c-507408d2e439 | uzmanparcaci1@gmail.com | mert_omur | true | TEMP_PASSWORD_HASH

---

## 5. Role row
    ffbce78f-3b98-46b7-9736-67b06a9f89df | 6dfe8d22-035a-401f-807c-507408d2e439 | PILOT_ADMIN | Pilot Admin

---

## 6. Assignment row
    6dfe8d22-035a-401f-807c-507408d2e439 | 331dda2d-c44d-46e1-84c8-9549e7291e1a | ffbce78f-3b98-46b7-9736-67b06a9f89df

---

## 7. Password gate

PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED
Bu kullanici canli girise acilmadan once parola reset / davet akisi zorunlu kapidir.

---

## 8. Status

4C_4G_USER_ROLE_APPLY_STATUS=PASS
4C_4G_SQL_EXECUTION_STATUS=PASS
4C_4G_TENANT_COUNT=1
4C_4G_BEFORE_USER_COUNT=0
4C_4G_AFTER_USER_COUNT=1
4C_4G_BEFORE_ROLE_COUNT=0
4C_4G_AFTER_ROLE_COUNT=1
4C_4G_BEFORE_ASSIGNMENT_COUNT=0
4C_4G_AFTER_ASSIGNMENT_COUNT=1
4C_4G_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
4C_4G_PILOT_ROLE_CODE=PILOT_ADMIN
4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED
4C_4G_DB_WRITE_APPLIED=YES
4C_4G_CRITICAL_BLOCKER_COUNT=0
4C_4G_WARNING_COUNT=1
4C_4H_READY=YES
