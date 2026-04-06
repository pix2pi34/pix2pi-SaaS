-- 0001_init.up.sql
-- Identity minimum schema
-- NOT: id column'lar BIGSERIAL (deterministic basit başlangıç)

BEGIN;

CREATE TABLE IF NOT EXISTS tenants (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
  id          BIGSERIAL PRIMARY KEY,
  tenant_id   BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'user',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, email)
);

CREATE TABLE IF NOT EXISTS roles (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS role_permissions (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  permission  TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (name, permission)
);

-- Seed (idempotent)
INSERT INTO tenants (name)
VALUES ('default')
ON CONFLICT (name) DO NOTHING;

INSERT INTO roles (name)
VALUES ('admin'), ('user')
ON CONFLICT (name) DO NOTHING;

INSERT INTO role_permissions (name, permission)
VALUES
  ('admin', 'identity:rbac:admin'),
  ('admin', 'identity:whoami:read'),
  ('user',  'identity:whoami:read')
ON CONFLICT (name, permission) DO NOTHING;

-- default tenant altında bir user seed (idempotent)
INSERT INTO users (tenant_id, email, role)
SELECT t.id, 'ceo@tellioglu.local', 'user'
FROM tenants t
WHERE t.name='default'
ON CONFLICT (tenant_id, email) DO NOTHING;

COMMIT;
