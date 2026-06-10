-- FAZ 1-2.4 auth.user_scopes canonical runtime model FIX V3
-- Fix: do not alter existing user_scopes column types while policies depend on them.
-- Runtime casts values adaptively based on actual column udt_name.

BEGIN;

CREATE SCHEMA IF NOT EXISTS auth;
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

CREATE OR REPLACE FUNCTION auth.security_generated_id(p_prefix text)
RETURNS text
LANGUAGE sql
VOLATILE
AS $$
  SELECT p_prefix || '_' || md5(random()::text || clock_timestamp()::text || txid_current()::text);
$$;

CREATE TABLE IF NOT EXISTS auth.user_scopes (
  tenant_id text,
  user_id text,
  legal_entity_id text,
  branch_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE auth.user_scopes
  ADD COLUMN IF NOT EXISTS scope_id text,
  ADD COLUMN IF NOT EXISTS scope_type text,
  ADD COLUMN IF NOT EXISTS scope_value text,
  ADD COLUMN IF NOT EXISTS accountant_company_id text,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS granted_by text,
  ADD COLUMN IF NOT EXISTS granted_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_by text,
  ADD COLUMN IF NOT EXISTS revoke_reason text,
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

ALTER TABLE auth.user_scopes
  ALTER COLUMN status SET DEFAULT 'ACTIVE',
  ALTER COLUMN granted_at SET DEFAULT now(),
  ALTER COLUMN metadata SET DEFAULT '{}'::jsonb,
  ALTER COLUMN created_at SET DEFAULT now(),
  ALTER COLUMN updated_at SET DEFAULT now();

UPDATE auth.user_scopes
SET
  scope_id = coalesce(nullif(scope_id::text, ''), auth.security_generated_id('uscope')),
  scope_type = coalesce(nullif(scope_type::text, ''), 'TENANT'),
  scope_value = coalesce(nullif(scope_value::text, ''), tenant_id::text),
  status = coalesce(nullif(status::text, ''), 'ACTIVE'),
  granted_at = coalesce(granted_at, now()),
  metadata = coalesce(metadata, '{}'::jsonb),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now())
WHERE scope_id IS NULL
   OR scope_type IS NULL
   OR scope_value IS NULL
   OR status IS NULL
   OR granted_at IS NULL
   OR metadata IS NULL
   OR created_at IS NULL
   OR updated_at IS NULL;

CREATE TABLE IF NOT EXISTS auth.user_scope_audit (
  tenant_id text NOT NULL,
  audit_id text NOT NULL,
  scope_id text NOT NULL,
  user_id text NOT NULL,
  action_type text NOT NULL,
  actor_user_id text,
  reason text,
  old_status text,
  new_status text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, audit_id)
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_user_scopes_scope_type') THEN
    ALTER TABLE auth.user_scopes
      ADD CONSTRAINT ck_user_scopes_scope_type
      CHECK (scope_type::text IN (
        'TENANT',
        'LEGAL_ENTITY',
        'BRANCH',
        'ACCOUNTANT_ASSIGNED_COMPANY'
      )) NOT VALID;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_user_scopes_status') THEN
    ALTER TABLE auth.user_scopes
      ADD CONSTRAINT ck_user_scopes_status
      CHECK (status::text IN ('ACTIVE', 'REVOKED', 'EXPIRED')) NOT VALID;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_user_scopes_scope_value_required') THEN
    ALTER TABLE auth.user_scopes
      ADD CONSTRAINT ck_user_scopes_scope_value_required
      CHECK (scope_value IS NOT NULL AND length(btrim(scope_value::text)) > 0) NOT VALID;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_user_scopes_user_required') THEN
    ALTER TABLE auth.user_scopes
      ADD CONSTRAINT ck_user_scopes_user_required
      CHECK (user_id IS NOT NULL AND length(btrim(user_id::text)) > 0) NOT VALID;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_user_scopes_expiry_after_grant') THEN
    ALTER TABLE auth.user_scopes
      ADD CONSTRAINT ck_user_scopes_expiry_after_grant
      CHECK (expires_at IS NULL OR expires_at > granted_at) NOT VALID;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_user_scope_audit_action_type') THEN
    ALTER TABLE auth.user_scope_audit
      ADD CONSTRAINT ck_user_scope_audit_action_type
      CHECK (action_type IN ('GRANTED', 'REVOKED', 'EXPIRED_CHECK', 'ASSERTED')) NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_scopes_user_scope
  ON auth.user_scopes (tenant_id, user_id, scope_type, scope_value, status);

