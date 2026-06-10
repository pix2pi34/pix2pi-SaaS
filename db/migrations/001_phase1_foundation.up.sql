BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS org;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS security;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS meta;
CREATE SCHEMA IF NOT EXISTS franchise;
CREATE SCHEMA IF NOT EXISTS partner;

CREATE DOMAIN core.code_text AS text
CHECK (VALUE ~ '^[A-Z0-9_\-]+$');

CREATE DOMAIN core.email_text AS text
CHECK (position('@' in VALUE) > 1);

CREATE TYPE core.record_status AS ENUM ('active', 'passive', 'draft', 'archived', 'deleted');
CREATE TYPE org.branch_operating_model AS ENUM ('company_owned', 'franchise_operated');
CREATE TYPE org.location_kind AS ENUM ('store', 'branch', 'warehouse', 'facility', 'office');
CREATE TYPE auth.scope_level AS ENUM ('tenant', 'legal_entity', 'branch');
CREATE TYPE auth.break_glass_reason AS ENUM ('incident_response', 'security_investigation', 'data_recovery', 'support_exception');
CREATE TYPE audit.export_kind AS ENUM ('csv', 'excel', 'pdf', 'json');

CREATE OR REPLACE FUNCTION core.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION security.set_claim(claim text, value text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config(claim, coalesce(value, ''), true);
END;
$$;

CREATE OR REPLACE FUNCTION security.current_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT nullif(current_setting('app.current_tenant_id', true), '')::uuid
$$;

CREATE OR REPLACE FUNCTION security.current_legal_entity_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT nullif(current_setting('app.current_legal_entity_id', true), '')::uuid
$$;

CREATE OR REPLACE FUNCTION security.current_branch_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT nullif(current_setting('app.current_branch_id', true), '')::uuid
$$;

CREATE OR REPLACE FUNCTION security.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce(nullif(current_setting('app.is_super_admin', true), ''), 'false')::boolean
$$;

CREATE TABLE platform.tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_code core.code_text NOT NULL UNIQUE,
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  timezone text NOT NULL DEFAULT 'Europe/Istanbul',
  country_code char(2) NOT NULL DEFAULT 'TR',
  status core.record_status NOT NULL DEFAULT 'active',
  owner_legal_entity_id uuid,
  data_partition_key text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  row_version bigint NOT NULL DEFAULT 1,
  deleted_at timestamptz,
  CONSTRAINT tenants_slug_format_ck CHECK (slug ~ '^[a-z0-9\-]+$')
);

CREATE TABLE core.schema_registry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schema_name text NOT NULL UNIQUE,
  purpose text NOT NULL,
  isolation_level text NOT NULL,
  owner_domain text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO core.schema_registry (schema_name, purpose, isolation_level, owner_domain)
VALUES
  ('platform', 'tenant and platform level records', 'global', 'platform'),
  ('org', 'organization and branch structures', 'tenant', 'organization'),
  ('auth', 'access control and user scope data', 'tenant', 'security'),
  ('audit', 'audit events and export records', 'tenant', 'security'),
  ('franchise', 'franchise contracts and controls', 'tenant', 'organization'),
  ('partner', 'cross-company relations', 'tenant', 'organization'),
  ('meta', 'data dictionary and field contracts', 'global', 'platform');

CREATE TABLE org.legal_entities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  business_code core.code_text NOT NULL,
  legal_name text NOT NULL,
  trade_name text,
  tax_number varchar(20) NOT NULL,
  tax_office text,
  mersis_number varchar(20),
  country_code char(2) NOT NULL DEFAULT 'TR',
  timezone text NOT NULL DEFAULT 'Europe/Istanbul',
  status core.record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  row_version bigint NOT NULL DEFAULT 1,
  deleted_at timestamptz,
  UNIQUE (tenant_id, business_code),
  UNIQUE (tenant_id, tax_number)
);

ALTER TABLE platform.tenants
  ADD CONSTRAINT tenants_owner_legal_entity_fk
  FOREIGN KEY (owner_legal_entity_id) REFERENCES org.legal_entities(id) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE org.branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  legal_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE RESTRICT,
  business_code core.code_text NOT NULL,
  name text NOT NULL,
  short_name text,
  operating_model org.branch_operating_model NOT NULL DEFAULT 'company_owned',
  branch_type org.location_kind NOT NULL DEFAULT 'branch',
  phone text,
  email core.email_text,
  status core.record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  row_version bigint NOT NULL DEFAULT 1,
  deleted_at timestamptz,
  UNIQUE (tenant_id, business_code)
);

