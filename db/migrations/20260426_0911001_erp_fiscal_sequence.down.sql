-- FAZ 3 / 9.11.1 rollback

DROP POLICY IF EXISTS erp_document_number_allocations_tenant_isolation_policy ON erp_document_number_allocations;
DROP POLICY IF EXISTS erp_document_sequences_tenant_isolation_policy ON erp_document_sequences;
DROP POLICY IF EXISTS erp_fiscal_periods_tenant_isolation_policy ON erp_fiscal_periods;
DROP POLICY IF EXISTS erp_fiscal_years_tenant_isolation_policy ON erp_fiscal_years;

DROP TABLE IF EXISTS erp_document_number_allocations;
DROP TABLE IF EXISTS erp_document_sequences;
DROP TABLE IF EXISTS erp_fiscal_periods;
DROP TABLE IF EXISTS erp_fiscal_years;
