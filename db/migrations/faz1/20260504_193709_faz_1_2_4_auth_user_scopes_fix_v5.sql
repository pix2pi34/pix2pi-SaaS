-- FAZ 1-2.4 auth.user_scopes FIX V5
-- Fix: legacy enum column scope_level compatibility.

BEGIN;

CREATE SCHEMA IF NOT EXISTS auth;

CREATE OR REPLACE FUNCTION auth.user_scope_column_exists(p_column_name text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name = 'user_scopes'
      AND column_name = p_column_name
  );
$$;

CREATE OR REPLACE FUNCTION auth.user_scope_sql_value(
  p_column_name text,
  p_value text
)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_udt_name text;
  v_udt_schema text;
  v_data_type text;
  v_typtype text;
  v_enum_label text;
BEGIN
  IF p_value IS NULL OR btrim(p_value) = '' THEN
    RETURN 'NULL';
  END IF;

  SELECT
    c.udt_name,
    c.udt_schema,
    c.data_type
  INTO
    v_udt_name,
    v_udt_schema,
    v_data_type
  FROM information_schema.columns c
  WHERE c.table_schema = 'auth'
    AND c.table_name = 'user_scopes'
    AND c.column_name = p_column_name
  LIMIT 1;

  IF v_udt_name IS NULL THEN
    RETURN format('%L', p_value);
  END IF;

  IF v_udt_name = 'uuid' THEN
    RETURN format('%L::uuid', p_value);
  END IF;

  SELECT t.typtype
  INTO v_typtype
  FROM pg_type t
  JOIN pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = v_udt_schema
    AND t.typname = v_udt_name
  LIMIT 1;

  IF v_typtype = 'e' THEN
    SELECT e.enumlabel
    INTO v_enum_label
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = v_udt_schema
      AND t.typname = v_udt_name
      AND upper(e.enumlabel) = upper(p_value)
    ORDER BY e.enumsortorder
    LIMIT 1;

    IF v_enum_label IS NULL THEN
      SELECT e.enumlabel
      INTO v_enum_label
      FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      JOIN pg_namespace n ON n.oid = t.typnamespace
      WHERE n.nspname = v_udt_schema
        AND t.typname = v_udt_name
      ORDER BY e.enumsortorder
      LIMIT 1;
    END IF;

    IF v_enum_label IS NULL THEN
      RAISE EXCEPTION 'enum label not found for %.%', v_udt_schema, v_udt_name;
    END IF;

    RETURN format('%L::%I.%I', v_enum_label, v_udt_schema, v_udt_name);
  END IF;

  RETURN format('%L', p_value);
END;
$$;

DO $$
DECLARE
  v_scope_level_expr text;