CREATE TABLE meta.table_column_standards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_schema text NOT NULL,
  table_name text NOT NULL,
  column_name text NOT NULL,
  data_type text NOT NULL,
  is_required boolean NOT NULL DEFAULT true,
  semantic_role text NOT NULL,
  notes text,
  UNIQUE (table_schema, table_name, column_name)
);

INSERT INTO meta.table_column_standards (table_schema, table_name, column_name, data_type, is_required, semantic_role, notes)
VALUES
  ('*', '*', 'id', 'uuid', true, 'primary_key', 'Primary key uses uuid and defaults to gen_random_uuid'),
  ('*', '*', 'tenant_id', 'uuid', true, 'tenant_scope', 'Tenant scoped tables must carry tenant_id'),
  ('*', '*', 'business_code', 'core.code_text', true, 'business_identifier', 'Readable business identifier'),
  ('*', '*', 'created_at', 'timestamptz', true, 'audit_time', 'Default now()'),
  ('*', '*', 'updated_at', 'timestamptz', true, 'audit_time', 'Updated by trigger'),
  ('*', '*', 'created_by', 'uuid', false, 'audit_actor', 'Application user id'),
  ('*', '*', 'updated_by', 'uuid', false, 'audit_actor', 'Application user id'),
  ('*', '*', 'row_version', 'bigint', true, 'optimistic_lock', 'Starts from 1'),
  ('*', '*', 'deleted_at', 'timestamptz', false, 'soft_delete', 'NULL means active row');

CREATE TABLE meta.field_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_schema text NOT NULL,
  table_name text NOT NULL,
  field_name text NOT NULL,
  label_tr text NOT NULL,
  data_type text NOT NULL,
  nullable boolean NOT NULL DEFAULT false,
  default_expression text,
  domain_rule text,
  ui_hint jsonb NOT NULL DEFAULT '{}'::jsonb,
  api_contract jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (table_schema, table_name, field_name)
);

INSERT INTO meta.field_contracts (table_schema, table_name, field_name, label_tr, data_type, nullable, domain_rule, ui_hint, api_contract)
VALUES
  ('platform', 'tenants', 'business_code', 'Tenant Kodu', 'core.code_text', false, 'Büyük harf, rakam, alt çizgi ve tire', '{"component":"text"}', '{"required":true,"maxLength":50}'),
  ('org', 'legal_entities', 'tax_number', 'Vergi Numarası', 'varchar(20)', false, 'Tenant içinde eşsiz olmalı', '{"component":"text"}', '{"required":true,"maxLength":20}'),
  ('org', 'branches', 'operating_model', 'İşletme Modeli', 'org.branch_operating_model', false, 'company_owned veya franchise_operated', '{"component":"select"}', '{"required":true}');

CREATE TABLE auth.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  email core.email_text NOT NULL,
  full_name text NOT NULL,
  password_hash text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  is_super_admin boolean NOT NULL DEFAULT false,
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  row_version bigint NOT NULL DEFAULT 1,
  deleted_at timestamptz,
  UNIQUE (tenant_id, email)
);

CREATE TABLE auth.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  role_code core.code_text NOT NULL,
  role_name text NOT NULL,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, role_code)
);

CREATE TABLE auth.permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  permission_code core.code_text NOT NULL UNIQUE,
  module_code core.code_text NOT NULL,
  action_code core.code_text NOT NULL,
  description text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE auth.role_permissions (
  role_id uuid NOT NULL REFERENCES auth.roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES auth.permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE auth.user_role_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES auth.roles(id) ON DELETE CASCADE,
  legal_entity_id uuid REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES org.branches(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_user_role_assignments_scope
ON auth.user_role_assignments (
  user_id,
  role_id,
  coalesce(legal_entity_id, '00000000-0000-0000-0000-000000000000'::uuid),
  coalesce(branch_id, '00000000-0000-0000-0000-000000000000'::uuid)
);

CREATE TABLE auth.user_scopes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scope_level auth.scope_level NOT NULL,
  legal_entity_id uuid REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES org.branches(id) ON DELETE CASCADE,
  can_view boolean NOT NULL DEFAULT true,
  can_edit boolean NOT NULL DEFAULT false,
  can_export boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_scopes_target_ck CHECK (
    (scope_level = 'tenant' AND legal_entity_id IS NULL AND branch_id IS NULL)
    OR (scope_level = 'legal_entity' AND legal_entity_id IS NOT NULL AND branch_id IS NULL)
    OR (scope_level = 'branch' AND legal_entity_id IS NOT NULL AND branch_id IS NOT NULL)
  )
);

CREATE TABLE auth.break_glass_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason auth.break_glass_reason NOT NULL,
  approved_by uuid REFERENCES auth.users(id),
  justification text NOT NULL,
  starts_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);

