-- FAZ 1-2.3 RLS BYPASS / CROSS-TENANT FIX V2
-- Problem:
-- pix2pi_rls_verify_role can read auth.user_scopes, but RLS policy calls security.is_super_admin()
-- and security.current_tenant_id(). Without USAGE/EXECUTE on security schema, policy evaluation fails.
-- This migration grants only verification runtime access. It does not change RLS policy logic.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='pix2pi_rls_verify_role') THEN
    CREATE ROLE pix2pi_rls_verify_role;
  END IF;
END $$;

GRANT USAGE ON SCHEMA app_security TO pix2pi_rls_verify_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_security TO pix2pi_rls_verify_role;

GRANT USAGE ON SCHEMA auth TO pix2pi_rls_verify_role;
GRANT SELECT ON auth.user_roles TO pix2pi_rls_verify_role;
GRANT SELECT ON auth.user_scopes TO pix2pi_rls_verify_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name='security') THEN
    GRANT USAGE ON SCHEMA security TO pix2pi_rls_verify_role;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA security TO pix2pi_rls_verify_role;
  END IF;
END $$;

COMMIT;
