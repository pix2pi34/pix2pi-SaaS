-- FAZ 4C — 4C-4F User / Role Commit SQL Package
-- Purpose: uzmanparcaci pilot admin user and role assignment
-- IMPORTANT:
--   This SQL file is a COMMIT package.
--   4C-4F only creates this file.
--   4C-4F does NOT execute it.
--   Execution must happen only in 4C-4G.
--
-- Generated at: 2026-05-01 07:49:36
-- Tenant ID: 6dfe8d22-035a-401f-807c-507408d2e439
-- Tenant business_code: UZMANPARCACI
-- Pilot user: uzmanparcaci1@gmail.com
-- Pilot role: PILOT_ADMIN

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='users'
  ) THEN
    RAISE EXCEPTION 'Required table auth.users does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='roles'
  ) THEN
    RAISE EXCEPTION 'Required table auth.roles does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='user_role_assignments'
  ) THEN
    RAISE EXCEPTION 'Required table auth.user_role_assignments does not exist';
  END IF;
END
$$;

DO $$
DECLARE
  tenant_count integer;
BEGIN
  SELECT count(*) INTO tenant_count
  FROM platform.tenants
  WHERE id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND (
      slug='uzmanparcaci'
      OR business_code='UZMANPARCACI'::core.code_text
    );

  IF tenant_count <> 1 THEN
    RAISE EXCEPTION 'Tenant verification failed. tenant_count=%', tenant_count;
  END IF;
END
$$;

WITH inserted_user AS (
  INSERT INTO auth.users (tenant_id,email,full_name,password_hash,is_active,created_at,updated_at)
  SELECT '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,'uzmanparcaci1@gmail.com','mert_omur','PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED',true,now(),now()
  WHERE NOT EXISTS (
    SELECT 1
    FROM auth.users
    WHERE lower(email::text)=lower('uzmanparcaci1@gmail.com')
  )
  RETURNING id AS user_id
),
selected_user AS (
  SELECT user_id FROM inserted_user
  UNION ALL
  SELECT id AS user_id
  FROM auth.users
  WHERE lower(email::text)=lower('uzmanparcaci1@gmail.com')
  LIMIT 1
),
inserted_role AS (
  INSERT INTO auth.roles (tenant_id,role_code,role_name,created_at,updated_at)
  SELECT '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,'PILOT_ADMIN','Pilot Admin',now(),now()
  WHERE NOT EXISTS (
    SELECT 1
    FROM auth.roles
    WHERE upper(role_code::text)=upper('PILOT_ADMIN')
  )
  RETURNING id AS role_id
),
selected_role AS (
  SELECT role_id FROM inserted_role
  UNION ALL
  SELECT id AS role_id
  FROM auth.roles
  WHERE upper(role_code::text)=upper('PILOT_ADMIN')
  LIMIT 1
),
inserted_assignment AS (
  INSERT INTO auth.user_role_assignments (tenant_id,user_id,role_id,created_at)
  SELECT '6dfe8d22-035a-401f-807c-507408d2e439'::uuid,u.user_id,r.role_id,now()
  FROM selected_user u
  CROSS JOIN selected_role r
  WHERE NOT EXISTS (
    SELECT 1
    FROM auth.user_role_assignments a
    WHERE a.user_id = u.user_id
      AND a.role_id = r.role_id
  )
  RETURNING user_id, role_id
)
SELECT
  'preview_user_count' AS check_name,
  count(*)::text AS check_value
FROM auth.users
WHERE lower(email::text)=lower('uzmanparcaci1@gmail.com');

SELECT
  'preview_role_count' AS check_name,
  count(*)::text AS check_value
FROM auth.roles
WHERE upper(role_code::text)=upper('PILOT_ADMIN');

DO $$
DECLARE
  final_user_count integer;
  final_role_count integer;
  final_assignment_count integer;
BEGIN
  SELECT count(*) INTO final_user_count
  FROM auth.users
  WHERE lower(email::text)=lower('uzmanparcaci1@gmail.com');

  SELECT count(*) INTO final_role_count
  FROM auth.roles
  WHERE upper(role_code::text)=upper('PILOT_ADMIN');

  SELECT count(*) INTO final_assignment_count
  FROM auth.user_role_assignments a
  JOIN auth.users u ON u.id = a.user_id
  JOIN auth.roles r ON r.id = a.role_id
  WHERE lower(u.email::text)=lower('uzmanparcaci1@gmail.com')
    AND upper(r.role_code::text)=upper('PILOT_ADMIN');

  IF final_user_count <> 1 THEN
    RAISE EXCEPTION 'User verification failed. final_user_count=%', final_user_count;
  END IF;

  IF final_role_count <> 1 THEN
    RAISE EXCEPTION 'Role verification failed. final_role_count=%', final_role_count;
  END IF;

  IF final_assignment_count <> 1 THEN
    RAISE EXCEPTION 'Assignment verification failed. final_assignment_count=%', final_assignment_count;
  END IF;
END
$$;

COMMIT;

-- Note:
-- This commit package must be executed only by 4C-4G guarded apply step.
