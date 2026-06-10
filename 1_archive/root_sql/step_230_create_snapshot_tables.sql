CREATE TABLE IF NOT EXISTS snapshots (
    id SERIAL PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    version INT NOT NULL DEFAULT 1,
    state JSONB NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_snapshots_unique_aggregate
ON snapshots (tenant_id, aggregate_type, aggregate_id);
