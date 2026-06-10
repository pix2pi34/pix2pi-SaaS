BEGIN;

CREATE OR REPLACE FUNCTION auth.rbac_role_ref_value(
  p_role_key text,
  p_target_table text,
  p_target_column text
)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_target_udt text;
  v_ref_column text;
  v_ref_value text;
  v_sql text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for role reference'
      USING ERRCODE = '22023';
  END IF;

  SELECT udt_name
  INTO v_target_udt
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name=p_target_table
    AND column_name=p_target_column
  LIMIT 1;

  IF v_target_udt = 'uuid' AND auth.rbac_column_exists('roles','id') THEN
    v_ref_column := 'id';
  ELSE
    v_ref_column := 'role_id';
  END IF;

  v_sql := format(
    'SELECT %I::text
     FROM auth.roles
     WHERE role_key::text = $1
       AND (tenant_id::text = $2 OR tenant_id IS NULL)
       AND auth.rbac_status_is_active(status::text)
     LIMIT 1',
    v_ref_column
  );

  EXECUTE v_sql INTO v_ref_value USING p_role_key, v_tenant_id;

  IF v_ref_value IS NULL OR btrim(v_ref_value) = '' THEN
    RAISE EXCEPTION 'role not found or reference column empty: %', p_role_key
      USING ERRCODE = '22023';
  END IF;

  RETURN v_ref_value;
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_permission_ref_value(
  p_permission_key text,
  p_target_table text,
  p_target_column text
)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_target_udt text;
  v_ref_column text;
  v_ref_value text;
  v_sql text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for permission reference'
      USING ERRCODE = '22023';
  END IF;

  SELECT udt_name
  INTO v_target_udt
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name=p_target_table
    AND column_name=p_target_column
  LIMIT 1;

  IF v_target_udt = 'uuid' AND auth.rbac_column_exists('permissions','id') THEN
    v_ref_column := 'id';
  ELSE
    v_ref_column := 'permission_id';
  END IF;

  v_sql := format(
    'SELECT %I::text
     FROM auth.permissions
     WHERE permission_key::text = $1
       AND (tenant_id::text = $2 OR tenant_id IS NULL)
       AND auth.rbac_status_is_active(status::text)
     LIMIT 1',
    v_ref_column
  );

  EXECUTE v_sql INTO v_ref_value USING p_permission_key, v_tenant_id;

  IF v_ref_value IS NULL OR btrim(v_ref_value) = '' THEN
    RAISE EXCEPTION 'permission not found or reference column empty: %', p_permission_key
      USING ERRCODE = '22023';
  END IF;

  RETURN v_ref_value;
END;
$$;

CREATE OR REPLACE FUNCTION auth.rbac_permission_ref_matches(
  p_permission_ref text,
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
  v_sql text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RETURN false;
  END IF;

  IF auth.rbac_column_exists('permissions','id') THEN
    v_sql :=
      'SELECT EXISTS (
         SELECT 1
         FROM auth.permissions p
         WHERE (p.permission_id::text = $1 OR p.id::text = $1)
           AND p.permission_key::text = $2
           AND (p.tenant_id::text = $3 OR p.tenant_id IS NULL)
           AND auth.rbac_status_is_active(p.status::text)
       )';
  ELSE
    v_sql :=
      'SELECT EXISTS (
         SELECT 1
         FROM auth.permissions p
         WHERE p.permission_id::text = $1
           AND p.permission_key::text = $2
           AND (p.tenant_id::text = $3 OR p.tenant_id IS NULL)
           AND auth.rbac_status_is_active(p.status::text)
       )';
  END IF;

  EXECUTE v_sql INTO v_exists USING p_permission_ref, p_permission_key, v_tenant_id;

  RETURN coalesce(v_exists, false);
END;
$$;

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
  v_role_ref text;
  v_permission_ref text;
  v_role_permission_id text;
  v_columns text;
  v_values text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for role permission link'
      USING ERRCODE = '22023';
  END IF;

  IF p_role_key IS NULL OR btrim(p_role_key) = '' THEN
    RAISE EXCEPTION 'role_key is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_permission_key IS NULL OR btrim(p_permission_key) = '' THEN
    RAISE EXCEPTION 'permission_key is required'
      USING ERRCODE = '22023';
  END IF;

  v_role_ref := auth.rbac_role_ref_value(p_role_key, 'role_permissions', 'role_id');
  v_permission_ref := auth.rbac_permission_ref_value(p_permission_key, 'role_permissions', 'permission_id');

  SELECT rp.role_permission_id::text
  INTO v_role_permission_id
  FROM auth.role_permissions rp
  WHERE rp.role_id::text = v_role_ref
    AND rp.permission_id::text = v_permission_ref
    AND (rp.tenant_id::text = v_tenant_id OR rp.tenant_id IS NULL)
    AND auth.rbac_status_is_active(rp.status::text)
  LIMIT 1;

  IF v_role_permission_id IS NOT NULL THEN
    RETURN v_role_permission_id;
  END IF;

  v_columns := 'tenant_id, role_permission_id, role_id, permission_id, status, metadata, created_at, updated_at';

  v_values :=
    auth.rbac_sql_value('role_permissions','tenant_id',v_tenant_id) || ', ' ||
    auth.rbac_generated_sql_value('role_permissions','role_permission_id','rperm') || ', ' ||
    auth.rbac_sql_value('role_permissions','role_id',v_role_ref) || ', ' ||
    auth.rbac_sql_value('role_permissions','permission_id',v_permission_ref) || ', ' ||
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
  v_role_ref text;
  v_user_role_id text;
  v_scope_value text;
  v_columns text;
  v_values text;
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
  v_role_ref := auth.rbac_role_ref_value(p_role_key, 'user_roles', 'role_id');

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

  IF v_user_role_id IS NOT NULL THEN
    RETURN v_user_role_id;
  END IF;

  v_columns := 'tenant_id, user_role_id, user_id, role_id, role_key, scope_type, scope_value, status, granted_by, granted_at, metadata, created_at, updated_at';

  v_values :=
    auth.rbac_sql_value('user_roles','tenant_id',v_tenant_id) || ', ' ||
    auth.rbac_generated_sql_value('user_roles','user_role_id','urole') || ', ' ||
    auth.rbac_sql_value('user_roles','user_id',p_user_id) || ', ' ||
    auth.rbac_sql_value('user_roles','role_id',v_role_ref) || ', ' ||
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
    WHERE ur.tenant_id::text = v_tenant_id
      AND ur.user_id::text = p_user_id
      AND auth.rbac_status_is_active(ur.status::text)
      AND ur.revoked_at IS NULL
      AND auth.rbac_permission_ref_matches(rp.permission_id::text, p_permission_key)
  )
  INTO v_exists;

  RETURN coalesce(v_exists, false);
END;
$$;

GRANT EXECUTE ON FUNCTION auth.rbac_role_ref_value(text, text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.rbac_permission_ref_value(text, text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.rbac_permission_ref_matches(text, text) TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO pix2pi_role_permission_verify_role;

COMMIT;
