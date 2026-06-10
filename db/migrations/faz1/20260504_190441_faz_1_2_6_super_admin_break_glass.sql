-- FAZ 1-2.6 Super-admin / Break-glass model
-- Reason guard, time-bound access, admin action audit, alert/event trace, abuse tests

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

CREATE TABLE IF NOT EXISTS auth.super_admin_principals (
  tenant_id text NOT NULL,
  principal_id text NOT NULL,
  principal_ref text NOT NULL,
  role_code text NOT NULL DEFAULT 'SUPER_ADMIN',
  status text NOT NULL DEFAULT 'ACTIVE',
  requires_break_glass boolean NOT NULL DEFAULT true,
  max_duration_minutes integer NOT NULL DEFAULT 120,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (tenant_id, principal_id)
);

CREATE TABLE IF NOT EXISTS auth.break_glass_access_sessions (
  tenant_id text NOT NULL,
  session_id text NOT NULL,
  actor_user_id text NOT NULL,
  target_tenant_id text NOT NULL,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'REQUESTED',
  requested_at timestamptz NOT NULL DEFAULT now(),
  approved_at timestamptz,
  approved_by text,
  expires_at timestamptz NOT NULL,
  closed_at timestamptz,
  close_reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, session_id)
);

CREATE TABLE IF NOT EXISTS auth.admin_action_audit (
  tenant_id text NOT NULL,
  action_id text NOT NULL,
  break_glass_session_id text NOT NULL,
  actor_user_id text NOT NULL,
  target_tenant_id text NOT NULL,
  action_type text NOT NULL,
  reason text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, action_id)
);