CREATE INDEX IF NOT EXISTS idx_user_scopes_legal_entity
  ON auth.user_scopes (tenant_id, user_id, legal_entity_id, status);

CREATE INDEX IF NOT EXISTS idx_user_scopes_branch
  ON auth.user_scopes (tenant_id, user_id, branch_id, status);

CREATE INDEX IF NOT EXISTS idx_user_scopes_accountant_company
  ON auth.user_scopes (tenant_id, user_id, accountant_company_id, status);

CREATE INDEX IF NOT EXISTS idx_user_scopes_expiration
  ON auth.user_scopes (tenant_id, status, expires_at);

CREATE INDEX IF NOT EXISTS idx_user_scope_audit_scope
  ON auth.user_scope_audit (tenant_id, scope_id, created_at);

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name IN ('user_scopes', 'user_scope_audit')
      AND column_name = 'tenant_id'
    GROUP BY table_schema, table_name
    ORDER BY table_name
  LOOP
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', r.table_schema, r.table_name);
    EXECUTE format('ALTER TABLE %I.%I FORCE ROW LEVEL SECURITY', r.table_schema, r.table_name);

    EXECUTE format('DROP POLICY IF EXISTS pix2pi_tenant_isolation_allow ON %I.%I', r.table_schema, r.table_name);
    EXECUTE format('DROP POLICY IF EXISTS pix2pi_tenant_isolation_enforce ON %I.%I', r.table_schema, r.table_name);

    EXECUTE format(
      'CREATE POLICY pix2pi_tenant_isolation_allow ON %I.%I AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id::text = app_security.current_tenant_id_text()) WITH CHECK (tenant_id::text = app_security.current_tenant_id_text())',
      r.table_schema,
      r.table_name
    );

    EXECUTE format(
      'CREATE POLICY pix2pi_tenant_isolation_enforce ON %I.%I AS RESTRICTIVE FOR ALL TO PUBLIC USING (tenant_id::text = app_security.current_tenant_id_text()) WITH CHECK (tenant_id::text = app_security.current_tenant_id_text())',
      r.table_schema,
      r.table_name
    );
  END LOOP;
END $$;

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
BEGIN
  IF p_value IS NULL OR btrim(p_value) = '' THEN
    RETURN 'NULL';
  END IF;

  SELECT c.udt_name
  INTO v_udt_name
  FROM information_schema.columns c
  WHERE c.table_schema = 'auth'
    AND c.table_name = 'user_scopes'
    AND c.column_name = p_column_name
  LIMIT 1;

  IF v_udt_name = 'uuid' THEN
    RETURN format('%L::uuid', p_value);
  END IF;

  RETURN format('%L', p_value);
END;
$$;

CREATE OR REPLACE FUNCTION auth.user_scope_normalized_value(
  p_scope_type text,
  p_scope_value text,
  p_legal_entity_id text,
  p_branch_id text,
  p_accountant_company_id text
)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  IF p_scope_type = 'TENANT' THEN
    RETURN coalesce(nullif(btrim(p_scope_value), ''), app_security.current_tenant_id_text());
  ELSIF p_scope_type = 'LEGAL_ENTITY' THEN
    RETURN coalesce(nullif(btrim(p_legal_entity_id), ''), nullif(btrim(p_scope_value), ''));
  ELSIF p_scope_type = 'BRANCH' THEN
    RETURN coalesce(nullif(btrim(p_branch_id), ''), nullif(btrim(p_scope_value), ''));
  ELSIF p_scope_type = 'ACCOUNTANT_ASSIGNED_COMPANY' THEN
    RETURN coalesce(nullif(btrim(p_accountant_company_id), ''), nullif(btrim(p_scope_value), ''));
  END IF;

  RETURN nullif(btrim(p_scope_value), '');
