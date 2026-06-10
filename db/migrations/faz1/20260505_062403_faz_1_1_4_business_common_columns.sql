BEGIN;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
    ORDER BY table_schema, table_name
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='tenant_id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN tenant_id uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='legal_entity_id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN legal_entity_id uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='branch_id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN branch_id uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='created_at'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN created_at timestamptz NOT NULL DEFAULT now()', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='updated_at'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now()', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='created_by'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN created_by uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='updated_by'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN updated_by uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='deleted_at'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN deleted_at timestamptz', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='audit_metadata'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN audit_metadata jsonb NOT NULL DEFAULT ''{}''::jsonb', r.table_schema, r.table_name);
    END IF;
  END LOOP;
END $$;

COMMIT;
