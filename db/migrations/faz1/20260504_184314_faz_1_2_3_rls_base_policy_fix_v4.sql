-- FAZ 1-2.3 RLS Base Policy Set FIX V4
-- Generated at: 2026-05-04T18:43:15+03:00
-- APPLY=1
-- FORCE_RLS=1

BEGIN;

CREATE SCHEMA IF NOT EXISTS app_security;

CREATE OR REPLACE FUNCTION app_security.current_tenant_id_text()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '');
$$;

CREATE OR REPLACE FUNCTION app_security.has_tenant_context()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT app_security.current_tenant_id_text() IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION app_security.set_tenant_context(p_tenant_id text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_tenant_id IS NULL OR btrim(p_tenant_id) = '' THEN
    RAISE EXCEPTION 'tenant context cannot be empty'
      USING ERRCODE = '22023';
  END IF;

  PERFORM set_config('app.tenant_id', p_tenant_id, true);
END;
$$;

GRANT USAGE ON SCHEMA app_security TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_security.current_tenant_id_text() TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_security.has_tenant_context() TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_security.set_tenant_context(text) TO PUBLIC;

COMMENT ON SCHEMA app_security IS 'Pix2pi application security helpers for tenant-aware database runtime';
COMMENT ON FUNCTION app_security.current_tenant_id_text() IS 'Returns transaction-local tenant id from app.tenant_id';
COMMENT ON FUNCTION app_security.has_tenant_context() IS 'Returns whether app.tenant_id is present';
COMMENT ON FUNCTION app_security.set_tenant_context(text) IS 'Sets transaction-local tenant context for RLS-protected operations';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_rls_verify_role') THEN
    CREATE ROLE pix2pi_rls_verify_role;
  END IF;
END $$;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT
      n.nspname as schema_name,
      c.relname as table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN information_schema.columns col
      ON col.table_schema = n.nspname
     AND col.table_name = c.relname
     AND col.column_name = 'tenant_id'
    WHERE c.relkind = 'r'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND n.nspname NOT LIKE 'pg_toast%'
    GROUP BY n.nspname, c.relname
    ORDER BY n.nspname, c.relname
  LOOP
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', r.schema_name, r.table_name);

    IF '1' = '1' THEN
      EXECUTE format('ALTER TABLE %I.%I FORCE ROW LEVEL SECURITY', r.schema_name, r.table_name);
    ELSE
      EXECUTE format('ALTER TABLE %I.%I NO FORCE ROW LEVEL SECURITY', r.schema_name, r.table_name);
    END IF;

    EXECUTE format('DROP POLICY IF EXISTS pix2pi_tenant_isolation_allow ON %I.%I', r.schema_name, r.table_name);
    EXECUTE format('DROP POLICY IF EXISTS pix2pi_tenant_isolation_enforce ON %I.%I', r.schema_name, r.table_name);

    EXECUTE format(
      'CREATE POLICY pix2pi_tenant_isolation_allow ON %I.%I AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id::text = app_security.current_tenant_id_text()) WITH CHECK (tenant_id::text = app_security.current_tenant_id_text())',
      r.schema_name,
      r.table_name
    );

    EXECUTE format(
      'CREATE POLICY pix2pi_tenant_isolation_enforce ON %I.%I AS RESTRICTIVE FOR ALL TO PUBLIC USING (tenant_id::text = app_security.current_tenant_id_text()) WITH CHECK (tenant_id::text = app_security.current_tenant_id_text())',
      r.schema_name,
      r.table_name
    );
  END LOOP;
END $$;

DROP SCHEMA IF EXISTS app_security_rls_test CASCADE;
CREATE SCHEMA app_security_rls_test;

CREATE TABLE app_security_rls_test.tenant_guard_sample (
  id bigint PRIMARY KEY,
  tenant_id text NOT NULL,
  payload text NOT NULL
);

INSERT INTO app_security_rls_test.tenant_guard_sample (id, tenant_id, payload)
VALUES
  (1, 'tenant_a', 'tenant A row'),
  (2, 'tenant_b', 'tenant B row');

ALTER TABLE app_security_rls_test.tenant_guard_sample ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_security_rls_test.tenant_guard_sample FORCE ROW LEVEL SECURITY;

CREATE POLICY pix2pi_tenant_isolation_allow
ON app_security_rls_test.tenant_guard_sample
AS PERMISSIVE
FOR ALL
TO PUBLIC
USING (tenant_id::text = app_security.current_tenant_id_text())
WITH CHECK (tenant_id::text = app_security.current_tenant_id_text());

CREATE POLICY pix2pi_tenant_isolation_enforce
ON app_security_rls_test.tenant_guard_sample
AS RESTRICTIVE
FOR ALL
TO PUBLIC
USING (tenant_id::text = app_security.current_tenant_id_text())
WITH CHECK (tenant_id::text = app_security.current_tenant_id_text());

GRANT USAGE ON SCHEMA app_security_rls_test TO pix2pi_rls_verify_role;
GRANT SELECT, INSERT ON app_security_rls_test.tenant_guard_sample TO pix2pi_rls_verify_role;

SET LOCAL ROLE pix2pi_rls_verify_role;

DO $$
DECLARE
  visible_count integer;
  mismatch_visible_count integer;
BEGIN
  PERFORM app_security.set_tenant_context('tenant_a');

  SELECT count(*)
    INTO visible_count
  FROM app_security_rls_test.tenant_guard_sample;

  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'RLS tenant_a visibility failed. expected=1 actual=%', visible_count;
  END IF;

  SELECT count(*)
    INTO mismatch_visible_count
  FROM app_security_rls_test.tenant_guard_sample
  WHERE tenant_id = 'tenant_b';

  IF mismatch_visible_count <> 0 THEN
    RAISE EXCEPTION 'RLS cross tenant select failed. expected=0 actual=%', mismatch_visible_count;
  END IF;

  INSERT INTO app_security_rls_test.tenant_guard_sample (id, tenant_id, payload)
  VALUES (3, 'tenant_a', 'tenant A allowed insert');

  BEGIN
    INSERT INTO app_security_rls_test.tenant_guard_sample (id, tenant_id, payload)
    VALUES (4, 'tenant_b', 'tenant B forbidden insert');

    RAISE EXCEPTION 'RLS cross tenant insert was allowed unexpectedly';
  EXCEPTION
    WHEN insufficient_privilege OR check_violation OR with_check_option_violation THEN
      NULL;
  END;
END $$;

DO $$
DECLARE
  no_context_count integer;
BEGIN
  PERFORM set_config('app.tenant_id', '', true);

  SELECT count(*)
    INTO no_context_count
  FROM app_security_rls_test.tenant_guard_sample;

  IF no_context_count <> 0 THEN
    RAISE EXCEPTION 'RLS no tenant context visibility failed. expected=0 actual=%', no_context_count;
  END IF;
END $$;

RESET ROLE;

DROP SCHEMA IF EXISTS app_security_rls_test CASCADE;

COMMIT;
