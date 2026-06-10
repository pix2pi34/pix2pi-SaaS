-- FAZ 3 / 9.8.1 rollback
-- Chart of accounts tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_account_mapping_rules_tenant_isolation_policy ON erp_account_mapping_rules;
DROP POLICY IF EXISTS erp_chart_accounts_tenant_isolation_policy ON erp_chart_accounts;

DROP TABLE IF EXISTS erp_account_mapping_rules;
DROP TABLE IF EXISTS erp_chart_accounts;
