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
  pk_count int;
  id_type text;
  pk_name text;
  ux_name text;
  ck_name text;
  prefix text;
  duplicate_count int;
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
    pk_name := left('pk_' || r.table_schema || '_' || r.table_name, 52) || '_' || substr(md5(r.table_schema || '.' || r.table_name || '.pk'), 1, 8);
    ux_name := left('ux_' || r.table_schema || '_' || r.table_name || '_tenant_business_code', 52) || '_' || substr(md5(r.table_schema || '.' || r.table_name || '.tenant_business_code'), 1, 8);
    ck_name := left('ck_' || r.table_schema || '_' || r.table_name || '_business_code_format', 52) || '_' || substr(md5(r.table_schema || '.' || r.table_name || '.business_code_format'), 1, 8);
    prefix := left(app_standard.normalize_business_code(r.table_name), 16);

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN id uuid', r.table_schema, r.table_name);
    END IF;

    SELECT data_type
    INTO id_type
    FROM information_schema.columns
    WHERE table_schema=r.table_schema
      AND table_name=r.table_name
      AND column_name='id'
    LIMIT 1;

    IF id_type='uuid' THEN
      EXECUTE format('UPDATE %I.%I SET id=gen_random_uuid() WHERE id IS NULL', r.table_schema, r.table_name);
      EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN id SET DEFAULT gen_random_uuid()', r.table_schema, r.table_name);

      BEGIN
        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN id SET NOT NULL', r.table_schema, r.table_name);
      EXCEPTION WHEN others THEN
        RAISE NOTICE 'id not-null skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
      END;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='business_code'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN business_code text', r.table_schema, r.table_name);
    END IF;

    IF id_type='uuid' THEN
      EXECUTE format(
        'UPDATE %I.%I SET business_code = app_standard.generate_business_code(%L, id) WHERE business_code IS NULL OR btrim(business_code) = ''''',
        r.table_schema,
        r.table_name,
        prefix
      );
    ELSE
      EXECUTE format(
        'UPDATE %I.%I SET business_code = app_standard.generate_business_code(%L, gen_random_uuid()) WHERE business_code IS NULL OR btrim(business_code) = ''''',
        r.table_schema,
        r.table_name,
        prefix
      );
    END IF;

    IF EXISTS (
      SELECT 1
      FROM information_schema.table_constraints tc
      WHERE tc.table_schema=r.table_schema
        AND tc.table_name=r.table_name
        AND tc.constraint_type='PRIMARY KEY'
    ) THEN
      -- Existing PK is preserved.
      NULL;
    ELSE
      IF id_type='uuid' THEN
        BEGIN
          EXECUTE format('ALTER TABLE %I.%I ADD CONSTRAINT %I PRIMARY KEY (id)', r.table_schema, r.table_name, pk_name);
        EXCEPTION WHEN duplicate_object THEN
          NULL;
        WHEN others THEN
          RAISE NOTICE 'primary key skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
        END;
      END IF;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.table_constraints tc
      WHERE tc.table_schema=r.table_schema
        AND tc.table_name=r.table_name
        AND tc.constraint_name=ck_name
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
        RAISE NOTICE 'business_code check skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
      END;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='tenant_id'
    ) THEN
      EXECUTE format(
        'SELECT count(*) FROM (
           SELECT tenant_id, business_code
           FROM %I.%I
           WHERE business_code IS NOT NULL
             AND (%s)
           GROUP BY tenant_id, business_code
           HAVING count(*) > 1
         ) d',
        r.table_schema,
        r.table_name,
        CASE
          WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema=r.table_schema
              AND table_name=r.table_name
              AND column_name='deleted_at'
          )
          THEN 'deleted_at IS NULL'
          ELSE 'true'
        END
      )
      INTO duplicate_count;

      IF duplicate_count = 0 THEN
        BEGIN
          EXECUTE format(
            'CREATE UNIQUE INDEX IF NOT EXISTS %I ON %I.%I (tenant_id, business_code) WHERE business_code IS NOT NULL AND %s',
            ux_name,
            r.table_schema,
            r.table_name,
            CASE
              WHEN EXISTS (
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema=r.table_schema
                  AND table_name=r.table_name
                  AND column_name='deleted_at'
              )
              THEN 'deleted_at IS NULL'
              ELSE 'true'
            END
          );
        EXCEPTION WHEN others THEN
          RAISE NOTICE 'tenant business_code unique index skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
        END;
      ELSE
        RAISE NOTICE 'tenant business_code unique index skipped for %.% because duplicate_count=%', r.table_schema, r.table_name, duplicate_count;
      END IF;
    END IF;
  END LOOP;
END $$;

GRANT USAGE ON SCHEMA app_standard TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.normalize_business_code(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.generate_business_code(text, uuid) TO PUBLIC;

COMMIT;