BEGIN
  IF auth.user_scope_column_exists('scope_level') THEN
    v_scope_level_expr := auth.user_scope_sql_value('scope_level', 'TENANT');

    EXECUTE
      'UPDATE auth.user_scopes
       SET scope_level = ' || v_scope_level_expr || '
       WHERE scope_level IS NULL';

    BEGIN
      EXECUTE
        'ALTER TABLE auth.user_scopes
         ALTER COLUMN scope_level SET DEFAULT ' || v_scope_level_expr;
    EXCEPTION
      WHEN others THEN
        NULL;
    END;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION auth.grant_user_scope(
  p_user_id text,
  p_scope_type text,
  p_scope_value text,
  p_legal_entity_id text DEFAULT NULL,
  p_branch_id text DEFAULT NULL,
  p_accountant_company_id text DEFAULT NULL,
  p_granted_by text DEFAULT NULL,
  p_expires_at timestamptz DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_scope_id text;
  v_scope_value text;
  v_columns text;
  v_values text;
  v_sql text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for user scope grant'
      USING ERRCODE = '22023';
  END IF;

  IF p_user_id IS NULL OR btrim(p_user_id) = '' THEN
    RAISE EXCEPTION 'user_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_scope_type NOT IN ('TENANT', 'LEGAL_ENTITY', 'BRANCH', 'ACCOUNTANT_ASSIGNED_COMPANY') THEN
    RAISE EXCEPTION 'invalid scope_type: %', p_scope_type
      USING ERRCODE = '22023';
  END IF;

  v_scope_value := auth.user_scope_normalized_value(
    p_scope_type,
    p_scope_value,
    p_legal_entity_id,
    p_branch_id,
    p_accountant_company_id
  );

  IF v_scope_value IS NULL OR btrim(v_scope_value) = '' THEN
    RAISE EXCEPTION 'scope value is required for scope_type %', p_scope_type
      USING ERRCODE = '22023';
  END IF;

  IF p_scope_type = 'TENANT' AND v_scope_value IS DISTINCT FROM v_tenant_id THEN
    RAISE EXCEPTION 'TENANT scope value must match current tenant context'
      USING ERRCODE = '42501';
  END IF;

  IF p_expires_at IS NOT NULL AND p_expires_at <= now() THEN
    RAISE EXCEPTION 'expires_at must be in the future'
      USING ERRCODE = '22023';
  END IF;

  v_scope_id := auth.security_generated_id('uscope');

  v_columns :=
    'tenant_id, scope_id, user_id, scope_type, scope_value, legal_entity_id, branch_id, accountant_company_id, status, granted_by, granted_at, expires_at, metadata, created_at, updated_at';

  v_values :=
      auth.user_scope_sql_value('tenant_id', v_tenant_id) || ', ' ||
      quote_literal(v_scope_id) || ', ' ||
      auth.user_scope_sql_value('user_id', btrim(p_user_id)) || ', ' ||
      quote_literal(p_scope_type) || ', ' ||
      quote_literal(v_scope_value) || ', ' ||
      auth.user_scope_sql_value('legal_entity_id', nullif(btrim(coalesce(p_legal_entity_id, '')), '')) || ', ' ||
      auth.user_scope_sql_value('branch_id', nullif(btrim(coalesce(p_branch_id, '')), '')) || ', ' ||
      quote_nullable(nullif(btrim(coalesce(p_accountant_company_id, '')), '')) || ', ' ||
      quote_literal('ACTIVE') || ', ' ||
      quote_nullable(nullif(btrim(coalesce(p_granted_by, '')), '')) || ', ' ||
      'now(), $1, $2, now(), now()';

  IF auth.user_scope_column_exists('scope_level') THEN
    v_columns := v_columns || ', scope_level';
    v_values := v_values || ', ' || auth.user_scope_sql_value('scope_level', p_scope_type);
  END IF;

  IF auth.user_scope_column_exists('can_read') THEN
    v_columns := v_columns || ', can_read';
    v_values := v_values || ', true';
  END IF;

  IF auth.user_scope_column_exists('can_write') THEN
    v_columns := v_columns || ', can_write';
    v_values := v_values || ', false';
  END IF;

  IF auth.user_scope_column_exists('can_admin') THEN
    v_columns := v_columns || ', can_admin';
    v_values := v_values || ', false';
  END IF;

  IF auth.user_scope_column_exists('can_manage') THEN
    v_columns := v_columns || ', can_manage';
    v_values := v_values || ', false';
  END IF;

  v_sql := 'INSERT INTO auth.user_scopes (' || v_columns || ') VALUES (' || v_values || ')';

  EXECUTE v_sql USING p_expires_at, coalesce(p_metadata, '{}'::jsonb);

  INSERT INTO auth.user_scope_audit (
    tenant_id,
    audit_id,
    scope_id,
    user_id,
    action_type,
    actor_user_id,
    reason,
    old_status,
    new_status,
    metadata
  )
  VALUES (
    v_tenant_id,
    auth.security_generated_id('uscope_audit'),
    v_scope_id,
    btrim(p_user_id),
    'GRANTED',
    nullif(btrim(coalesce(p_granted_by, '')), ''),
    'User scope granted',
    NULL,
    'ACTIVE',
    jsonb_build_object('scope_type', p_scope_type, 'scope_value', v_scope_value)
  );

  RETURN v_scope_id;
END;
$$;

GRANT EXECUTE ON FUNCTION auth.user_scope_column_exists(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.user_scope_sql_value(text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.grant_user_scope(text, text, text, text, text, text, text, timestamptz, jsonb) TO PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_user_scope_verify_role') THEN
    GRANT EXECUTE ON FUNCTION auth.user_scope_column_exists(text) TO pix2pi_user_scope_verify_role;
    GRANT EXECUTE ON FUNCTION auth.user_scope_sql_value(text, text) TO pix2pi_user_scope_verify_role;
    GRANT EXECUTE ON FUNCTION auth.grant_user_scope(text, text, text, text, text, text, text, timestamptz, jsonb) TO pix2pi_user_scope_verify_role;
  END IF;
END $$;

COMMIT;
