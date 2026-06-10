BEGIN;

ALTER TABLE inventory.location_inventory_links
  DROP CONSTRAINT IF EXISTS ck_inventory_location_links_stock_account_format;

ALTER TABLE inventory.location_inventory_links
  DROP CONSTRAINT IF EXISTS ck_inventory_location_links_account_format;

ALTER TABLE inventory.location_inventory_links
  ADD CONSTRAINT ck_inventory_location_links_account_format
  CHECK (
    (
      default_stock_account_code IS NULL
      OR default_stock_account_code ~ '^[0-9]{3}(\.[0-9]{1,4})?$'
    )
    AND
    (
      default_cogs_account_code IS NULL
      OR default_cogs_account_code ~ '^[0-9]{3}(\.[0-9]{1,4})?$'
    )
  ) NOT VALID;

COMMIT;
