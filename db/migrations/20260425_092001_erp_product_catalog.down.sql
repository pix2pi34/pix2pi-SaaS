-- FAZ 3 / 9.2.1 rollback
-- Product catalog tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_products_tenant_isolation_policy ON erp_products;
DROP POLICY IF EXISTS erp_items_tenant_isolation_policy ON erp_items;
DROP POLICY IF EXISTS erp_product_categories_tenant_isolation_policy ON erp_product_categories;
DROP POLICY IF EXISTS erp_units_tenant_isolation_policy ON erp_units;

DROP TABLE IF EXISTS erp_products;
DROP TABLE IF EXISTS erp_items;
DROP TABLE IF EXISTS erp_product_categories;
DROP TABLE IF EXISTS erp_units;
