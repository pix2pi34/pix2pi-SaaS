-- FAZ 3 / 9.9.1 rollback
-- Tax tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_tax_transactions_tenant_isolation_policy ON erp_tax_transactions;
DROP POLICY IF EXISTS erp_tax_rates_tenant_isolation_policy ON erp_tax_rates;
DROP POLICY IF EXISTS erp_tax_codes_tenant_isolation_policy ON erp_tax_codes;

DROP TABLE IF EXISTS erp_tax_transactions;
DROP TABLE IF EXISTS erp_tax_rates;
DROP TABLE IF EXISTS erp_tax_codes;
