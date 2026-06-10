BEGIN;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='pix2pi' AND rolbypassrls=true) THEN
    ALTER ROLE pix2pi NOBYPASSRLS;
  END IF;
END $$;

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
