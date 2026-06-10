-- FAZ 1-2.5 Role / Permission canonical model
-- Purpose: tenant-safe RBAC runtime foundation.

BEGIN;

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS app_security;

CREATE OR REPLACE FUNCTION auth.security_generated_id(p_prefix text)
RETURNS text
LANGUAGE sql
VOLATILE
AS $$
  SELECT p_prefix || '_' || md5(random()::text || clock_timestamp()::text || txid_current()::text);
$$;

CREATE TABLE IF NOT EXISTS auth.roles (
  tenant_id text,
  role_id text,
  role_key text,
  role_name text,
  description text,
  is_system boolean DEFAULT false,
  status text DEFAULT 'ACTIVE',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.permissions (
  tenant_id text,
  permission_id text,
  permission_key text,
  permission_name text,
  description text,
  module_key text,
  action_key text,
  is_system boolean DEFAULT true,
  status text DEFAULT 'ACTIVE',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.role_permissions (
  tenant_id text,
  role_permission_id text,
  role_id text,
  permission_id text,
  status text DEFAULT 'ACTIVE',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.user_roles (
  tenant_id text,
  user_role_id text,
  user_id text,
  role_id text,
  role_key text,
  scope_type text DEFAULT 'TENANT',
  scope_value text,
  status text DEFAULT 'ACTIVE',
  granted_by text,
  granted_at timestamptz DEFAULT now(),
  revoked_at timestamptz,
  revoked_by text,
  revoke_reason text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (tenant_id, user_role_id)
);

ALTER TABLE auth.roles
  ADD COLUMN IF NOT EXISTS tenant_id text,
  ADD COLUMN IF NOT EXISTS role_id text,
  ADD COLUMN IF NOT EXISTS role_key text,
  ADD COLUMN IF NOT EXISTS role_name text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS is_system boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE auth.permissions
  ADD COLUMN IF NOT EXISTS tenant_id text,
  ADD COLUMN IF NOT EXISTS permission_id text,
  ADD COLUMN IF NOT EXISTS permission_key text,
  ADD COLUMN IF NOT EXISTS permission_name text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS module_key text,
  ADD COLUMN IF NOT EXISTS action_key text,
  ADD COLUMN IF NOT EXISTS is_system boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE auth.role_permissions
  ADD COLUMN IF NOT EXISTS tenant_id text,
  ADD COLUMN IF NOT EXISTS role_permission_id text,
  ADD COLUMN IF NOT EXISTS role_id text,
  ADD COLUMN IF NOT EXISTS permission_id text,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE auth.user_roles
  ADD COLUMN IF NOT EXISTS tenant_id text,
  ADD COLUMN IF NOT EXISTS user_role_id text,
  ADD COLUMN IF NOT EXISTS user_id text,
  ADD COLUMN IF NOT EXISTS role_id text,
  ADD COLUMN IF NOT EXISTS role_key text,
  ADD COLUMN IF NOT EXISTS scope_type text DEFAULT 'TENANT',
  ADD COLUMN IF NOT EXISTS scope_value text,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS granted_by text,
  ADD COLUMN IF NOT EXISTS granted_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_by text,
  ADD COLUMN IF NOT EXISTS revoke_reason text,
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

CREATE OR REPLACE FUNCTION auth.rbac_column_exists(
  p_table_name text,
  p_column_name text
)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name = p_table_name
      AND column_name = p_column_name
  );
$$;

CREATE OR REPLACE FUNCTION auth.rbac_sql_value(
  p_table_name text,
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
  v_value text;
BEGIN
  v_value := nullif(btrim(coalesce(p_value, '')), '');

  IF v_value IS NULL THEN
    RETURN 'NULL';
  END IF;

  SELECT c.udt_name, c.udt_schema, c.data_type
  INTO v_udt_name, v_udt_schema, v_data_type
  FROM information_schema.columns c
  WHERE c.table_schema = 'auth'
    AND c.table_name = p_table_name
    AND c.column_name = p_column_name
  LIMIT 1;

  IF v_udt_name IS NULL THEN
    RETURN quote_literal(v_value);
  END IF;

  IF v_udt_name = 'uuid' THEN
    RETURN format('%L::uuid', v_value);
  END IF;

  IF v_udt_name = 'bool' THEN
    IF upper(v_value) IN ('TRUE','T','1','YES') THEN
      RETURN 'true';
    END IF;
    RETURN 'false';
  END IF;

  IF v_udt_name = 'jsonb' THEN
    RETURN quote_literal(v_value)::text || '::jsonb';
  END IF;

  IF v_udt_name = 'json' THEN
    RETURN quote_literal(v_value)::text || '::json';
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
      AND upper(e.enumlabel) = upper(v_value)
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

    RETURN format('%L::%I.%I', v_enum_label, v_udt_schema, v_udt_name);
  END IF;

  RETURN quote_literal(v_value);
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_generated_sql_value(
  p_table_name text,
  p_column_name text,
  p_prefix text
)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_udt_name text;
BEGIN
  SELECT c.udt_name
  INTO v_udt_name
  FROM information_schema.columns c
  WHERE c.table_schema = 'auth'
    AND c.table_name = p_table_name
    AND c.column_name = p_column_name
  LIMIT 1;

  IF v_udt_name = 'uuid' THEN
    RETURN 'md5(random()::text || clock_timestamp()::text)::uuid';
  END IF;

  RETURN quote_literal(p_prefix) || ' || ' || quote_literal('_') || ' || md5(random()::text || clock_timestamp()::text)';
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_status_is_active(p_status text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT upper(coalesce(nullif(btrim(p_status), ''), 'ACTIVE')) NOT IN ('REVOKED','DISABLED','INACTIVE','DELETED','ARCHIVED');
$$;

DO $$
BEGIN
  IF auth.rbac_column_exists('roles', 'role_id') THEN
    EXECUTE
      'UPDATE auth.roles SET role_id = ' ||
      auth.rbac_generated_sql_value('roles', 'role_id', 'role') ||
      ' WHERE role_id IS NULL OR role_id::text = ''''';
  END IF;

  IF auth.rbac_column_exists('roles', 'role_key') THEN
    UPDATE auth.roles
    SET role_key = coalesce(nullif(role_key::text, ''), 'SYSTEM_ADMIN')
    WHERE role_key IS NULL OR role_key::text = '';
  END IF;

  IF auth.rbac_column_exists('roles', 'role_name') THEN
    UPDATE auth.roles
    SET role_name = coalesce(nullif(role_name::text, ''), 'System Admin')
    WHERE role_name IS NULL OR role_name::text = '';
  END IF;

  IF auth.rbac_column_exists('permissions', 'permission_id') THEN
    EXECUTE
      'UPDATE auth.permissions SET permission_id = ' ||
      auth.rbac_generated_sql_value('permissions', 'permission_id', 'perm') ||
      ' WHERE permission_id IS NULL OR permission_id::text = ''''';
  END IF;

  IF auth.rbac_column_exists('permissions', 'permission_key') THEN
    UPDATE auth.permissions
    SET permission_key = coalesce(nullif(permission_key::text, ''), 'SYSTEM_READ')
    WHERE permission_key IS NULL OR permission_key::text = '';
  END IF;

  IF auth.rbac_column_exists('permissions', 'permission_name') THEN
    UPDATE auth.permissions
    SET permission_name = coalesce(nullif(permission_name::text, ''), 'System Read')
    WHERE permission_name IS NULL OR permission_name::text = '';
  END IF;

  IF auth.rbac_column_exists('role_permissions', 'role_permission_id') THEN
    EXECUTE
      'UPDATE auth.role_permissions SET role_permission_id = ' ||
      auth.rbac_generated_sql_value('role_permissions', 'role_permission_id', 'rperm') ||
      ' WHERE role_permission_id IS NULL OR role_permission_id::text = ''''';
  END IF;

  IF auth.rbac_column_exists('user_roles', 'user_role_id') THEN
    EXECUTE
      'UPDATE auth.user_roles SET user_role_id = ' ||
      auth.rbac_generated_sql_value('user_roles', 'user_role_id', 'urole') ||
      ' WHERE user_role_id IS NULL OR user_role_id::text = ''''';
  END IF;
END $$;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name IN ('roles','permissions','role_permissions','user_roles')
      AND column_name = 'tenant_id'
    GROUP BY table_schema, table_name
  LOOP
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', r.table_schema, r.table_name);
    EXECUTE format('ALTER TABLE %I.%I FORCE ROW LEVEL SECURITY', r.table_schema, r.table_name);

    EXECUTE format('DROP POLICY IF EXISTS pix2pi_tenant_isolation_allow ON %I.%I', r.table_schema, r.table_name);
    EXECUTE format('DROP POLICY IF EXISTS pix2pi_tenant_isolation_enforce ON %I.%I', r.table_schema, r.table_name);

    EXECUTE format(
      'CREATE POLICY pix2pi_tenant_isolation_allow ON %I.%I AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id::text = app_security.current_tenant_id_text() OR tenant_id IS NULL) WITH CHECK (tenant_id::text = app_security.current_tenant_id_text() OR tenant_id IS NULL)',
      r.table_schema,
      r.table_name
    );

    EXECUTE format(
      'CREATE POLICY pix2pi_tenant_isolation_enforce ON %I.%I AS RESTRICTIVE FOR ALL TO PUBLIC USING (tenant_id::text = app_security.current_tenant_id_text() OR tenant_id IS NULL) WITH CHECK (tenant_id::text = app_security.current_tenant_id_text() OR tenant_id IS NULL)',
      r.table_schema,
      r.table_name
    );
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION auth.rbac_link_role_permission(
  p_role_key text,
  p_permission_key text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_role_id text;
  v_permission_id text;
  v_role_permission_id text;
  v_columns text;
  v_values text;
  v_exists boolean;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for role permission link'
      USING ERRCODE = '22023';
  END IF;

  SELECT r.role_id::text
  INTO v_role_id
  FROM auth.roles r
  WHERE r.role_key::text = p_role_key
    AND (r.tenant_id::text = v_tenant_id OR r.tenant_id IS NULL)
    AND auth.rbac_status_is_active(r.status::text)
  LIMIT 1;

  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'role not found: %', p_role_key
      USING ERRCODE = '22023';
  END IF;

  SELECT p.permission_id::text
  INTO v_permission_id
  FROM auth.permissions p
  WHERE p.permission_key::text = p_permission_key
    AND (p.tenant_id::text = v_tenant_id OR p.tenant_id IS NULL)
    AND auth.rbac_status_is_active(p.status::text)
  LIMIT 1;

  IF v_permission_id IS NULL THEN
    RAISE EXCEPTION 'permission not found: %', p_permission_key
      USING ERRCODE = '22023';
  END IF;

  SELECT exists (
    SELECT 1
    FROM auth.role_permissions rp
    WHERE rp.role_id::text = v_role_id
      AND rp.permission_id::text = v_permission_id
      AND (rp.tenant_id::text = v_tenant_id OR rp.tenant_id IS NULL)
      AND auth.rbac_status_is_active(rp.status::text)
  )
  INTO v_exists;

  IF v_exists THEN
    SELECT rp.role_permission_id::text
    INTO v_role_permission_id
    FROM auth.role_permissions rp
    WHERE rp.role_id::text = v_role_id
      AND rp.permission_id::text = v_permission_id
      AND (rp.tenant_id::text = v_tenant_id OR rp.tenant_id IS NULL)
      AND auth.rbac_status_is_active(rp.status::text)
    LIMIT 1;

    RETURN v_role_permission_id;
  END IF;

  v_columns := 'tenant_id, role_permission_id, role_id, permission_id, status, metadata, created_at, updated_at';
  v_values :=
    auth.rbac_sql_value('role_permissions','tenant_id',v_tenant_id) || ', ' ||
    auth.rbac_generated_sql_value('role_permissions','role_permission_id','rperm') || ', ' ||
    auth.rbac_sql_value('role_permissions','role_id',v_role_id) || ', ' ||
    auth.rbac_sql_value('role_permissions','permission_id',v_permission_id) || ', ' ||
    auth.rbac_sql_value('role_permissions','status','ACTIVE') || ', ' ||
    quote_literal('{}') || '::jsonb, now(), now()';

  EXECUTE 'INSERT INTO auth.role_permissions (' || v_columns || ') VALUES (' || v_values || ') RETURNING role_permission_id::text'
  INTO v_role_permission_id;

  RETURN v_role_permission_id;
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_grant_role_to_user(
  p_user_id text,
  p_role_key text,
  p_scope_type text DEFAULT 'TENANT',
  p_scope_value text DEFAULT NULL,
  p_granted_by text DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_role_id text;
  v_user_role_id text;
  v_scope_value text;
  v_columns text;
  v_values text;
  v_exists boolean;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for user role grant'
      USING ERRCODE = '22023';
  END IF;

  IF p_user_id IS NULL OR btrim(p_user_id) = '' THEN
    RAISE EXCEPTION 'user_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_role_key IS NULL OR btrim(p_role_key) = '' THEN
    RAISE EXCEPTION 'role_key is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_scope_type NOT IN ('TENANT','LEGAL_ENTITY','BRANCH','ACCOUNTANT_ASSIGNED_COMPANY') THEN
    RAISE EXCEPTION 'invalid scope_type: %', p_scope_type
      USING ERRCODE = '22023';
  END IF;

  v_scope_value := coalesce(nullif(btrim(coalesce(p_scope_value, '')), ''), v_tenant_id);

  SELECT r.role_id::text
  INTO v_role_id
  FROM auth.roles r
  WHERE r.role_key::text = p_role_key
    AND (r.tenant_id::text = v_tenant_id OR r.tenant_id IS NULL)
    AND auth.rbac_status_is_active(r.status::text)
  LIMIT 1;

  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'role not found: %', p_role_key
      USING ERRCODE = '22023';
  END IF;

  SELECT exists (
    SELECT 1
    FROM auth.user_roles ur
    WHERE ur.tenant_id::text = v_tenant_id
      AND ur.user_id::text = p_user_id
      AND ur.role_key::text = p_role_key
      AND ur.scope_type::text = p_scope_type
      AND ur.scope_value::text = v_scope_value
      AND auth.rbac_status_is_active(ur.status::text)
      AND ur.revoked_at IS NULL
  )
  INTO v_exists;

  IF v_exists THEN
    SELECT ur.user_role_id::text
    INTO v_user_role_id
    FROM auth.user_roles ur
    WHERE ur.tenant_id::text = v_tenant_id
      AND ur.user_id::text = p_user_id
      AND ur.role_key::text = p_role_key
      AND ur.scope_type::text = p_scope_type
      AND ur.scope_value::text = v_scope_value
      AND auth.rbac_status_is_active(ur.status::text)
      AND ur.revoked_at IS NULL
    LIMIT 1;

    RETURN v_user_role_id;
  END IF;

  v_columns := 'tenant_id, user_role_id, user_id, role_id, role_key, scope_type, scope_value, status, granted_by, granted_at, metadata, created_at, updated_at';

  v_values :=
    auth.rbac_sql_value('user_roles','tenant_id',v_tenant_id) || ', ' ||
    auth.rbac_generated_sql_value('user_roles','user_role_id','urole') || ', ' ||
    auth.rbac_sql_value('user_roles','user_id',p_user_id) || ', ' ||
    auth.rbac_sql_value('user_roles','role_id',v_role_id) || ', ' ||
    auth.rbac_sql_value('user_roles','role_key',p_role_key) || ', ' ||
    auth.rbac_sql_value('user_roles','scope_type',p_scope_type) || ', ' ||
    auth.rbac_sql_value('user_roles','scope_value',v_scope_value) || ', ' ||
    auth.rbac_sql_value('user_roles','status','ACTIVE') || ', ' ||
    auth.rbac_sql_value('user_roles','granted_by',p_granted_by) || ', now(), $1, now(), now()';

  EXECUTE 'INSERT INTO auth.user_roles (' || v_columns || ') VALUES (' || v_values || ') RETURNING user_role_id::text'
  INTO v_user_role_id
  USING coalesce(p_metadata, '{}'::jsonb);

  RETURN v_user_role_id;
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_revoke_user_role(
  p_user_role_id text,
  p_revoked_by text,
  p_revoke_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for user role revoke'
      USING ERRCODE = '22023';
  END IF;

  IF p_user_role_id IS NULL OR btrim(p_user_role_id) = '' THEN
    RAISE EXCEPTION 'user_role_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_revoke_reason IS NULL OR length(btrim(p_revoke_reason)) < 10 THEN
    RAISE EXCEPTION 'revoke reason must be at least 10 characters'
      USING ERRCODE = '22023';
  END IF;

  UPDATE auth.user_roles
  SET
    status = 'REVOKED',
    revoked_at = now(),
    revoked_by = nullif(btrim(coalesce(p_revoked_by, '')), ''),
    revoke_reason = btrim(p_revoke_reason),
    updated_at = now()
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = p_user_role_id
    AND revoked_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'active user role not found for revoke'
      USING ERRCODE = '42501';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_user_has_role(
  p_user_id text,
  p_role_key text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_exists boolean;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT exists (
    SELECT 1
    FROM auth.user_roles ur
    WHERE ur.tenant_id::text = v_tenant_id
      AND ur.user_id::text = p_user_id
      AND ur.role_key::text = p_role_key
      AND auth.rbac_status_is_active(ur.status::text)
      AND ur.revoked_at IS NULL
  )
  INTO v_exists;

  RETURN coalesce(v_exists, false);
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_user_has_permission(
  p_user_id text,
  p_permission_key text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_exists boolean;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT exists (
    SELECT 1
    FROM auth.user_roles ur
    JOIN auth.role_permissions rp
      ON rp.role_id::text = ur.role_id::text
     AND (rp.tenant_id::text = v_tenant_id OR rp.tenant_id IS NULL)
     AND auth.rbac_status_is_active(rp.status::text)
    JOIN auth.permissions p
      ON p.permission_id::text = rp.permission_id::text
     AND (p.tenant_id::text = v_tenant_id OR p.tenant_id IS NULL)
     AND p.permission_key::text = p_permission_key
     AND auth.rbac_status_is_active(p.status::text)
    WHERE ur.tenant_id::text = v_tenant_id
      AND ur.user_id::text = p_user_id
      AND auth.rbac_status_is_active(ur.status::text)
      AND ur.revoked_at IS NULL
  )
  INTO v_exists;

  RETURN coalesce(v_exists, false);
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_assert_permission(
  p_user_id text,
  p_permission_key text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
BEGIN
  IF NOT auth.rbac_user_has_permission(p_user_id, p_permission_key) THEN
    RAISE EXCEPTION 'required permission missing: user=%, permission=%',
      p_user_id,
      p_permission_key
      USING ERRCODE = '42501';
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_role_permission_verify_role') THEN
    CREATE ROLE pix2pi_role_permission_verify_role;
  END IF;
END $$;

GRANT USAGE ON SCHEMA auth TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.roles TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.permissions TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.role_permissions TO pix2pi_role_permission_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_roles TO pix2pi_role_permission_verify_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO pix2pi_role_permission_verify_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name='app_security') THEN
    GRANT USAGE ON SCHEMA app_security TO pix2pi_role_permission_verify_role;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_security TO pix2pi_role_permission_verify_role;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name='security') THEN
    GRANT USAGE ON SCHEMA security TO pix2pi_role_permission_verify_role;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA security TO pix2pi_role_permission_verify_role;
  END IF;
END $$;

COMMIT;
