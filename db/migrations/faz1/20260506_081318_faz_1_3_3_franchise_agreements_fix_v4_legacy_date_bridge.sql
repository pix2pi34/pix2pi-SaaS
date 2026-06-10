BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS franchise;

DO $$
DECLARE
  has_agreement_code boolean := false;
  has_starts_on boolean := false;
  has_ends_on boolean := false;
  has_terminated_on boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='agreement_code'
  ) INTO has_agreement_code;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='starts_on'
  ) INTO has_starts_on;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='ends_on'
  ) INTO has_ends_on;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='terminated_on'
  ) INTO has_terminated_on;

  IF has_agreement_code AND has_starts_on AND has_ends_on AND has_terminated_on THEN
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
          NEW.business_code := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.agreement_number::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.business_code::text, ''), 'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' OR NEW.agreement_code::text = 'FR_AGR_PENDING' THEN
          NEW.agreement_code := COALESCE(NULLIF(NEW.agreement_number::text, ''), NULLIF(NEW.business_code::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.start_date IS NULL THEN
          NEW.start_date := COALESCE(NEW.starts_on::date, current_date);
        END IF;

        IF NEW.starts_on IS NULL THEN
          NEW.starts_on := NEW.start_date;
        END IF;

        IF NEW.end_date IS NULL AND NEW.ends_on IS NOT NULL THEN
          NEW.end_date := NEW.ends_on::date;
        END IF;

        IF NEW.ends_on IS NULL THEN
          NEW.ends_on := NEW.end_date;
        END IF;

        IF NEW.terminated_at IS NULL AND NEW.terminated_on IS NOT NULL THEN
          NEW.terminated_at := NEW.terminated_on::timestamptz;
        END IF;

        IF NEW.terminated_on IS NULL AND NEW.terminated_at IS NOT NULL THEN
          NEW.terminated_on := NEW.terminated_at::date;
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

  ELSIF has_agreement_code AND has_starts_on AND has_ends_on THEN
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
          NEW.business_code := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.agreement_number::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.business_code::text, ''), 'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' OR NEW.agreement_code::text = 'FR_AGR_PENDING' THEN
          NEW.agreement_code := COALESCE(NULLIF(NEW.agreement_number::text, ''), NULLIF(NEW.business_code::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.start_date IS NULL THEN
          NEW.start_date := COALESCE(NEW.starts_on::date, current_date);
        END IF;

        IF NEW.starts_on IS NULL THEN
          NEW.starts_on := NEW.start_date;
        END IF;

        IF NEW.end_date IS NULL AND NEW.ends_on IS NOT NULL THEN
          NEW.end_date := NEW.ends_on::date;
        END IF;

        IF NEW.ends_on IS NULL THEN
          NEW.ends_on := NEW.end_date;
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

  ELSIF has_agreement_code AND has_starts_on THEN
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
          NEW.business_code := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.agreement_number::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.business_code::text, ''), 'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' OR NEW.agreement_code::text = 'FR_AGR_PENDING' THEN
          NEW.agreement_code := COALESCE(NULLIF(NEW.agreement_number::text, ''), NULLIF(NEW.business_code::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.start_date IS NULL THEN
          NEW.start_date := COALESCE(NEW.starts_on::date, current_date);
        END IF;

        IF NEW.starts_on IS NULL THEN
          NEW.starts_on := NEW.start_date;
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

  ELSE
    RAISE NOTICE 'No legacy date bridge required or partial unsupported legacy set detected';
  END IF;

  IF has_agreement_code OR has_starts_on THEN
    EXECUTE 'DROP TRIGGER IF EXISTS trg_franchise_agreements_sync_legacy_fields ON franchise.agreements';
    EXECUTE 'CREATE TRIGGER trg_franchise_agreements_sync_legacy_fields
             BEFORE INSERT OR UPDATE ON franchise.agreements
             FOR EACH ROW
             EXECUTE FUNCTION franchise.sync_agreements_legacy_fields()';

    EXECUTE 'GRANT EXECUTE ON FUNCTION franchise.sync_agreements_legacy_fields() TO PUBLIC';
  END IF;

  IF has_agreement_code THEN
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
  END IF;

  IF has_starts_on THEN
    EXECUTE 'ALTER TABLE franchise.agreements ALTER COLUMN starts_on SET DEFAULT current_date';

    EXECUTE '
      UPDATE franchise.agreements
      SET starts_on = COALESCE(starts_on, start_date, current_date)
      WHERE starts_on IS NULL
    ';
  END IF;

  IF has_ends_on THEN
    EXECUTE '
      UPDATE franchise.agreements
      SET ends_on = COALESCE(ends_on, end_date)
      WHERE ends_on IS NULL
        AND end_date IS NOT NULL
    ';
  END IF;

  IF has_terminated_on THEN
    EXECUTE '
      UPDATE franchise.agreements
      SET terminated_on = COALESCE(terminated_on, terminated_at::date)
      WHERE terminated_on IS NULL
        AND terminated_at IS NOT NULL
    ';
  END IF;
END $$;

COMMIT;