CREATE TABLE audit.audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  legal_entity_id uuid REFERENCES org.legal_entities(id) ON DELETE SET NULL,
  branch_id uuid REFERENCES org.branches(id) ON DELETE SET NULL,
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_code core.code_text NOT NULL,
  entity_schema text NOT NULL,
  entity_table text NOT NULL,
  entity_id uuid,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit.export_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  legal_entity_id uuid REFERENCES org.legal_entities(id) ON DELETE SET NULL,
  branch_id uuid REFERENCES org.branches(id) ON DELETE SET NULL,
  requested_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  export_kind audit.export_kind NOT NULL,
  export_scope jsonb NOT NULL DEFAULT '{}'::jsonb,
  storage_key text,
  status core.record_status NOT NULL DEFAULT 'draft',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE org.entity_relations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  parent_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  child_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  relation_type core.code_text NOT NULL,
  ownership_ratio numeric(5,2),
  effective_from date NOT NULL,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT entity_relations_date_ck CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CONSTRAINT entity_relations_distinct_ck CHECK (parent_entity_id <> child_entity_id)
);

CREATE TABLE org.entity_shareholders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  legal_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  shareholder_kind core.code_text NOT NULL,
  shareholder_name text NOT NULL,
  shareholder_entity_id uuid REFERENCES org.legal_entities(id) ON DELETE SET NULL,
  ownership_ratio numeric(5,2) NOT NULL,
  voting_ratio numeric(5,2),
  effective_from date NOT NULL,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ownership_ratio >= 0 AND ownership_ratio <= 100),
  CHECK (voting_ratio IS NULL OR (voting_ratio >= 0 AND voting_ratio <= 100))
);

CREATE TABLE franchise.agreements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  franchisor_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  franchisee_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES org.branches(id) ON DELETE SET NULL,
  agreement_code core.code_text NOT NULL,
  royalty_rate numeric(5,2),
  starts_on date NOT NULL,
  ends_on date,
  status core.record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, agreement_code)
);

CREATE TABLE org.locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  legal_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES org.branches(id) ON DELETE CASCADE,
  location_kind org.location_kind NOT NULL,
  name text NOT NULL,
  address_line_1 text,
  address_line_2 text,
  district text,
  city text,
  country_code char(2) NOT NULL DEFAULT 'TR',
  postal_code text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE org.entity_branch_visibility_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  source_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  target_entity_id uuid REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  target_branch_id uuid REFERENCES org.branches(id) ON DELETE CASCADE,
  can_view_sales boolean NOT NULL DEFAULT false,
  can_view_stock boolean NOT NULL DEFAULT false,
  can_export boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (target_entity_id IS NOT NULL OR target_branch_id IS NOT NULL)
);

CREATE TABLE partner.company_relations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  source_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  target_entity_id uuid NOT NULL REFERENCES org.legal_entities(id) ON DELETE CASCADE,
  relation_kind core.code_text NOT NULL,
  partner_role core.code_text NOT NULL,
  starts_on date NOT NULL,
  ends_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (source_entity_id <> target_entity_id)
);

CREATE INDEX idx_legal_entities_tenant_status ON org.legal_entities (tenant_id, status);
CREATE INDEX idx_branches_tenant_entity_status ON org.branches (tenant_id, legal_entity_id, status);
CREATE INDEX idx_user_scopes_tenant_user_scope ON auth.user_scopes (tenant_id, user_id, scope_level);
CREATE INDEX idx_audit_events_tenant_created ON audit.audit_events (tenant_id, created_at DESC);
CREATE INDEX idx_export_jobs_tenant_status ON audit.export_jobs (tenant_id, status, created_at DESC);
CREATE INDEX idx_entity_relations_parent_child ON org.entity_relations (tenant_id, parent_entity_id, child_entity_id);
CREATE INDEX idx_locations_tenant_kind ON org.locations (tenant_id, location_kind);

