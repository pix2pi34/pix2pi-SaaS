-- FAZ 3 / 9.1.1 rollback
-- Master party tablolarını ters sırayla kaldırır.

DROP POLICY IF EXISTS erp_addresses_tenant_isolation_policy ON erp_addresses;
DROP POLICY IF EXISTS erp_contacts_tenant_isolation_policy ON erp_contacts;
DROP POLICY IF EXISTS erp_vendors_tenant_isolation_policy ON erp_vendors;
DROP POLICY IF EXISTS erp_customers_tenant_isolation_policy ON erp_customers;
DROP POLICY IF EXISTS erp_parties_tenant_isolation_policy ON erp_parties;

DROP TABLE IF EXISTS erp_addresses;
DROP TABLE IF EXISTS erp_contacts;
DROP TABLE IF EXISTS erp_vendors;
DROP TABLE IF EXISTS erp_customers;
DROP TABLE IF EXISTS erp_parties;