END;
$$;

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

  EXECUTE
    'INSERT INTO auth.user_scopes (
      tenant_id,
      scope_id,
      user_id,
      scope_type,
      scope_value,
      legal_entity_id,
      branch_id,
      accountant_company_id,
      status,
      granted_by,
      granted_at,
      expires_at,
      metadata,
      created_at,
      updated_at
    ) VALUES (' ||
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
      'now(), $1, $2, now(), now())'
  USING p_expires_at, coalesce(p_metadata, '{}'::jsonb);

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

CREATE OR REPLACE FUNCTION auth.revoke_user_scope(
  p_scope_id text,
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
  v_scope record;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for user scope revoke'
      USING ERRCODE = '22023';
  END IF;

  IF p_scope_id IS NULL OR btrim(p_scope_id) = '' THEN
    RAISE EXCEPTION 'scope_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_revoke_reason IS NULL OR length(btrim(p_revoke_reason)) < 10 THEN
    RAISE EXCEPTION 'revoke reason must be at least 10 characters'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_scope
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id
    AND scope_id::text = p_scope_id
    AND status::text = 'ACTIVE';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'active user scope not found for revoke'
      USING ERRCODE = '42501';
  END IF;

  UPDATE auth.user_scopes
  SET
    status = 'REVOKED',
    revoked_at = now(),
    revoked_by = nullif(btrim(coalesce(p_revoked_by, '')), ''),
    revoke_reason = btrim(p_revoke_reason),
    updated_at = now()
  WHERE tenant_id::text = v_tenant_id
    AND scope_id::text = p_scope_id;

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
    p_scope_id,
    v_scope.user_id::text,
    'REVOKED',
    nullif(btrim(coalesce(p_revoked_by, '')), ''),
    btrim(p_revoke_reason),
    'ACTIVE',
    'REVOKED',
    jsonb_build_object('scope_type', v_scope.scope_type::text, 'scope_value', v_scope.scope_value::text)
  );
END;
$$;

CREATE OR REPLACE FUNCTION auth.user_has_scope(
  p_user_id text,
  p_scope_type text,
  p_scope_value text
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
    FROM auth.user_scopes
    WHERE tenant_id::text = v_tenant_id
      AND user_id::text = p_user_id
      AND scope_type::text = p_scope_type
      AND scope_value::text = p_scope_value
      AND status::text = 'ACTIVE'
      AND (expires_at IS NULL OR expires_at > now())
  )
  INTO v_exists;

  RETURN coalesce(v_exists, false);
END;
$$;

CREATE OR REPLACE FUNCTION auth.assert_user_scope(
  p_user_id text,
  p_scope_type text,
  p_scope_value text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
BEGIN
  IF NOT auth.user_has_scope(p_user_id, p_scope_type, p_scope_value) THEN
    RAISE EXCEPTION 'required user scope missing: user=%, scope_type=%, scope_value=%',
      p_user_id,
      p_scope_type,
      p_scope_value
      USING ERRCODE = '42501';
  END IF;
END;
$$;

GRANT USAGE ON SCHEMA auth TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.user_scope_sql_value(text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.user_scope_normalized_value(text, text, text, text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.grant_user_scope(text, text, text, text, text, text, text, timestamptz, jsonb) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.revoke_user_scope(text, text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.user_has_scope(text, text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.assert_user_scope(text, text, text) TO PUBLIC;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_user_scope_verify_role') THEN
    CREATE ROLE pix2pi_user_scope_verify_role;
  END IF;
END $$;

GRANT USAGE ON SCHEMA auth TO pix2pi_user_scope_verify_role;
GRANT USAGE ON SCHEMA app_security TO pix2pi_user_scope_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_scopes TO pix2pi_user_scope_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_scope_audit TO pix2pi_user_scope_verify_role;
GRANT EXECUTE ON FUNCTION app_security.set_tenant_context(text) TO pix2pi_user_scope_verify_role;
GRANT EXECUTE ON FUNCTION auth.grant_user_scope(text, text, text, text, text, text, text, timestamptz, jsonb) TO pix2pi_user_scope_verify_role;
GRANT EXECUTE ON FUNCTION auth.revoke_user_scope(text, text, text) TO pix2pi_user_scope_verify_role;
GRANT EXECUTE ON FUNCTION auth.user_has_scope(text, text, text) TO pix2pi_user_scope_verify_role;
GRANT EXECUTE ON FUNCTION auth.assert_user_scope(text, text, text) TO pix2pi_user_scope_verify_role;

COMMIT;
