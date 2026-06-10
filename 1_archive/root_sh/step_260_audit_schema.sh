#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

cat <<'SQLEOF' > step_260_create_audit_tables.sql
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    actor_type TEXT NOT NULL,
    actor_id TEXT NOT NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    status TEXT NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
ON audit_logs (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action
ON audit_logs (action);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
ON audit_logs (entity_type, entity_id);
SQLEOF

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_260_create_audit_tables.sql

echo "OK ✅ audit schema hazir"
