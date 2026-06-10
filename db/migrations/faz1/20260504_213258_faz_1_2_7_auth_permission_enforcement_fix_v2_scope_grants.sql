-- FAZ 1-2.7 FIX V2
-- Purpose:
-- Enforcement suite runs as pix2pi_role_permission_verify_role.
-- It verifies both RBAC and user scope boundaries, so it needs minimum access to auth.user_scopes.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_role_permission_verify_role') THEN
    CREATE ROLE pix2pi_role_permission_verify_role;
  END IF;
END $$;

GRANT USAGE ON SCHEMA auth TO pix2pi_role_permission_verify_role;
GRANT USAGE ON SCHEMA app_security TO pix2pi_role_permission_verify_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'security') THEN
    GRANT USAGE ON SCHEMA security TO pix2pi_role_permission_verify_role;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA security TO pix2pi_role_permission_verify_role;
  END IF;
END $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO pix2pi_role_permission_verify_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_security TO pix2pi_role_permission_verify_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.roles TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.permissions TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.role_permissions TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_roles TO pix2pi_role_permission_verify_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_scopes TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_scope_audit TO pix2pi_role_permission_verify_role;

COMMIT;
