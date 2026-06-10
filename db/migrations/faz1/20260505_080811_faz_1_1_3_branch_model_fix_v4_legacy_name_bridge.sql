BEGIN;

CREATE SCHEMA IF NOT EXISTS org;

UPDATE org.branches
SET name = COALESCE(
  NULLIF(branch_name, ''),
  NULLIF(branch_code, ''),
  NULLIF(business_code, ''),
  id::text
)
WHERE name IS NULL
   OR btrim(name::text) = '';

CREATE OR REPLACE FUNCTION org.sync_branch_legacy_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.branch_name IS NULL OR btrim(NEW.branch_name::text) = '' THEN
    NEW.branch_name := COALESCE(NULLIF(NEW.name::text, ''), NULLIF(NEW.branch_code, ''), NULLIF(NEW.business_code, ''), NEW.id::text);
  END IF;

  IF NEW.name IS NULL OR btrim(NEW.name::text) = '' THEN
    NEW.name := COALESCE(NULLIF(NEW.branch_name::text, ''), NULLIF(NEW.branch_code, ''), NULLIF(NEW.business_code, ''), NEW.id::text);
  END IF;

  IF NEW.branch_code IS NULL OR btrim(NEW.branch_code::text) = '' THEN
    NEW.branch_code := COALESCE(NULLIF(NEW.business_code, ''), 'BR-' || upper(substr(replace(NEW.id::text,'-',''),1,10)));
  END IF;

  IF NEW.business_code IS NULL OR btrim(NEW.business_code::text) = '' THEN
    NEW.business_code := COALESCE(NULLIF(NEW.branch_code, ''), 'BRANCH_' || upper(substr(replace(NEW.id::text,'-',''),1,10)));
  END IF;

  IF NEW.scope_key IS NULL OR btrim(NEW.scope_key::text) = '' THEN
    NEW.scope_key := 'branch:' || NEW.id::text;
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
