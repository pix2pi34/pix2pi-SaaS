CREATE TABLE IF NOT EXISTS erp_runtime_flows (
    flow_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id text NOT NULL,
    request_id text NOT NULL,

    transaction_kind text NOT NULL CHECK (
        transaction_kind IN (
            'sales_invoice',
            'purchase_invoice',
            'cash_receipt',
            'cash_payment'
        )
    ),

    source_module text NOT NULL,
    source_document_type text NOT NULL,
    source_document_id text NULL,
    source_document_no text NULL,

    total_amount numeric(18, 2) NOT NULL CHECK (total_amount > 0),
    currency_code text NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 6) NOT NULL DEFAULT 1 CHECK (exchange_rate > 0),

    idempotency_key text NOT NULL,
    correlation_id text NULL,

    flow_status text NOT NULL DEFAULT 'draft' CHECK (
        flow_status IN (
            'draft',
            'running',
            'completed',
            'failed'
        )
    ),

    description text NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    started_at timestamptz NULL,
    completed_at timestamptz NULL,
    failed_at timestamptz NULL,
    failure_reason text NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz NULL,

    created_by text NULL,
    updated_by text NULL,

    CONSTRAINT erp_runtime_flows_source_presence_chk CHECK (
        source_document_id IS NOT NULL OR source_document_no IS NOT NULL
    ),

    CONSTRAINT erp_runtime_flows_idempotency_uniq UNIQUE (
        tenant_id,
        idempotency_key
    )
);

CREATE INDEX IF NOT EXISTS idx_erp_runtime_flows_tenant_status
    ON erp_runtime_flows (tenant_id, flow_status)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_erp_runtime_flows_tenant_source
    ON erp_runtime_flows (tenant_id, source_module, source_document_type, source_document_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_erp_runtime_flows_correlation
    ON erp_runtime_flows (tenant_id, correlation_id)
    WHERE deleted_at IS NULL AND correlation_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS erp_runtime_flow_steps (
    flow_step_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id text NOT NULL,
    flow_id uuid NOT NULL REFERENCES erp_runtime_flows(flow_id) ON DELETE CASCADE,

    step_no integer NOT NULL CHECK (step_no > 0),

    step_kind text NOT NULL CHECK (
        step_kind IN (
            'validate_request',
            'persist_document',
            'calculate_tax',
            'cashbank_payment',
            'post_journal',
            'post_ledger',
            'publish_event'
        )
    ),

    step_status text NOT NULL DEFAULT 'pending' CHECK (
        step_status IN (
            'pending',
            'running',
            'completed',
            'failed',
            'skipped'
        )
    ),

    message text NULL,
    failure_reason text NULL,

    started_at timestamptz NULL,
    completed_at timestamptz NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz NULL,

    created_by text NULL,
    updated_by text NULL,

    CONSTRAINT erp_runtime_flow_steps_step_uniq UNIQUE (
        tenant_id,
        flow_id,
        step_no
    )
);

CREATE INDEX IF NOT EXISTS idx_erp_runtime_flow_steps_tenant_flow
    ON erp_runtime_flow_steps (tenant_id, flow_id, step_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_erp_runtime_flow_steps_tenant_status
    ON erp_runtime_flow_steps (tenant_id, step_status)
    WHERE deleted_at IS NULL;

ALTER TABLE erp_runtime_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_runtime_flows FORCE ROW LEVEL SECURITY;

ALTER TABLE erp_runtime_flow_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_runtime_flow_steps FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS erp_runtime_flows_tenant_isolation ON erp_runtime_flows;
CREATE POLICY erp_runtime_flows_tenant_isolation
ON erp_runtime_flows
USING (tenant_id = current_setting('app.tenant_id', true))
WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS erp_runtime_flow_steps_tenant_isolation ON erp_runtime_flow_steps;
CREATE POLICY erp_runtime_flow_steps_tenant_isolation
ON erp_runtime_flow_steps
USING (tenant_id = current_setting('app.tenant_id', true))
WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
