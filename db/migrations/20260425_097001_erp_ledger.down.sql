-- FAZ 3 / 9.7.1 rollback
-- Ledger tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_ledger_balances_tenant_isolation_policy ON erp_ledger_balances;
DROP POLICY IF EXISTS erp_account_movements_tenant_isolation_policy ON erp_account_movements;

DROP TABLE IF EXISTS erp_ledger_balances;
DROP TABLE IF EXISTS erp_account_movements;
