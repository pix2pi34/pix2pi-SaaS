BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.master_parties (
    tenant_id uuid NOT NULL,
    party_id uuid NOT NULL DEFAULT gen_random_uuid(),

    party_code varchar(96) NOT NULL,
    party_type varchar(40) NOT NULL,

    legal_title varchar(255) NOT NULL,
    trade_name varchar(255),

    tax_identity_no varchar(32),
    tax_office varchar(128),
    mersis_no varchar(64),

    phone varchar(64),
    email varchar(255),

    country_code char(2) NOT NULL DEFAULT 'TR',
    city varchar(128),
    district varchar(128),

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    source_channel varchar(64) NOT NULL DEFAULT 'ERP',

    notes text,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT master_parties_pk PRIMARY KEY (tenant_id, party_id),
    CONSTRAINT master_parties_code_unique UNIQUE (tenant_id, party_code),
    CONSTRAINT master_parties_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT master_parties_party_type_chk CHECK (
        party_type IN ('CUSTOMER', 'VENDOR', 'CUSTOMER_VENDOR', 'CONTACT', 'EMPLOYEE', 'BANK', 'TAX_AUTHORITY', 'OTHER')
    ),
    CONSTRAINT master_parties_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'BLOCKED', 'ARCHIVED')
    )
);

CREATE TABLE IF NOT EXISTS erp.master_customers (
    tenant_id uuid NOT NULL,
    customer_id uuid NOT NULL DEFAULT gen_random_uuid(),
    party_id uuid NOT NULL,

    customer_code varchar(96) NOT NULL,
    customer_group_code varchar(96),

    customer_type varchar(40) NOT NULL DEFAULT 'COMMERCIAL',
    credit_limit numeric(18, 2) NOT NULL DEFAULT 0,
    risk_limit numeric(18, 2) NOT NULL DEFAULT 0,

    payment_term_days integer NOT NULL DEFAULT 0,
    default_currency_code char(3) NOT NULL DEFAULT 'TRY',

    e_invoice_enabled boolean NOT NULL DEFAULT false,
    e_archive_enabled boolean NOT NULL DEFAULT false,

    default_receivable_account_code varchar(32),
    default_revenue_account_code varchar(32),

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT master_customers_pk PRIMARY KEY (tenant_id, customer_id),
    CONSTRAINT master_customers_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE CASCADE,
    CONSTRAINT master_customers_code_unique UNIQUE (tenant_id, customer_code),
    CONSTRAINT master_customers_party_unique UNIQUE (tenant_id, party_id),
    CONSTRAINT master_customers_type_chk CHECK (
        customer_type IN ('COMMERCIAL', 'INDIVIDUAL', 'MARKETPLACE_BUYER', 'PUBLIC', 'OTHER')
    ),
    CONSTRAINT master_customers_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'BLOCKED', 'ARCHIVED')
    ),
    CONSTRAINT master_customers_amount_chk CHECK (
        credit_limit >= 0
        AND risk_limit >= 0
        AND payment_term_days >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.master_vendors (
    tenant_id uuid NOT NULL,
    vendor_id uuid NOT NULL DEFAULT gen_random_uuid(),
    party_id uuid NOT NULL,

    vendor_code varchar(96) NOT NULL,
    vendor_group_code varchar(96),

    vendor_type varchar(40) NOT NULL DEFAULT 'COMMERCIAL',
    payment_term_days integer NOT NULL DEFAULT 0,
    default_currency_code char(3) NOT NULL DEFAULT 'TRY',

    e_invoice_enabled boolean NOT NULL DEFAULT false,
    e_archive_enabled boolean NOT NULL DEFAULT false,

    default_payable_account_code varchar(32),
    default_expense_account_code varchar(32),

    procurement_enabled boolean NOT NULL DEFAULT true,
    return_enabled boolean NOT NULL DEFAULT true,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT master_vendors_pk PRIMARY KEY (tenant_id, vendor_id),
    CONSTRAINT master_vendors_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE CASCADE,
    CONSTRAINT master_vendors_code_unique UNIQUE (tenant_id, vendor_code),
    CONSTRAINT master_vendors_party_unique UNIQUE (tenant_id, party_id),
    CONSTRAINT master_vendors_type_chk CHECK (
        vendor_type IN ('COMMERCIAL', 'INDIVIDUAL', 'SUPPLIER', 'SERVICE_PROVIDER', 'PUBLIC', 'OTHER')
    ),
    CONSTRAINT master_vendors_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'BLOCKED', 'ARCHIVED')
    ),
    CONSTRAINT master_vendors_payment_term_chk CHECK (
        payment_term_days >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.master_contacts (
    tenant_id uuid NOT NULL,
    contact_id uuid NOT NULL DEFAULT gen_random_uuid(),

    party_id uuid,

    contact_code varchar(96) NOT NULL,
    contact_type varchar(40) NOT NULL DEFAULT 'GENERAL',

    first_name varchar(128),
    last_name varchar(128),
    display_name varchar(255) NOT NULL,

    title varchar(128),
    department varchar(128),

    phone varchar(64),
    mobile_phone varchar(64),
    email varchar(255),

    is_primary boolean NOT NULL DEFAULT false,
    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT master_contacts_pk PRIMARY KEY (tenant_id, contact_id),
    CONSTRAINT master_contacts_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT master_contacts_code_unique UNIQUE (tenant_id, contact_code),
    CONSTRAINT master_contacts_type_chk CHECK (
        contact_type IN ('GENERAL', 'BILLING', 'SHIPPING', 'PROCUREMENT', 'SALES', 'ACCOUNTING', 'TECHNICAL', 'OTHER')
    ),
    CONSTRAINT master_contacts_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    )
);

