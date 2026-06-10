BEGIN;

CREATE SCHEMA IF NOT EXISTS app_standard;

CREATE OR REPLACE FUNCTION app_standard.normalize_identifier_name(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT trim(both '_' from regexp_replace(lower(coalesce(input_text, '')), '[^a-z0-9_]', '_', 'g'));
$$;

CREATE OR REPLACE FUNCTION app_standard.is_snake_identifier(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(input_text, '') ~ '^[a-z][a-z0-9_]*$';
$$;

CREATE OR REPLACE FUNCTION app_standard.standard_index_name(
  index_kind text,
  schema_name text,
  table_name text,
  column_list text DEFAULT ''
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT left(
    app_standard.normalize_identifier_name(
      coalesce(index_kind, 'idx') || '_' ||
      coalesce(schema_name, 'public') || '_' ||
      coalesce(table_name, 'table') ||
      case when coalesce(column_list, '') = '' then '' else '_' || column_list end
    ),
    52
  ) || '_' || substr(md5(coalesce(index_kind, '') || '.' || coalesce(schema_name, '') || '.' || coalesce(table_name, '') || '.' || coalesce(column_list, '')), 1, 8);
$$;

CREATE OR REPLACE FUNCTION app_standard.is_standard_index_name(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    app_standard.is_snake_identifier(input_text)
    AND length(input_text) <= 63;
$$;

CREATE OR REPLACE FUNCTION app_standard.is_standard_fk_name(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    app_standard.is_snake_identifier(input_text)
    AND length(input_text) <= 63;
$$;

CREATE OR REPLACE FUNCTION app_standard.is_standard_unique_name(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    app_standard.is_snake_identifier(input_text)
    AND length(input_text) <= 63;
$$;

GRANT USAGE ON SCHEMA app_standard TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.normalize_identifier_name(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_snake_identifier(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.standard_index_name(text,text,text,text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_standard_index_name(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_standard_fk_name(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_standard_unique_name(text) TO PUBLIC;

COMMIT;
