BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'idempotency_status_enum'
  ) THEN
    CREATE TYPE runtime.idempotency_status_enum AS ENUM (
      'reserved',
      'processing',
      'completed',
      'failed',
      'expired'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'dedupe_status_enum'
  ) THEN
    CREATE TYPE runtime.dedupe_status_enum AS ENUM (
      'active',
      'released',
      'expired'
    );
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION runtime.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.touch_last_seen_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.last_seen_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS runtime.idempotency_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  scope_key text NOT NULL,
  idempotency_key text NOT NULL,
  request_fingerprint text,
  status runtime.idempotency_status_enum NOT NULL DEFAULT 'reserved',
  response_code integer,
  resource_type text,
  resource_id text,
  request_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  response_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  locked_by text,
  locked_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (scope_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (idempotency_key <> ''),
  CHECK (response_code IS NULL OR response_code BETWEEN 100 AND 599),
  CHECK (last_seen_at >= first_seen_at),
  CHECK (expires_at IS NULL OR expires_at >= first_seen_at),
  CHECK (locked_at IS NULL OR locked_at >= first_seen_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_idempotency_keys_tenant_scope_key
ON runtime.idempotency_keys (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  scope_key,
  idempotency_key
);

CREATE INDEX IF NOT EXISTS ix_idempotency_keys_tenant_id
ON runtime.idempotency_keys (tenant_id);

CREATE INDEX IF NOT EXISTS ix_idempotency_keys_status
ON runtime.idempotency_keys (status);

CREATE INDEX IF NOT EXISTS ix_idempotency_keys_expires_at
ON runtime.idempotency_keys (expires_at);

CREATE INDEX IF NOT EXISTS ix_idempotency_keys_fingerprint
ON runtime.idempotency_keys (request_fingerprint);

CREATE TABLE IF NOT EXISTS runtime.dedupe_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  dedupe_scope text NOT NULL,
  dedupe_key text NOT NULL,
  dedupe_hash text,
  status runtime.dedupe_status_enum NOT NULL DEFAULT 'active',
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  owner_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (dedupe_scope ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (dedupe_key <> ''),
  CHECK (last_seen_at >= first_seen_at),
  CHECK (expires_at IS NULL OR expires_at >= first_seen_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_dedupe_records_tenant_scope_key
ON runtime.dedupe_records (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  dedupe_scope,
  dedupe_key
);

CREATE INDEX IF NOT EXISTS ix_dedupe_records_tenant_id
ON runtime.dedupe_records (tenant_id);

CREATE INDEX IF NOT EXISTS ix_dedupe_records_status
ON runtime.dedupe_records (status);

CREATE INDEX IF NOT EXISTS ix_dedupe_records_expires_at
ON runtime.dedupe_records (expires_at);

CREATE INDEX IF NOT EXISTS ix_dedupe_records_hash
ON runtime.dedupe_records (dedupe_hash);

DROP TRIGGER IF EXISTS trg_idempotency_keys_touch_updated_at
ON runtime.idempotency_keys;

CREATE TRIGGER trg_idempotency_keys_touch_updated_at
BEFORE UPDATE ON runtime.idempotency_keys
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_idempotency_keys_touch_last_seen_at
ON runtime.idempotency_keys;

CREATE TRIGGER trg_idempotency_keys_touch_last_seen_at
BEFORE UPDATE ON runtime.idempotency_keys
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_last_seen_at();

DROP TRIGGER IF EXISTS trg_dedupe_records_touch_updated_at
ON runtime.dedupe_records;

CREATE TRIGGER trg_dedupe_records_touch_updated_at
BEFORE UPDATE ON runtime.dedupe_records
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_dedupe_records_touch_last_seen_at
ON runtime.dedupe_records;

CREATE TRIGGER trg_dedupe_records_touch_last_seen_at
BEFORE UPDATE ON runtime.dedupe_records
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_last_seen_at();

ALTER TABLE runtime.idempotency_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.idempotency_keys FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.dedupe_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.dedupe_records FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_idempotency_keys_select ON runtime.idempotency_keys;
CREATE POLICY p_idempotency_keys_select
ON runtime.idempotency_keys
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_idempotency_keys_insert ON runtime.idempotency_keys;
CREATE POLICY p_idempotency_keys_insert
ON runtime.idempotency_keys
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_idempotency_keys_update ON runtime.idempotency_keys;
CREATE POLICY p_idempotency_keys_update
ON runtime.idempotency_keys
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_idempotency_keys_delete ON runtime.idempotency_keys;
CREATE POLICY p_idempotency_keys_delete
ON runtime.idempotency_keys
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_dedupe_records_select ON runtime.dedupe_records;
CREATE POLICY p_dedupe_records_select
ON runtime.dedupe_records
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_dedupe_records_insert ON runtime.dedupe_records;
CREATE POLICY p_dedupe_records_insert
ON runtime.dedupe_records
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_dedupe_records_update ON runtime.dedupe_records;
CREATE POLICY p_dedupe_records_update
ON runtime.dedupe_records
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_dedupe_records_delete ON runtime.dedupe_records;
CREATE POLICY p_dedupe_records_delete
ON runtime.dedupe_records
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_app') THEN
    GRANT USAGE ON SCHEMA runtime TO pix2pi_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA runtime TO pix2pi_app;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA runtime TO pix2pi_app;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA runtime TO pix2pi_app;
  END IF;
END
$$;

COMMIT;
