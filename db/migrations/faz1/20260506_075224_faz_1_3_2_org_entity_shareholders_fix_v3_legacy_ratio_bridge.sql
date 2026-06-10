BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;

DO $$
DECLARE
  has_kind boolean := false;
  has_ownership_ratio boolean := false;
  has_voting_ratio boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='shareholder_kind'
  ) INTO has_kind;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='ownership_ratio'
  ) INTO has_ownership_ratio;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='voting_ratio'
  ) INTO has_voting_ratio;

  IF has_kind AND has_ownership_ratio AND has_voting_ratio THEN
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

        IF NEW.ownership_percentage IS NULL THEN
          NEW.ownership_percentage := COALESCE(NEW.ownership_ratio, 0);
        END IF;

        IF NEW.ownership_ratio IS NULL THEN
          NEW.ownership_ratio := COALESCE(NEW.ownership_percentage, 0);
        END IF;

        IF NEW.voting_percentage IS NULL THEN
          NEW.voting_percentage := NEW.voting_ratio;
        END IF;

        IF NEW.voting_ratio IS NULL THEN
          NEW.voting_ratio := COALESCE(NEW.voting_percentage, NEW.ownership_percentage, NEW.ownership_ratio, 0);
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

  ELSIF has_kind AND has_ownership_ratio THEN
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

        IF NEW.ownership_percentage IS NULL THEN
          NEW.ownership_percentage := COALESCE(NEW.ownership_ratio, 0);
        END IF;

        IF NEW.ownership_ratio IS NULL THEN
          NEW.ownership_ratio := COALESCE(NEW.ownership_percentage, 0);
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

  ELSE
    EXECUTE $fn$
      CREATE OR REPLACE FUNCTION org.sync_entity_shareholder_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $body$
      BEGIN
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
  END IF;

  EXECUTE 'DROP TRIGGER IF EXISTS trg_org_entity_shareholders_sync_legacy_fields ON org.entity_shareholders';
  EXECUTE 'CREATE TRIGGER trg_org_entity_shareholders_sync_legacy_fields
           BEFORE INSERT OR UPDATE ON org.entity_shareholders
           FOR EACH ROW
           EXECUTE FUNCTION org.sync_entity_shareholder_legacy_fields()';

  IF has_kind THEN
    EXECUTE 'ALTER TABLE org.entity_shareholders ALTER COLUMN shareholder_kind SET DEFAULT ''OTHER''';
    EXECUTE '
      UPDATE org.entity_shareholders
      SET shareholder_kind = COALESCE(NULLIF(shareholder_kind::text, ''''), NULLIF(shareholder_type::text, ''''), ''OTHER'')
      WHERE shareholder_kind IS NULL
         OR btrim(shareholder_kind::text) = ''''
    ';
  END IF;

  IF has_ownership_ratio THEN
    EXECUTE 'ALTER TABLE org.entity_shareholders ALTER COLUMN ownership_ratio SET DEFAULT 0';
    EXECUTE '
      UPDATE org.entity_shareholders
      SET ownership_ratio = COALESCE(ownership_ratio, ownership_percentage, 0)
      WHERE ownership_ratio IS NULL
    ';
  END IF;

  IF has_voting_ratio THEN
    EXECUTE 'ALTER TABLE org.entity_shareholders ALTER COLUMN voting_ratio SET DEFAULT 0';
    EXECUTE '
      UPDATE org.entity_shareholders
      SET voting_ratio = COALESCE(voting_ratio, voting_percentage, ownership_percentage, ownership_ratio, 0)
      WHERE voting_ratio IS NULL
    ';
  END IF;

  EXECUTE 'GRANT EXECUTE ON FUNCTION org.sync_entity_shareholder_legacy_fields() TO PUBLIC';
END $$;

COMMIT;
