BEGIN;

CREATE SCHEMA IF NOT EXISTS org;

UPDATE org.branches
SET name = COALESCE(
  NULLIF(branch_name::text, ''),
  NULLIF(name::text, ''),
  NULLIF(branch_code::text, ''),
  NULLIF(business_code::text, ''),
  id::text
)
WHERE name IS NULL
   OR btrim(name::text) = '';

UPDATE org.branches
SET branch_name = COALESCE(
  NULLIF(branch_name::text, ''),
  NULLIF(name::text, ''),
  NULLIF(branch_code::text, ''),
  NULLIF(business_code::text, ''),
  id::text
)
WHERE branch_name IS NULL
   OR btrim(branch_name::text) = '';

CREATE OR REPLACE FUNCTION org.sync_branch_legacy_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.branch_name IS NULL OR btrim(NEW.branch_name::text) = '' THEN
    NEW.branch_name := COALESCE(
      NULLIF(NEW.name::text, ''),
      NULLIF(NEW.branch_code::text, ''),
      NULLIF(NEW.business_code::text, ''),
      NEW.id::text
    );
  END IF;

  IF NEW.name IS NULL OR btrim(NEW.name::text) = '' THEN
    NEW.name := COALESCE(
      NULLIF(NEW.branch_name::text, ''),
      NULLIF(NEW.branch_code::text, ''),
      NULLIF(NEW.business_code::text, ''),
      NEW.id::text
    );
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_org_branches_sync_legacy_fields ON org.branches;
CREATE TRIGGER trg_org_branches_sync_legacy_fields
BEFORE INSERT OR UPDATE ON org.branches
FOR EACH ROW
EXECUTE FUNCTION org.sync_branch_legacy_fields();

GRANT EXECUTE ON FUNCTION org.sync_branch_legacy_fields() TO PUBLIC;

COMMIT;
