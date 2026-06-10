BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS franchise;

DO $$
DECLARE
  has_agreement_code boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='agreement_code'
  ) INTO has_agreement_code;

  IF has_agreement_code THEN
    EXECUTE $fn$
      CREATE OR REPLACE FUNCTION franchise.sync_agreements_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $body$
      BEGIN
        IF NEW.id IS NULL THEN
          NEW.id := gen_random_uuid();
        END IF;

        IF NEW.business_code IS NULL OR btrim(NEW.business_code::text) = '' THEN
          NEW.business_code := COALESCE(
            NULLIF(NEW.agreement_code::text, ''),
            NULLIF(NEW.agreement_number::text, ''),
            'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12))
          );
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(
            NULLIF(NEW.agreement_code::text, ''),
            NULLIF(NEW.business_code::text, ''),
            'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12))
          );
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' THEN
          NEW.agreement_code := COALESCE(
            NULLIF(NEW.agreement_number::text, ''),
            NULLIF(NEW.business_code::text, ''),
            'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12))
          );
        END IF;

        IF NEW.agreement_lifecycle_status IS NULL OR btrim(NEW.agreement_lifecycle_status::text) = '' THEN
          NEW.agreement_lifecycle_status := 'DRAFT';
        END IF;

        IF NEW.metadata IS NULL THEN
          NEW.metadata := '{}'::jsonb;
        END IF;

        IF NEW.audit_metadata IS NULL THEN
          NEW.audit_metadata := '{}'::jsonb;
        END IF;

        RETURN NEW;
      END
      $body$;
    $fn$;

    EXECUTE 'DROP TRIGGER IF EXISTS trg_franchise_agreements_sync_legacy_fields ON franchise.agreements';

    EXECUTE 'CREATE TRIGGER trg_franchise_agreements_sync_legacy_fields
             BEFORE INSERT OR UPDATE ON franchise.agreements
             FOR EACH ROW
             EXECUTE FUNCTION franchise.sync_agreements_legacy_fields()';

    EXECUTE 'ALTER TABLE franchise.agreements ALTER COLUMN agreement_code SET DEFAULT ''FR_AGR_PENDING''';

    EXECUTE '
      UPDATE franchise.agreements
      SET agreement_code = COALESCE(
        NULLIF(agreement_code::text, ''''),
        NULLIF(agreement_number::text, ''''),
        NULLIF(business_code::text, ''''),
        ''FR_AGR_'' || upper(substr(replace(id::text, ''-'', ''''), 1, 12))
      )
      WHERE agreement_code IS NULL
         OR btrim(agreement_code::text) = ''''
    ';

    EXECUTE 'GRANT EXECUTE ON FUNCTION franchise.sync_agreements_legacy_fields() TO PUBLIC';
  ELSE
    EXECUTE $fn$
      CREATE OR REPLACE FUNCTION franchise.sync_agreements_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $body$
      BEGIN
        IF NEW.id IS NULL THEN
          NEW.id := gen_random_uuid();
        END IF;

        IF NEW.business_code IS NULL OR btrim(NEW.business_code::text) = '' THEN
          NEW.business_code := COALESCE(
            NULLIF(NEW.agreement_number::text, ''),
            'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12))
          );
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(
            NULLIF(NEW.business_code::text, ''),
            'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12))
          );
        END IF;

        IF NEW.agreement_lifecycle_status IS NULL OR btrim(NEW.agreement_lifecycle_status::text) = '' THEN
          NEW.agreement_lifecycle_status := 'DRAFT';
        END IF;

        IF NEW.metadata IS NULL THEN
          NEW.metadata := '{}'::jsonb;
        END IF;

        IF NEW.audit_metadata IS NULL THEN
          NEW.audit_metadata := '{}'::jsonb;
        END IF;

        RETURN NEW;
      END
      $body$;
    $fn$;

    EXECUTE 'DROP TRIGGER IF EXISTS trg_franchise_agreements_sync_legacy_fields ON franchise.agreements';

    EXECUTE 'CREATE TRIGGER trg_franchise_agreements_sync_legacy_fields
             BEFORE INSERT OR UPDATE ON franchise.agreements
             FOR EACH ROW
             EXECUTE FUNCTION franchise.sync_agreements_legacy_fields()';

    EXECUTE 'GRANT EXECUTE ON FUNCTION franchise.sync_agreements_legacy_fields() TO PUBLIC';
  END IF;
END $$;

COMMIT;
