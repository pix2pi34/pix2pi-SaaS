CREATE SCHEMA IF NOT EXISTS search_projection;

CREATE TABLE IF NOT EXISTS search_projection.party_search_documents (
    party_search_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL,
    party_code text,
    display_name text NOT NULL,
    tax_no text,
    email text,
    phone text,
    city text,
    district text,
    search_text text NOT NULL,
    search_keywords text[] NOT NULL DEFAULT ARRAY[]::text[],
    source_updated_at timestamptz,
    indexed_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, entity_type, entity_id)
);

CREATE TABLE IF NOT EXISTS search_projection.product_search_documents (
    product_search_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL DEFAULT 'product',
    product_code text,
    sku text,
    barcode text,
    product_name text NOT NULL,
    category_code text,
    unit_code text,
    tax_rate_code text,
    search_text text NOT NULL,
    search_keywords text[] NOT NULL DEFAULT ARRAY[]::text[],
    source_updated_at timestamptz,
    indexed_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, entity_type, entity_id)
);

CREATE TABLE IF NOT EXISTS search_projection.inventory_search_documents (
    inventory_search_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL DEFAULT 'inventory_balance',
    product_code text NOT NULL,
    location_code text NOT NULL,
    stock_status text NOT NULL DEFAULT 'unknown',
    quantity numeric(18,4) NOT NULL DEFAULT 0,
    reserved_quantity numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity numeric(18,4) NOT NULL DEFAULT 0,
    search_text text NOT NULL,
    search_keywords text[] NOT NULL DEFAULT ARRAY[]::text[],
    source_updated_at timestamptz,
    indexed_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, entity_type, entity_id)
);

CREATE TABLE IF NOT EXISTS search_projection.business_document_search_documents (
    business_document_search_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL,
    document_no text,
    document_type text NOT NULL,
    document_status text NOT NULL DEFAULT 'unknown',
    party_code text,
    document_date date,
    period_key text,
    gross_amount numeric(18,4) NOT NULL DEFAULT 0,
    tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    net_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    search_text text NOT NULL,
    search_keywords text[] NOT NULL DEFAULT ARRAY[]::text[],
    source_updated_at timestamptz,
    indexed_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, entity_type, entity_id)
);

CREATE TABLE IF NOT EXISTS search_projection.finance_search_documents (
    finance_search_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL,
    journal_no text,
    account_code text,
    account_name text,
    period_key text,
    document_no text,
    debit_amount numeric(18,4) NOT NULL DEFAULT 0,
    credit_amount numeric(18,4) NOT NULL DEFAULT 0,
    balance_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    search_text text NOT NULL,
    search_keywords text[] NOT NULL DEFAULT ARRAY[]::text[],
    source_updated_at timestamptz,
    indexed_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, entity_type, entity_id)
);

CREATE TABLE IF NOT EXISTS search_projection.global_search_documents (
    global_search_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL,
    entity_group text NOT NULL,
    title text NOT NULL,
    subtitle text,
    route_key text,
    route_params jsonb NOT NULL DEFAULT '{}'::jsonb,
    priority_score numeric(9,4) NOT NULL DEFAULT 0,
    search_text text NOT NULL,
    search_keywords text[] NOT NULL DEFAULT ARRAY[]::text[],
    source_updated_at timestamptz,
    indexed_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, entity_group, entity_type, entity_id)
);

CREATE TABLE IF NOT EXISTS search_projection.search_projection_rebuild_state (
    search_projection_rebuild_state_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    projection_key text NOT NULL,
    rebuild_status text NOT NULL DEFAULT 'idle',
    last_cursor text,
    last_entity_id text,
    processed_count integer NOT NULL DEFAULT 0 CHECK (processed_count >= 0),
    failed_count integer NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
    last_error_code text,
    last_error_message text,
    started_at timestamptz,
    finished_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now(),
    rebuild_version integer NOT NULL DEFAULT 1,
    UNIQUE (tenant_id, projection_key)
);

CREATE INDEX IF NOT EXISTS idx_party_search_tenant_entity
    ON search_projection.party_search_documents (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_party_search_tenant_name
    ON search_projection.party_search_documents (tenant_id, display_name);

CREATE INDEX IF NOT EXISTS idx_product_search_tenant_entity
    ON search_projection.product_search_documents (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_product_search_tenant_code
    ON search_projection.product_search_documents (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_product_search_tenant_barcode
    ON search_projection.product_search_documents (tenant_id, barcode);

CREATE INDEX IF NOT EXISTS idx_inventory_search_tenant_entity
    ON search_projection.inventory_search_documents (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_inventory_search_tenant_product_location
    ON search_projection.inventory_search_documents (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_document_search_tenant_entity
    ON search_projection.business_document_search_documents (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_document_search_tenant_date
    ON search_projection.business_document_search_documents (tenant_id, document_date);

CREATE INDEX IF NOT EXISTS idx_document_search_tenant_no
    ON search_projection.business_document_search_documents (tenant_id, document_no);

CREATE INDEX IF NOT EXISTS idx_finance_search_tenant_entity
    ON search_projection.finance_search_documents (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_finance_search_tenant_account
    ON search_projection.finance_search_documents (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS idx_global_search_tenant_entity
    ON search_projection.global_search_documents (tenant_id, entity_group, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_global_search_tenant_title
    ON search_projection.global_search_documents (tenant_id, title);

CREATE INDEX IF NOT EXISTS idx_rebuild_state_tenant_projection
    ON search_projection.search_projection_rebuild_state (tenant_id, projection_key);
