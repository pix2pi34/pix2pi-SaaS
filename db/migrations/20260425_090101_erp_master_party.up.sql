-- FAZ 3 / 9.1.1
-- ERP Türkiye canlı çekirdeği
-- Master Party tabloları:
-- parties, customers, vendors, contacts, addresses
--
-- Not:
-- Customer ve vendor ayrı iş kimlikleri olarak tutulur.
-- Ortak gerçek/tüzel kişi bilgisi erp_parties üstünden yönetilir.
-- Bu yapı ileride cari, muhasebe, e-belge, CRM ve tedarik zinciri için genişleyebilir.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_parties (
    party_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    party_type TEXT NOT NULL,
    display_name TEXT NOT NULL,
    legal_name TEXT,
    trade_name TEXT,

    tax_no TEXT,
    tax_office TEXT,
    mersis_no TEXT,

    phone TEXT,
    email TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    source TEXT NOT NULL DEFAULT 'manual',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_parties_party_type_chk
        CHECK (party_type IN ('person', 'organization')),

    CONSTRAINT erp_parties_status_chk
        CHECK (status IN ('active', 'passive', 'blocked', 'deleted')),

    CONSTRAINT erp_parties_email_basic_chk
        CHECK (email IS NULL OR position('@' IN email) > 1)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_parties_tenant_tax_no
    ON erp_parties (tenant_id, tax_no)
    WHERE tax_no IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_parties_tenant_display_name
    ON erp_parties (tenant_id, display_name);

CREATE INDEX IF NOT EXISTS ix_erp_parties_tenant_status
    ON erp_parties (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    customer_code TEXT NOT NULL,
    customer_group TEXT,

    credit_limit NUMERIC(18, 2) NOT NULL DEFAULT 0,
    payment_terms_days INTEGER NOT NULL DEFAULT 0,

    currency_code TEXT NOT NULL DEFAULT 'TRY',

    is_credit_allowed BOOLEAN NOT NULL DEFAULT true,
    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_customers_status_chk
        CHECK (status IN ('active', 'passive', 'blocked', 'deleted')),

    CONSTRAINT erp_customers_payment_terms_chk
        CHECK (payment_terms_days >= 0),

    CONSTRAINT erp_customers_credit_limit_chk
        CHECK (credit_limit >= 0),

    CONSTRAINT erp_customers_currency_code_chk
        CHECK (char_length(currency_code) = 3)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_customers_tenant_code
    ON erp_customers (tenant_id, customer_code)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_customers_tenant_party
    ON erp_customers (tenant_id, party_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_customers_tenant_status
    ON erp_customers (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_vendors (
    vendor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE RESTRICT,

    vendor_code TEXT NOT NULL,
    vendor_group TEXT,

    payment_terms_days INTEGER NOT NULL DEFAULT 0,
    currency_code TEXT NOT NULL DEFAULT 'TRY',

    is_purchase_allowed BOOLEAN NOT NULL DEFAULT true,
    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_vendors_status_chk
        CHECK (status IN ('active', 'passive', 'blocked', 'deleted')),

    CONSTRAINT erp_vendors_payment_terms_chk
        CHECK (payment_terms_days >= 0),

    CONSTRAINT erp_vendors_currency_code_chk
        CHECK (char_length(currency_code) = 3)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_vendors_tenant_code
    ON erp_vendors (tenant_id, vendor_code)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_vendors_tenant_party
    ON erp_vendors (tenant_id, party_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_vendors_tenant_status
    ON erp_vendors (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_contacts (
    contact_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE CASCADE,

    full_name TEXT NOT NULL,
    title TEXT,
    department TEXT,

    phone TEXT,
    mobile_phone TEXT,
    email TEXT,

    is_primary BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_contacts_status_chk
        CHECK (status IN ('active', 'passive', 'deleted')),

    CONSTRAINT erp_contacts_email_basic_chk
        CHECK (email IS NULL OR position('@' IN email) > 1)
);

CREATE INDEX IF NOT EXISTS ix_erp_contacts_tenant_party
    ON erp_contacts (tenant_id, party_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_contacts_one_primary_per_party
    ON erp_contacts (tenant_id, party_id)
    WHERE is_primary = true AND deleted_at IS NULL;


CREATE TABLE IF NOT EXISTS erp_addresses (
    address_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,
    party_id UUID NOT NULL REFERENCES erp_parties(party_id) ON DELETE CASCADE,

    address_type TEXT NOT NULL DEFAULT 'general',

    country_code TEXT NOT NULL DEFAULT 'TR',
    city TEXT NOT NULL,
    district TEXT,
    neighborhood TEXT,

    address_line1 TEXT NOT NULL,
    address_line2 TEXT,

    postal_code TEXT,

    is_primary BOOLEAN NOT NULL DEFAULT false,
    is_invoice_address BOOLEAN NOT NULL DEFAULT false,
    is_delivery_address BOOLEAN NOT NULL DEFAULT false,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_addresses_type_chk
        CHECK (address_type IN ('general', 'invoice', 'delivery', 'warehouse', 'branch')),

    CONSTRAINT erp_addresses_status_chk
        CHECK (status IN ('active', 'passive', 'deleted')),

    CONSTRAINT erp_addresses_country_code_chk
        CHECK (char_length(country_code) = 2)
);

CREATE INDEX IF NOT EXISTS ix_erp_addresses_tenant_party
    ON erp_addresses (tenant_id, party_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_addresses_one_primary_per_party
    ON erp_addresses (tenant_id, party_id)
    WHERE is_primary = true AND deleted_at IS NULL;


ALTER TABLE erp_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_addresses ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_parties FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_customers FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_vendors FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_contacts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_addresses FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_parties_tenant_isolation_policy
    ON erp_parties
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_customers_tenant_isolation_policy
    ON erp_customers
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_vendors_tenant_isolation_policy
    ON erp_vendors
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_contacts_tenant_isolation_policy
    ON erp_contacts
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_addresses_tenant_isolation_policy
    ON erp_addresses
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
