BEGIN;

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
  v_permission_ref text;
  v_exists boolean;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RETURN false;
  END IF;

  IF p_user_id IS NULL OR btrim(p_user_id) = '' THEN
    RETURN false;
  END IF;

  IF p_permission_key IS NULL OR btrim(p_permission_key) = '' THEN
    RETURN false;
  END IF;

  BEGIN
    v_permission_ref := auth.rbac_permission_ref_value(
      p_permission_key,
      'role_permissions',
      'permission_id'
    );
  EXCEPTION WHEN OTHERS THEN
    RETURN false;
  END;

  /*
    Legacy-aware permission check:

    user_roles.role_id may store auth.roles.role_id text OR auth.roles.id uuid.
    role_permissions.role_id may store auth.roles.role_id text OR auth.roles.id uuid.

    Therefore permission is resolved through role_key + bridge reference,
    not by assuming user_roles.role_id = role_permissions.role_id.
  */
  SELECT EXISTS (
    SELECT 1
    FROM auth.user_roles ur
    JOIN auth.role_permissions rp
      ON rp.role_id::text = auth.rbac_role_ref_value(
           ur.role_key::text,
           'role_permissions',
           'role_id'
         )
     AND rp.permission_id::text = v_permission_ref
     AND (rp.tenant_id::text = v_tenant_id OR rp.tenant_id IS NULL)
     AND auth.rbac_status_is_active(rp.status::text)
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

GRANT EXECUTE ON FUNCTION auth.rbac_user_has_permission(text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.rbac_assert_permission(text, text) TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO pix2pi_role_permission_verify_role;

COMMIT;
