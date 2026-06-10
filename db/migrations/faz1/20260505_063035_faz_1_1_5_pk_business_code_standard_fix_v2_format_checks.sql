BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS app_standard;

CREATE OR REPLACE FUNCTION app_standard.normalize_business_code(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT regexp_replace(upper(coalesce(input_text, '')), '[^A-Z0-9_-]', '_', 'g');
$$;

CREATE OR REPLACE FUNCTION app_standard.generate_business_code(prefix text, source_id uuid DEFAULT gen_random_uuid())
RETURNS text
LANGUAGE sql
VOLATILE
AS $$
  SELECT left(app_standard.normalize_business_code(coalesce(prefix, 'CODE')), 16)
         || '_'
         || substr(replace(coalesce(source_id, gen_random_uuid())::text, '-', ''), 1, 12);
$$;

DO $$
DECLARE
  r record;
  ck_name text;
  prefix text;
  invalid_count bigint;
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
    prefix := left(app_standard.normalize_business_code(r.table_name), 16);
    ck_name := left('ck_' || r.table_schema || '_' || r.table_name || '_business_code_format', 52)
               || '_'
               || substr(md5(r.table_schema || '.' || r.table_name || '.business_code_format'), 1, 8);

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='business_code'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN business_code text', r.table_schema, r.table_name);
    END IF;

    EXECUTE format(
      'UPDATE %I.%I
       SET business_code = app_standard.generate_business_code(%L, gen_random_uuid())
       WHERE business_code IS NULL
          OR btrim(business_code) = ''''
          OR business_code !~ %L',
      r.table_schema,
      r.table_name,
      prefix,
      '^[A-Z0-9][A-Z0-9_-]{1,127}$'
    );

    EXECUTE format(
      'SELECT count(*) FROM %I.%I
       WHERE business_code IS NULL
          OR btrim(business_code) = ''''
          OR business_code !~ %L',
      r.table_schema,
      r.table_name,
      '^[A-Z0-9][A-Z0-9_-]{1,127}$'
    )
    INTO invalid_count;

    IF invalid_count > 0 THEN
      RAISE NOTICE 'business_code invalid rows still exist for %.% count=%', r.table_schema, r.table_name, invalid_count;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_constraint con
      JOIN pg_class cls ON cls.oid=con.conrelid
      JOIN pg_namespace ns ON ns.oid=cls.relnamespace
      WHERE ns.nspname=r.table_schema
        AND cls.relname=r.table_name
        AND con.contype='c'
        AND pg_get_constraintdef(con.oid) ILIKE '%business_code%'
    ) THEN
      BEGIN
        EXECUTE format(
          'ALTER TABLE %I.%I ADD CONSTRAINT %I CHECK (business_code IS NULL OR business_code ~ %L) NOT VALID',
          r.table_schema,
          r.table_name,
          ck_name,
          '^[A-Z0-9][A-Z0-9_-]{1,127}$'
        );
      EXCEPTION WHEN duplicate_object THEN
        NULL;
      WHEN others THEN
        RAISE NOTICE 'business_code format check add skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
      END;
    END IF;
  END LOOP;
END $$;

GRANT USAGE ON SCHEMA app_standard TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.normalize_business_code(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.generate_business_code(text, uuid) TO PUBLIC;

COMMIT;
