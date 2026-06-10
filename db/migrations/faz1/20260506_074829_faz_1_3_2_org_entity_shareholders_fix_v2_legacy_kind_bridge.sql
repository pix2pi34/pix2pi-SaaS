BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='shareholder_kind'
  ) THEN
    EXECUTE $fn$
      CREATE OR REPLACE FUNCTION org.sync_entity_shareholder_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $body$
      BEGIN
        IF NEW.shareholder_type IS NULL OR btrim(NEW.shareholder_type::text) = '' THEN
          NEW.shareholder_type := COALESCE(NULLIF(NEW.shareholder_kind::text, ''), 'OTHER');
        END IF;

        IF NEW.shareholder_kind IS NULL OR btrim(NEW.shareholder_kind::text) = '' THEN
          NEW.shareholder_kind := COALESCE(NULLIF(NEW.shareholder_type::text, ''), 'OTHER');
        END IF;

        IF NEW.shareholder_name IS NULL OR btrim(NEW.shareholder_name::text) = '' THEN
          NEW.shareholder_name := COALESCE(
            NULLIF(NEW.shareholder_tax_number::text, ''),
            NULLIF(NEW.business_code::text, ''),
            NEW.id::text
          );
        END IF;

        RETURN NEW;
      END
      $body$;
    $fn$;

    EXECUTE 'DROP TRIGGER IF EXISTS trg_org_entity_shareholders_sync_legacy_fields ON org.entity_shareholders';
    EXECUTE 'CREATE TRIGGER trg_org_entity_shareholders_sync_legacy_fields
             BEFORE INSERT OR UPDATE ON org.entity_shareholders
             FOR EACH ROW
             EXECUTE FUNCTION org.sync_entity_shareholder_legacy_fields()';

    EXECUTE 'ALTER TABLE org.entity_shareholders ALTER COLUMN shareholder_kind SET DEFAULT ''OTHER''';

    EXECUTE '
      UPDATE org.entity_shareholders
      SET shareholder_kind = COALESCE(NULLIF(shareholder_kind::text, ''''), NULLIF(shareholder_type::text, ''''), ''OTHER'')
      WHERE shareholder_kind IS NULL
         OR btrim(shareholder_kind::text) = ''''
    ';

    EXECUTE 'GRANT EXECUTE ON FUNCTION org.sync_entity_shareholder_legacy_fields() TO PUBLIC';
  END IF;
END $$;

COMMIT;