CREATE TABLE IF NOT EXISTS erp.master_addresses (
    tenant_id uuid NOT NULL,
    address_id uuid NOT NULL DEFAULT gen_random_uuid(),

    party_id uuid,

    address_code varchar(96) NOT NULL,
    address_type varchar(40) NOT NULL DEFAULT 'GENERAL',

    title varchar(255),

    country_code char(2) NOT NULL DEFAULT 'TR',
    city varchar(128) NOT NULL,
    district varchar(128),
    neighborhood varchar(128),

    address_line1 text NOT NULL,
    address_line2 text,
    postal_code varchar(32),

    tax_office varchar(128),

    latitude numeric(12, 8),
    longitude numeric(12, 8),

    is_primary boolean NOT NULL DEFAULT false,
    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT master_addresses_pk PRIMARY KEY (tenant_id, address_id),
    CONSTRAINT master_addresses_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT master_addresses_code_unique UNIQUE (tenant_id, address_code),
    CONSTRAINT master_addresses_type_chk CHECK (
        address_type IN ('GENERAL', 'BILLING', 'SHIPPING', 'INVOICE', 'WAREHOUSE', 'BRANCH', 'OTHER')
    ),
    CONSTRAINT master_addresses_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    )
);

CREATE TABLE IF NOT EXISTS erp.master_party_audit_events (
    tenant_id uuid NOT NULL,
    party_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    party_id uuid,
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

    CONSTRAINT master_party_audit_events_pk PRIMARY KEY (tenant_id, party_audit_event_id),
    CONSTRAINT master_party_audit_events_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT master_party_audit_events_action_chk CHECK (
        audit_action IN ('CREATE', 'UPDATE', 'BLOCK', 'UNBLOCK', 'ARCHIVE', 'MERGE', 'SYSTEM_MIGRATION')
    )
);

CREATE INDEX IF NOT EXISTS master_parties_type_status_idx
    ON erp.master_parties (tenant_id, party_type, status);

CREATE INDEX IF NOT EXISTS master_parties_tax_identity_idx
    ON erp.master_parties (tenant_id, tax_identity_no)
    WHERE tax_identity_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS master_parties_email_idx
    ON erp.master_parties (tenant_id, email)
    WHERE email IS NOT NULL;

CREATE INDEX IF NOT EXISTS master_customers_party_idx
    ON erp.master_customers (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS master_customers_group_status_idx
    ON erp.master_customers (tenant_id, customer_group_code, status);

CREATE INDEX IF NOT EXISTS master_vendors_party_idx
    ON erp.master_vendors (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS master_vendors_group_status_idx
    ON erp.master_vendors (tenant_id, vendor_group_code, status);

CREATE INDEX IF NOT EXISTS master_contacts_party_idx
    ON erp.master_contacts (tenant_id, party_id, is_primary);

CREATE INDEX IF NOT EXISTS master_contacts_email_idx
    ON erp.master_contacts (tenant_id, email)
    WHERE email IS NOT NULL;

CREATE INDEX IF NOT EXISTS master_addresses_party_idx
    ON erp.master_addresses (tenant_id, party_id, address_type, is_primary);

CREATE INDEX IF NOT EXISTS master_addresses_city_idx
    ON erp.master_addresses (tenant_id, city, district);

CREATE INDEX IF NOT EXISTS master_party_audit_events_party_idx
    ON erp.master_party_audit_events (tenant_id, party_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS master_party_audit_events_entity_idx
    ON erp.master_party_audit_events (tenant_id, entity_name, entity_id, occurred_at DESC);

ALTER TABLE erp.master_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.master_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.master_vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.master_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.master_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.master_party_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.master_parties FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.master_customers FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.master_vendors FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.master_contacts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.master_addresses FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.master_party_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS master_parties_tenant_policy ON erp.master_parties;
CREATE POLICY master_parties_tenant_policy ON erp.master_parties
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS master_customers_tenant_policy ON erp.master_customers;
CREATE POLICY master_customers_tenant_policy ON erp.master_customers
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS master_vendors_tenant_policy ON erp.master_vendors;
CREATE POLICY master_vendors_tenant_policy ON erp.master_vendors
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS master_contacts_tenant_policy ON erp.master_contacts;
CREATE POLICY master_contacts_tenant_policy ON erp.master_contacts
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS master_addresses_tenant_policy ON erp.master_addresses;
CREATE POLICY master_addresses_tenant_policy ON erp.master_addresses
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS master_party_audit_events_tenant_policy ON erp.master_party_audit_events;
CREATE POLICY master_party_audit_events_tenant_policy ON erp.master_party_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.master_parties IS 'FAZ 3-9.1 master party base table';
COMMENT ON TABLE erp.master_customers IS 'FAZ 3-9.1 customer master table';
COMMENT ON TABLE erp.master_vendors IS 'FAZ 3-9.1 vendor master table';
COMMENT ON TABLE erp.master_contacts IS 'FAZ 3-9.1 contact master table';
COMMENT ON TABLE erp.master_addresses IS 'FAZ 3-9.1 address master table';
COMMENT ON TABLE erp.master_party_audit_events IS 'FAZ 3-9.1 master party audit event table';

COMMIT;
