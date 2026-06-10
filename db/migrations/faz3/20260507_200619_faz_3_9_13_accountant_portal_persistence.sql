BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.accountant_portal_accounts (
    tenant_id uuid NOT NULL,
    accountant_account_id uuid NOT NULL DEFAULT gen_random_uuid(),

    accountant_account_no varchar(128) NOT NULL,

    accountant_firm_title varchar(255) NOT NULL,
    accountant_party_id uuid,

    tax_identity_no varchar(32),
    tax_office varchar(128),
    mersis_no varchar(64),

    phone varchar(64),
    email varchar(255),
    address_text text,

    portal_status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    onboarding_status varchar(40) NOT NULL DEFAULT 'DRAFT',

    default_export_format varchar(32) NOT NULL DEFAULT 'XLSX',
    default_accounting_package varchar(64) DEFAULT 'TDHP',

    max_assigned_company_count integer NOT NULL DEFAULT 0,
    active_assigned_company_count integer NOT NULL DEFAULT 0,

    billing_enabled boolean NOT NULL DEFAULT false,
    trial_enabled boolean NOT NULL DEFAULT false,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT accountant_portal_accounts_pk PRIMARY KEY (tenant_id, accountant_account_id),
    CONSTRAINT accountant_portal_accounts_no_unique UNIQUE (tenant_id, accountant_account_no),
    CONSTRAINT accountant_portal_accounts_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT accountant_portal_accounts_party_fk FOREIGN KEY (tenant_id, accountant_party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT accountant_portal_accounts_status_chk CHECK (
        portal_status IN ('ACTIVE', 'PASSIVE', 'SUSPENDED', 'CANCELED', 'ARCHIVED')
    ),
    CONSTRAINT accountant_portal_accounts_onboarding_chk CHECK (
        onboarding_status IN ('DRAFT', 'INVITED', 'ACTIVE', 'REJECTED', 'COMPLETED')
    ),
    CONSTRAINT accountant_portal_accounts_export_format_chk CHECK (
        default_export_format IN ('XLSX', 'PDF', 'CSV', 'JSON', 'XML', 'ZIP')
    ),
    CONSTRAINT accountant_portal_accounts_package_chk CHECK (
        default_accounting_package IS NULL OR default_accounting_package IN ('TDHP', 'LOGO', 'MIKRO', 'ZIRVE', 'ETA', 'CUSTOM')
    ),
    CONSTRAINT accountant_portal_accounts_count_chk CHECK (
        max_assigned_company_count >= 0
        AND active_assigned_company_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.accountant_portal_users (
    tenant_id uuid NOT NULL,
    accountant_portal_user_id uuid NOT NULL DEFAULT gen_random_uuid(),
    accountant_account_id uuid NOT NULL,

    user_id uuid,
    user_email varchar(255) NOT NULL,
    display_name varchar(255) NOT NULL,

    portal_role varchar(64) NOT NULL DEFAULT 'ACCOUNTANT_USER',
    access_status varchar(40) NOT NULL DEFAULT 'INVITED',

    can_export boolean NOT NULL DEFAULT true,
    can_view_financials boolean NOT NULL DEFAULT true,
    can_view_e_belge boolean NOT NULL DEFAULT true,
    can_manage_assigned_companies boolean NOT NULL DEFAULT false,
    can_manage_subscription boolean NOT NULL DEFAULT false,

    invited_by uuid,
    invited_at timestamptz NOT NULL DEFAULT now(),
    accepted_at timestamptz,
    disabled_at timestamptz,

    last_login_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT accountant_portal_users_pk PRIMARY KEY (tenant_id, accountant_portal_user_id),
    CONSTRAINT accountant_portal_users_account_fk FOREIGN KEY (tenant_id, accountant_account_id)
        REFERENCES erp.accountant_portal_accounts (tenant_id, accountant_account_id)
        ON DELETE CASCADE,
    CONSTRAINT accountant_portal_users_email_unique UNIQUE (tenant_id, accountant_account_id, user_email),
    CONSTRAINT accountant_portal_users_role_chk CHECK (
        portal_role IN ('ACCOUNTANT_OWNER', 'ACCOUNTANT_ADMIN', 'ACCOUNTANT_USER', 'READ_ONLY', 'EXPORT_ONLY')
    ),
    CONSTRAINT accountant_portal_users_status_chk CHECK (
        access_status IN ('INVITED', 'ACTIVE', 'DISABLED', 'REVOKED', 'EXPIRED')
    )
);

CREATE TABLE IF NOT EXISTS erp.accountant_portal_subscriptions (
    tenant_id uuid NOT NULL,
    accountant_subscription_id uuid NOT NULL DEFAULT gen_random_uuid(),
    accountant_account_id uuid NOT NULL,

    subscription_no varchar(128) NOT NULL,

    plan_code varchar(96) NOT NULL,
    plan_name varchar(255) NOT NULL,

    subscription_status varchar(40) NOT NULL DEFAULT 'TRIALING',
    billing_period varchar(32) NOT NULL DEFAULT 'MONTHLY',

    starts_at date NOT NULL DEFAULT CURRENT_DATE,
    ends_at date,
    trial_ends_at date,

    monthly_base_price numeric(18,2) NOT NULL DEFAULT 0,
    company_unit_price numeric(18,2) NOT NULL DEFAULT 0,
    included_company_count integer NOT NULL DEFAULT 0,
    active_company_count integer NOT NULL DEFAULT 0,

    currency_code char(3) NOT NULL DEFAULT 'TRY',

    next_billing_date date,
    last_billing_date date,

    cancellation_reason text,
    canceled_by uuid,
    canceled_at timestamptz,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT accountant_portal_subscriptions_pk PRIMARY KEY (tenant_id, accountant_subscription_id),
    CONSTRAINT accountant_portal_subscriptions_account_fk FOREIGN KEY (tenant_id, accountant_account_id)
        REFERENCES erp.accountant_portal_accounts (tenant_id, accountant_account_id)
        ON DELETE CASCADE,
    CONSTRAINT accountant_portal_subscriptions_no_unique UNIQUE (tenant_id, subscription_no),
    CONSTRAINT accountant_portal_subscriptions_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT accountant_portal_subscriptions_status_chk CHECK (
        subscription_status IN ('TRIALING', 'ACTIVE', 'PAST_DUE', 'SUSPENDED', 'CANCELED', 'EXPIRED')
    ),
    CONSTRAINT accountant_portal_subscriptions_period_chk CHECK (
        billing_period IN ('MONTHLY', 'YEARLY', 'CUSTOM')
    ),
    CONSTRAINT accountant_portal_subscriptions_date_chk CHECK (
        ends_at IS NULL OR ends_at >= starts_at
    ),
    CONSTRAINT accountant_portal_subscriptions_amount_chk CHECK (
        monthly_base_price >= 0
        AND company_unit_price >= 0
        AND included_company_count >= 0
        AND active_company_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.accountant_portal_assigned_companies (
    tenant_id uuid NOT NULL,
    assigned_company_id uuid NOT NULL DEFAULT gen_random_uuid(),

    accountant_account_id uuid NOT NULL,
    accountant_subscription_id uuid,

    assigned_company_tenant_id uuid NOT NULL,
    assigned_company_party_id uuid,

    assigned_company_code varchar(128) NOT NULL,
    assigned_company_title varchar(255) NOT NULL,

    tax_identity_no varchar(32),
    tax_office varchar(128),

    assignment_status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    access_level varchar(64) NOT NULL DEFAULT 'READ_EXPORT',

    can_view_sales boolean NOT NULL DEFAULT true,
    can_view_procurement boolean NOT NULL DEFAULT true,
    can_view_inventory boolean NOT NULL DEFAULT true,
    can_view_payment boolean NOT NULL DEFAULT true,
    can_view_e_belge boolean NOT NULL DEFAULT true,
    can_export_accounting boolean NOT NULL DEFAULT true,
    can_export_ledger boolean NOT NULL DEFAULT true,

    assignment_start_date date NOT NULL DEFAULT CURRENT_DATE,
    assignment_end_date date,

    monthly_fee_amount numeric(18,2) NOT NULL DEFAULT 0,
    currency_code char(3) NOT NULL DEFAULT 'TRY',

    assigned_by uuid,
    assigned_at timestamptz NOT NULL DEFAULT now(),
    revoked_by uuid,
    revoked_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT accountant_portal_assigned_companies_pk PRIMARY KEY (tenant_id, assigned_company_id),
    CONSTRAINT accountant_portal_assigned_companies_account_fk FOREIGN KEY (tenant_id, accountant_account_id)
        REFERENCES erp.accountant_portal_accounts (tenant_id, accountant_account_id)
        ON DELETE CASCADE,
    CONSTRAINT accountant_portal_assigned_companies_subscription_fk FOREIGN KEY (tenant_id, accountant_subscription_id)
        REFERENCES erp.accountant_portal_subscriptions (tenant_id, accountant_subscription_id)
        ON DELETE SET NULL,
    CONSTRAINT accountant_portal_assigned_companies_party_fk FOREIGN KEY (tenant_id, assigned_company_party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT accountant_portal_assigned_companies_unique UNIQUE (tenant_id, accountant_account_id, assigned_company_tenant_id),
    CONSTRAINT accountant_portal_assigned_companies_status_chk CHECK (
        assignment_status IN ('ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED', 'ARCHIVED')
    ),
    CONSTRAINT accountant_portal_assigned_companies_access_chk CHECK (
        access_level IN ('READ_ONLY', 'READ_EXPORT', 'FULL_ACCOUNTING_VIEW', 'CUSTOM')
    ),
    CONSTRAINT accountant_portal_assigned_companies_date_chk CHECK (
        assignment_end_date IS NULL OR assignment_end_date >= assignment_start_date
    ),
    CONSTRAINT accountant_portal_assigned_companies_amount_chk CHECK (
        monthly_fee_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.accountant_portal_company_export_permissions (
    tenant_id uuid NOT NULL,
    export_permission_id uuid NOT NULL DEFAULT gen_random_uuid(),

    assigned_company_id uuid NOT NULL,
    accountant_account_id uuid NOT NULL,

    export_type varchar(64) NOT NULL,
    target_system varchar(64) NOT NULL,
    export_format varchar(32) NOT NULL,

    permission_status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    max_export_per_month integer NOT NULL DEFAULT 0,
    used_export_count integer NOT NULL DEFAULT 0,

    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT accountant_portal_company_export_permissions_pk PRIMARY KEY (tenant_id, export_permission_id),
    CONSTRAINT accountant_portal_company_export_permissions_company_fk FOREIGN KEY (tenant_id, assigned_company_id)
        REFERENCES erp.accountant_portal_assigned_companies (tenant_id, assigned_company_id)
        ON DELETE CASCADE,
    CONSTRAINT accountant_portal_company_export_permissions_account_fk FOREIGN KEY (tenant_id, accountant_account_id)
        REFERENCES erp.accountant_portal_accounts (tenant_id, accountant_account_id)
        ON DELETE CASCADE,
    CONSTRAINT accountant_portal_company_export_permissions_unique UNIQUE (
        tenant_id,
        assigned_company_id,
        export_type,
        target_system,
        export_format
    ),
    CONSTRAINT accountant_portal_company_export_permissions_type_chk CHECK (
        export_type IN ('ACCOUNTING_EXPORT', 'LEDGER_EXPORT', 'JOURNAL_EXPORT', 'SALES_EXPORT', 'PROCUREMENT_EXPORT', 'PAYMENT_EXPORT', 'E_BELGE_EXPORT', 'CUSTOM')
    ),
    CONSTRAINT accountant_portal_company_export_permissions_target_chk CHECK (
        target_system IN ('TDHP', 'LOGO', 'MIKRO', 'ZIRVE', 'ETA', 'EXCEL', 'PDF', 'CSV', 'JSON', 'XML', 'CUSTOM')
    ),
    CONSTRAINT accountant_portal_company_export_permissions_format_chk CHECK (
        export_format IN ('XLSX', 'PDF', 'CSV', 'JSON', 'XML', 'TXT', 'ZIP', 'CUSTOM')
    ),
    CONSTRAINT accountant_portal_company_export_permissions_status_chk CHECK (
        permission_status IN ('ACTIVE', 'PASSIVE', 'SUSPENDED', 'ARCHIVED')
    ),
    CONSTRAINT accountant_portal_company_export_permissions_count_chk CHECK (
        max_export_per_month >= 0
        AND used_export_count >= 0
    ),
    CONSTRAINT accountant_portal_company_export_permissions_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.accountant_portal_audit_events (
    tenant_id uuid NOT NULL,
    accountant_portal_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    accountant_account_id uuid,
    assigned_company_id uuid,
    accountant_subscription_id uuid,

    entity_name varchar(96) NOT NULL,
    entity_id uuid,

    audit_action varchar(64) NOT NULL,

    old_value jsonb,
    new_value jsonb,

    reason_code varchar(96),
    reason_message text,

    actor_user_id uuid,
    actor_role varchar(96),

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT accountant_portal_audit_events_pk PRIMARY KEY (tenant_id, accountant_portal_audit_event_id),
    CONSTRAINT accountant_portal_audit_events_account_fk FOREIGN KEY (tenant_id, accountant_account_id)
        REFERENCES erp.accountant_portal_accounts (tenant_id, accountant_account_id)
        ON DELETE SET NULL,
    CONSTRAINT accountant_portal_audit_events_company_fk FOREIGN KEY (tenant_id, assigned_company_id)
        REFERENCES erp.accountant_portal_assigned_companies (tenant_id, assigned_company_id)
        ON DELETE SET NULL,
    CONSTRAINT accountant_portal_audit_events_subscription_fk FOREIGN KEY (tenant_id, accountant_subscription_id)
        REFERENCES erp.accountant_portal_subscriptions (tenant_id, accountant_subscription_id)
        ON DELETE SET NULL,
    CONSTRAINT accountant_portal_audit_events_action_chk CHECK (
        audit_action IN (
            'CREATE_ACCOUNT',
            'UPDATE_ACCOUNT',
            'INVITE_USER',
            'DISABLE_USER',
            'CREATE_SUBSCRIPTION',
            'UPDATE_SUBSCRIPTION',
            'CANCEL_SUBSCRIPTION',
            'ASSIGN_COMPANY',
            'REVOKE_COMPANY',
            'GRANT_EXPORT_PERMISSION',
            'REVOKE_EXPORT_PERMISSION',
            'EXPORT_RUN',
            'SYSTEM_MIGRATION'
        )
    )
);

CREATE INDEX IF NOT EXISTS accountant_portal_accounts_status_idx
    ON erp.accountant_portal_accounts (tenant_id, portal_status, onboarding_status);

CREATE INDEX IF NOT EXISTS accountant_portal_accounts_tax_identity_idx
    ON erp.accountant_portal_accounts (tenant_id, tax_identity_no)
    WHERE tax_identity_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS accountant_portal_accounts_email_idx
    ON erp.accountant_portal_accounts (tenant_id, email)
    WHERE email IS NOT NULL;

CREATE INDEX IF NOT EXISTS accountant_portal_users_account_status_idx
    ON erp.accountant_portal_users (tenant_id, accountant_account_id, access_status);

CREATE INDEX IF NOT EXISTS accountant_portal_users_email_idx
    ON erp.accountant_portal_users (tenant_id, user_email);

CREATE INDEX IF NOT EXISTS accountant_portal_subscriptions_account_status_idx
    ON erp.accountant_portal_subscriptions (tenant_id, accountant_account_id, subscription_status);

CREATE INDEX IF NOT EXISTS accountant_portal_subscriptions_billing_idx
    ON erp.accountant_portal_subscriptions (tenant_id, next_billing_date, subscription_status);

CREATE INDEX IF NOT EXISTS accountant_portal_assigned_companies_account_status_idx
    ON erp.accountant_portal_assigned_companies (tenant_id, accountant_account_id, assignment_status);

CREATE INDEX IF NOT EXISTS accountant_portal_assigned_companies_company_tenant_idx
    ON erp.accountant_portal_assigned_companies (tenant_id, assigned_company_tenant_id);

CREATE INDEX IF NOT EXISTS accountant_portal_assigned_companies_party_idx
    ON erp.accountant_portal_assigned_companies (tenant_id, assigned_company_party_id);

CREATE INDEX IF NOT EXISTS accountant_portal_company_export_permissions_company_idx
    ON erp.accountant_portal_company_export_permissions (tenant_id, assigned_company_id, permission_status);

CREATE INDEX IF NOT EXISTS accountant_portal_company_export_permissions_target_idx
    ON erp.accountant_portal_company_export_permissions (tenant_id, export_type, target_system, export_format);

CREATE INDEX IF NOT EXISTS accountant_portal_audit_events_account_idx
    ON erp.accountant_portal_audit_events (tenant_id, accountant_account_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS accountant_portal_audit_events_company_idx
    ON erp.accountant_portal_audit_events (tenant_id, assigned_company_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS accountant_portal_audit_events_entity_idx
    ON erp.accountant_portal_audit_events (tenant_id, entity_name, entity_id, occurred_at DESC);

ALTER TABLE erp.accountant_portal_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_assigned_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_company_export_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.accountant_portal_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_users FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_subscriptions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_assigned_companies FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_company_export_permissions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.accountant_portal_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS accountant_portal_accounts_tenant_policy ON erp.accountant_portal_accounts;
CREATE POLICY accountant_portal_accounts_tenant_policy ON erp.accountant_portal_accounts
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS accountant_portal_users_tenant_policy ON erp.accountant_portal_users;
CREATE POLICY accountant_portal_users_tenant_policy ON erp.accountant_portal_users
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS accountant_portal_subscriptions_tenant_policy ON erp.accountant_portal_subscriptions;
CREATE POLICY accountant_portal_subscriptions_tenant_policy ON erp.accountant_portal_subscriptions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS accountant_portal_assigned_companies_tenant_policy ON erp.accountant_portal_assigned_companies;
CREATE POLICY accountant_portal_assigned_companies_tenant_policy ON erp.accountant_portal_assigned_companies
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS accountant_portal_company_export_permissions_tenant_policy ON erp.accountant_portal_company_export_permissions;
CREATE POLICY accountant_portal_company_export_permissions_tenant_policy ON erp.accountant_portal_company_export_permissions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS accountant_portal_audit_events_tenant_policy ON erp.accountant_portal_audit_events;
CREATE POLICY accountant_portal_audit_events_tenant_policy ON erp.accountant_portal_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.accountant_portal_accounts IS 'FAZ 3-9.13 accountant portal account table';
COMMENT ON TABLE erp.accountant_portal_users IS 'FAZ 3-9.13 accountant portal user table';
COMMENT ON TABLE erp.accountant_portal_subscriptions IS 'FAZ 3-9.13 accountant portal subscription table';
COMMENT ON TABLE erp.accountant_portal_assigned_companies IS 'FAZ 3-9.13 accountant portal assigned company table';
COMMENT ON TABLE erp.accountant_portal_company_export_permissions IS 'FAZ 3-9.13 accountant portal company export permission table';
COMMENT ON TABLE erp.accountant_portal_audit_events IS 'FAZ 3-9.13 accountant portal audit event table';

COMMIT;
