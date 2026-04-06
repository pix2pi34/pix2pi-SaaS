BEGIN;

-- Tenants meta (idempotent)
ALTER TABLE tenants
  ADD COLUMN IF NOT EXISTS active      boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS plan        text    NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS features    jsonb   NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS org_root_id bigint;

-- seed defaults for dev (safe / idempotent)
UPDATE tenants
SET
  plan = CASE WHEN plan IS NULL OR plan = '' THEN 'dev' ELSE plan END,
  features = CASE WHEN features IS NULL THEN '{"rbac":true,"graph":false}'::jsonb ELSE features END
WHERE id = 1;

COMMIT;
