-- FAZ 3 / 9.3.1 rollback
-- Inventory tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_warehouse_balances_tenant_isolation_policy ON erp_warehouse_balances;
DROP POLICY IF EXISTS erp_stock_movements_tenant_isolation_policy ON erp_stock_movements;
DROP POLICY IF EXISTS erp_warehouses_tenant_isolation_policy ON erp_warehouses;

DROP TABLE IF EXISTS erp_warehouse_balances;
DROP TABLE IF EXISTS erp_stock_movements;
DROP TABLE IF EXISTS erp_warehouses;
