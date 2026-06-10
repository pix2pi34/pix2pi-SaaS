-- FAZ 3 / 9.6.1 rollback
-- Journal tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_journal_lines_tenant_isolation_policy ON erp_journal_lines;
DROP POLICY IF EXISTS erp_journal_entries_tenant_isolation_policy ON erp_journal_entries;

DROP TABLE IF EXISTS erp_journal_lines;
DROP TABLE IF EXISTS erp_journal_entries;