CREATE OR REPLACE FUNCTION security.tenant_row_visible(row_tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT security.is_super_admin() OR row_tenant_id = security.current_tenant_id()
$$;

ALTER TABLE platform.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.legal_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.legal_entities FORCE ROW LEVEL SECURITY;
ALTER TABLE org.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.branches FORCE ROW LEVEL SECURITY;
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.users FORCE ROW LEVEL SECURITY;
ALTER TABLE auth.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.roles FORCE ROW LEVEL SECURITY;
ALTER TABLE auth.user_role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.user_role_assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE auth.user_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.user_scopes FORCE ROW LEVEL SECURITY;
ALTER TABLE auth.break_glass_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.break_glass_sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE audit.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit.audit_events FORCE ROW LEVEL SECURITY;
ALTER TABLE audit.export_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit.export_jobs FORCE ROW LEVEL SECURITY;
ALTER TABLE org.entity_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.entity_relations FORCE ROW LEVEL SECURITY;
ALTER TABLE org.entity_shareholders ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.entity_shareholders FORCE ROW LEVEL SECURITY;
ALTER TABLE franchise.agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE franchise.agreements FORCE ROW LEVEL SECURITY;
ALTER TABLE org.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.locations FORCE ROW LEVEL SECURITY;
ALTER TABLE org.entity_branch_visibility_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.entity_branch_visibility_rules FORCE ROW LEVEL SECURITY;
ALTER TABLE partner.company_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner.company_relations FORCE ROW LEVEL SECURITY;

CREATE POLICY p_tenants_select ON platform.tenants
  FOR SELECT USING (security.tenant_row_visible(id));

CREATE POLICY p_tenant_owned_rows_all ON org.legal_entities
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_branch_rows_all ON org.branches
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_auth_users_rows_all ON auth.users
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_auth_roles_rows_all ON auth.roles
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_auth_role_assignments_rows_all ON auth.user_role_assignments
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_auth_scopes_rows_all ON auth.user_scopes
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_break_glass_rows_all ON auth.break_glass_sessions
  USING (security.is_super_admin() OR security.tenant_row_visible(tenant_id))
  WITH CHECK (security.is_super_admin() OR security.tenant_row_visible(tenant_id));

CREATE POLICY p_audit_events_rows_all ON audit.audit_events
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_export_jobs_rows_all ON audit.export_jobs
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_entity_relations_rows_all ON org.entity_relations
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_entity_shareholders_rows_all ON org.entity_shareholders
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_franchise_rows_all ON franchise.agreements
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_locations_rows_all ON org.locations
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_visibility_rules_rows_all ON org.entity_branch_visibility_rules
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE POLICY p_partner_relations_rows_all ON partner.company_relations
  USING (security.tenant_row_visible(tenant_id))
  WITH CHECK (security.tenant_row_visible(tenant_id));

CREATE TRIGGER trg_tenants_touch_updated_at
  BEFORE UPDATE ON platform.tenants
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_legal_entities_touch_updated_at
  BEFORE UPDATE ON org.legal_entities
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_branches_touch_updated_at
  BEFORE UPDATE ON org.branches
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_auth_users_touch_updated_at
  BEFORE UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_auth_roles_touch_updated_at
  BEFORE UPDATE ON auth.roles
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_user_scopes_touch_updated_at
  BEFORE UPDATE ON auth.user_scopes
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_break_glass_touch_updated_at
  BEFORE UPDATE ON auth.break_glass_sessions
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_export_jobs_touch_updated_at
  BEFORE UPDATE ON audit.export_jobs
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_entity_relations_touch_updated_at
  BEFORE UPDATE ON org.entity_relations
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_entity_shareholders_touch_updated_at
  BEFORE UPDATE ON org.entity_shareholders
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_franchise_touch_updated_at
  BEFORE UPDATE ON franchise.agreements
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_locations_touch_updated_at
  BEFORE UPDATE ON org.locations
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_visibility_rules_touch_updated_at
  BEFORE UPDATE ON org.entity_branch_visibility_rules
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

CREATE TRIGGER trg_partner_relations_touch_updated_at
  BEFORE UPDATE ON partner.company_relations
  FOR EACH ROW EXECUTE FUNCTION core.touch_updated_at();

INSERT INTO auth.permissions (permission_code, module_code, action_code, description)
VALUES
  ('TENANT_VIEW', 'TENANT', 'VIEW', 'Tenant görüntüleme'),
  ('TENANT_SWITCH', 'TENANT', 'SWITCH', 'Tenant değiştirme'),
  ('USER_MANAGE', 'AUTH', 'MANAGE', 'Kullanıcı yönetimi'),
  ('ROLE_MANAGE', 'AUTH', 'MANAGE', 'Rol yönetimi'),
  ('EXPORT_RUN', 'EXPORT', 'RUN', 'Export başlatma');

COMMIT;

