-- FAZ 1-2.4 FIX V9C
-- Purpose: legacy auth.user_scopes RLS policy calls security.* functions.
-- Grant minimum schema/function privileges to pix2pi_user_scope_verify_role.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_user_scope_verify_role') THEN
    CREATE ROLE pix2pi_user_scope_verify_role;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'security') THEN
    GRANT USAGE ON SCHEMA security TO pix2pi_user_scope_verify_role;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA security TO pix2pi_user_scope_verify_role;
  ELSE
    RAISE NOTICE 'security schema not found; skipping security schema grants';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'app_security') THEN
    GRANT USAGE ON SCHEMA app_security TO pix2pi_user_scope_verify_role;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_security TO pix2pi_user_scope_verify_role;
  END IF;
END $$;

GRANT USAGE ON SCHEMA auth TO pix2pi_user_scope_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_scopes TO pix2pi_user_scope_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_scope_audit TO pix2pi_user_scope_verify_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO pix2pi_user_scope_verify_role;

COMMIT;
