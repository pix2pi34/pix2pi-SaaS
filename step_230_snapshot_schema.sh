#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

cat <<'SQLEOF' > step_230_create_snapshot_tables.sql
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
SQLEOF

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_230_create_snapshot_tables.sql

echo "OK ✅ snapshot tablo hazir"
