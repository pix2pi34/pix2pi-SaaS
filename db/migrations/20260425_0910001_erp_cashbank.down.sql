-- FAZ 3 / 9.10.1 rollback

DROP POLICY IF EXISTS erp_payment_transactions_tenant_isolation_policy ON erp_payment_transactions;
DROP POLICY IF EXISTS erp_bank_accounts_tenant_isolation_policy ON erp_bank_accounts;
DROP POLICY IF EXISTS erp_cash_accounts_tenant_isolation_policy ON erp_cash_accounts;

DROP TABLE IF EXISTS erp_payment_transactions;
DROP TABLE IF EXISTS erp_bank_accounts;
DROP TABLE IF EXISTS erp_cash_accounts;
