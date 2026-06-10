CREATE TABLE IF NOT EXISTS event_store (
    id SERIAL PRIMARY KEY,
    event_id TEXT,
    event_type TEXT,
    subject TEXT,
    payload JSONB,
    tenant_id TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
