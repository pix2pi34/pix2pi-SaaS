# FAZ 4C — 4C-4E-FIX1 Dry Run Error Diagnosis Report

Step: 4C-4E-FIX1
Blok: Dry Run Error Diagnosis
Test tarihi: 2026-05-01 07:48:00

## Test sonucu

4C_4E_FIX1_DIAGNOSIS_STATUS=PASS
4C_4E_FIX1_DRY_RUN_STATUS=FAIL
4C_4E_FIX1_ROLLBACK_SAFE=YES
4C_4E_FIX1_BEFORE_USER_COUNT=0
4C_4E_FIX1_AFTER_USER_COUNT=0
4C_4E_FIX1_BEFORE_ROLE_COUNT=0
4C_4E_FIX1_AFTER_ROLE_COUNT=0
4C_4E_FIX1_BEFORE_ASSIGNMENT_COUNT=0
4C_4E_FIX1_AFTER_ASSIGNMENT_COUNT=0
4C_4E_FIX1_DB_WRITE_APPLIED=NO
4C_4D_FIX4_READY=YES

## SQL error
    psql:sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql:112: ERROR:  null value in column "password_hash" of relation "users" violates not-null constraint
    DETAIL:  Failing row contains (fa5753f6-be25-4f7a-a996-ec49111c211a, 6dfe8d22-035a-401f-807c-507408d2e439, uzmanparcaci1@gmail.com, mert_omur, null, t, f, null, 2026-05-01 04:47:59.526196+00, 2026-05-01 04:47:59.526196+00, null, null, 1, null).

## auth.users required no default
    tenant_id
    email
    full_name
    password_hash

## auth.roles required no default
    tenant_id
    role_code
    role_name

## auth.user_role_assignments required no default
    tenant_id
    user_id
    role_id

## Sonuc

Dry-run hatasi yakalandi.
Kalici DB yazma yapilmadi.
Bir sonraki adimda SQL mapping duzeltilecek.