CREATE TABLE IF NOT EXISTS auth.security_alerts (
  tenant_id text NOT NULL,
  alert_id text NOT NULL,
  severity text NOT NULL,
  alert_type text NOT NULL,
  message text NOT NULL,
  break_glass_session_id text,
  actor_user_id text,
  target_tenant_id text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, alert_id)
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_super_admin_principals_status') THEN
    ALTER TABLE auth.super_admin_principals
      ADD CONSTRAINT ck_super_admin_principals_status
      CHECK (status IN ('ACTIVE', 'SUSPENDED', 'REVOKED'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_super_admin_principals_duration') THEN
    ALTER TABLE auth.super_admin_principals
      ADD CONSTRAINT ck_super_admin_principals_duration
      CHECK (max_duration_minutes BETWEEN 1 AND 120);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_break_glass_reason_required') THEN
    ALTER TABLE auth.break_glass_access_sessions
      ADD CONSTRAINT ck_break_glass_reason_required
      CHECK (length(btrim(reason)) >= 10);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_break_glass_status') THEN
    ALTER TABLE auth.break_glass_access_sessions
      ADD CONSTRAINT ck_break_glass_status
      CHECK (status IN ('REQUESTED', 'ACTIVE', 'CLOSED', 'EXPIRED', 'DENIED'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_break_glass_expires_after_request') THEN
    ALTER TABLE auth.break_glass_access_sessions
      ADD CONSTRAINT ck_break_glass_expires_after_request
      CHECK (expires_at > requested_at);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_admin_action_reason_required') THEN
    ALTER TABLE auth.admin_action_audit
      ADD CONSTRAINT ck_admin_action_reason_required
      CHECK (length(btrim(reason)) >= 10);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_admin_action_type_required') THEN
    ALTER TABLE auth.admin_action_audit
      ADD CONSTRAINT ck_admin_action_type_required
      CHECK (length(btrim(action_type)) >= 3);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_security_alert_severity') THEN
    ALTER TABLE auth.security_alerts
      ADD CONSTRAINT ck_security_alert_severity
      CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_break_glass_access_sessions_actor
  ON auth.break_glass_access_sessions (tenant_id, actor_user_id, status, expires_at);

CREATE INDEX IF NOT EXISTS idx_break_glass_access_sessions_target_tenant
  ON auth.break_glass_access_sessions (tenant_id, target_tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_admin_action_audit_session
  ON auth.admin_action_audit (tenant_id, break_glass_session_id, created_at);

CREATE INDEX IF NOT EXISTS idx_security_alerts_session
  ON auth.security_alerts (tenant_id, break_glass_session_id, created_at);

INSERT INTO auth.super_admin_principals (
  tenant_id,
  principal_id,
  principal_ref,
  role_code,
  status,
  requires_break_glass,
  max_duration_minutes,
  metadata
)
VALUES (
  'platform',
  'super_admin_role',
  'SUPER_ADMIN',
  'SUPER_ADMIN',
  'ACTIVE',
  true,
  120,
  '{"seed":"FAZ_1_2_6","break_glass_required":true}'::jsonb
)
ON CONFLICT (tenant_id, principal_id)
DO UPDATE SET
  principal_ref = EXCLUDED.principal_ref,
  role_code = EXCLUDED.role_code,
  status = 'ACTIVE',
  requires_break_glass = true,
  max_duration_minutes = 120,
  updated_at = now(),
  metadata = EXCLUDED.metadata;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name IN (
        'super_admin_principals',
        'break_glass_access_sessions',
        'admin_action_audit',
        'security_alerts'
      )
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

CREATE OR REPLACE FUNCTION auth.security_generated_id(p_prefix text)
RETURNS text
LANGUAGE sql
VOLATILE
AS $$
  SELECT p_prefix || '_' || md5(random()::text || clock_timestamp()::text || txid_current()::text);
$$;

CREATE OR REPLACE FUNCTION auth.request_break_glass(
  p_actor_user_id text,
  p_target_tenant_id text,
  p_reason text,
  p_duration_minutes integer DEFAULT 15,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_session_id text;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for break-glass request'
      USING ERRCODE = '22023';
  END IF;

  IF p_actor_user_id IS NULL OR btrim(p_actor_user_id) = '' THEN
    RAISE EXCEPTION 'actor_user_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_target_tenant_id IS NULL OR btrim(p_target_tenant_id) = '' THEN
    RAISE EXCEPTION 'target_tenant_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_reason IS NULL OR length(btrim(p_reason)) < 10 THEN
    RAISE EXCEPTION 'break-glass reason must be at least 10 characters'
      USING ERRCODE = '22023';
  END IF;

  IF p_duration_minutes IS NULL OR p_duration_minutes < 1 OR p_duration_minutes > 120 THEN
    RAISE EXCEPTION 'break-glass duration must be between 1 and 120 minutes'
      USING ERRCODE = '22023';
  END IF;

  v_session_id := auth.security_generated_id('bgs');

  INSERT INTO auth.break_glass_access_sessions (
    tenant_id,
    session_id,
    actor_user_id,
    target_tenant_id,
    reason,
    status,
    requested_at,
    expires_at,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_session_id,
    p_actor_user_id,
    p_target_tenant_id,
    btrim(p_reason),
    'REQUESTED',
    now(),
    now() + make_interval(mins => p_duration_minutes),
    coalesce(p_metadata, '{}'::jsonb)
  );

  INSERT INTO auth.security_alerts (
    tenant_id,
    alert_id,
    severity,
    alert_type,
    message,
    break_glass_session_id,
    actor_user_id,
    target_tenant_id,
    metadata
  )
  VALUES (
    v_tenant_id,
    auth.security_generated_id('alert'),
    'HIGH',
    'BREAK_GLASS_REQUESTED',
    'Break-glass access requested',
    v_session_id,
    p_actor_user_id,
    p_target_tenant_id,
    jsonb_build_object('duration_minutes', p_duration_minutes)
  );

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION auth.approve_break_glass(
  p_session_id text,
  p_approved_by text
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
    RAISE EXCEPTION 'tenant context is required for break-glass approval'
      USING ERRCODE = '22023';
  END IF;

  IF p_session_id IS NULL OR btrim(p_session_id) = '' THEN
    RAISE EXCEPTION 'session_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_approved_by IS NULL OR btrim(p_approved_by) = '' THEN
    RAISE EXCEPTION 'approved_by is required'
      USING ERRCODE = '22023';
  END IF;

  UPDATE auth.break_glass_access_sessions
  SET
    status = 'ACTIVE',
    approved_at = now(),
    approved_by = p_approved_by,
    updated_at = now()
  WHERE tenant_id = v_tenant_id
    AND session_id = p_session_id
    AND status = 'REQUESTED'
    AND expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'break-glass session cannot be approved'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO auth.security_alerts (
    tenant_id,
    alert_id,
    severity,
    alert_type,
    message,
    break_glass_session_id,
    actor_user_id,
    target_tenant_id,
    metadata
  )
  SELECT
    tenant_id,
    auth.security_generated_id('alert'),
    'CRITICAL',
    'BREAK_GLASS_APPROVED',
    'Break-glass access approved',
    session_id,
    actor_user_id,
    target_tenant_id,
    jsonb_build_object('approved_by', p_approved_by)
  FROM auth.break_glass_access_sessions
  WHERE tenant_id = v_tenant_id
    AND session_id = p_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION auth.record_admin_action(
  p_session_id text,
  p_action_type text,
  p_reason text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, app_security, public
AS $$
DECLARE
  v_tenant_id text;
  v_action_id text;
  v_session record;
BEGIN
  v_tenant_id := app_security.current_tenant_id_text();

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant context is required for admin action'
      USING ERRCODE = '22023';
  END IF;

  IF p_session_id IS NULL OR btrim(p_session_id) = '' THEN
    RAISE EXCEPTION 'break-glass session_id is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_action_type IS NULL OR length(btrim(p_action_type)) < 3 THEN
    RAISE EXCEPTION 'admin action_type is required'
      USING ERRCODE = '22023';
  END IF;

  IF p_reason IS NULL OR length(btrim(p_reason)) < 10 THEN
    RAISE EXCEPTION 'admin action reason must be at least 10 characters'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_session
  FROM auth.break_glass_access_sessions
  WHERE tenant_id = v_tenant_id
    AND session_id = p_session_id
    AND status = 'ACTIVE'
    AND expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'active break-glass session is required for admin action'
      USING ERRCODE = '42501';
  END IF;

  v_action_id := auth.security_generated_id('admact');

  INSERT INTO auth.admin_action_audit (
    tenant_id,
    action_id,
    break_glass_session_id,
    actor_user_id,
    target_tenant_id,
    action_type,
    reason,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_action_id,
    p_session_id,
    v_session.actor_user_id,
    v_session.target_tenant_id,
    btrim(p_action_type),
    btrim(p_reason),
    coalesce(p_metadata, '{}'::jsonb)
  );

  INSERT INTO auth.security_alerts (
    tenant_id,
    alert_id,
    severity,
    alert_type,
    message,
    break_glass_session_id,
    actor_user_id,
    target_tenant_id,
    metadata
  )
  VALUES (
    v_tenant_id,
    auth.security_generated_id('alert'),
    'CRITICAL',
    'ADMIN_ACTION_RECORDED',
    'Privileged admin action recorded under break-glass',
    p_session_id,
    v_session.actor_user_id,
    v_session.target_tenant_id,
    jsonb_build_object('action_id', v_action_id, 'action_type', p_action_type)
  );

  RETURN v_action_id;
END;
$$;

CREATE OR REPLACE FUNCTION auth.close_break_glass(
  p_session_id text,
  p_close_reason text
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
    RAISE EXCEPTION 'tenant context is required for break-glass close'
      USING ERRCODE = '22023';
  END IF;

  IF p_close_reason IS NULL OR length(btrim(p_close_reason)) < 10 THEN
    RAISE EXCEPTION 'close reason must be at least 10 characters'
      USING ERRCODE = '22023';
  END IF;

  UPDATE auth.break_glass_access_sessions
  SET
    status = 'CLOSED',
    closed_at = now(),
    close_reason = btrim(p_close_reason),
    updated_at = now()
  WHERE tenant_id = v_tenant_id
    AND session_id = p_session_id
    AND status IN ('REQUESTED', 'ACTIVE');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'break-glass session cannot be closed'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO auth.security_alerts (
    tenant_id,
    alert_id,
    severity,
    alert_type,
    message,
    break_glass_session_id,
    metadata
  )
  VALUES (
    v_tenant_id,
    auth.security_generated_id('alert'),
    'HIGH',
    'BREAK_GLASS_CLOSED',
    'Break-glass access closed',
    p_session_id,
    jsonb_build_object('close_reason', p_close_reason)
  );
END;
$$;

GRANT USAGE ON SCHEMA auth TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.security_generated_id(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.request_break_glass(text, text, text, integer, jsonb) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.approve_break_glass(text, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.record_admin_action(text, text, text, jsonb) TO PUBLIC;
GRANT EXECUTE ON FUNCTION auth.close_break_glass(text, text) TO PUBLIC;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_break_glass_verify_role') THEN
    CREATE ROLE pix2pi_break_glass_verify_role;
  END IF;
END $$;

GRANT USAGE ON SCHEMA auth TO pix2pi_break_glass_verify_role;
GRANT USAGE ON SCHEMA app_security TO pix2pi_break_glass_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.super_admin_principals TO pix2pi_break_glass_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.break_glass_access_sessions TO pix2pi_break_glass_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.admin_action_audit TO pix2pi_break_glass_verify_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.security_alerts TO pix2pi_break_glass_verify_role;
GRANT EXECUTE ON FUNCTION app_security.set_tenant_context(text) TO pix2pi_break_glass_verify_role;
GRANT EXECUTE ON FUNCTION auth.request_break_glass(text, text, text, integer, jsonb) TO pix2pi_break_glass_verify_role;
GRANT EXECUTE ON FUNCTION auth.approve_break_glass(text, text) TO pix2pi_break_glass_verify_role;
GRANT EXECUTE ON FUNCTION auth.record_admin_action(text, text, text, jsonb) TO pix2pi_break_glass_verify_role;
GRANT EXECUTE ON FUNCTION auth.close_break_glass(text, text) TO pix2pi_break_glass_verify_role;

COMMIT;
