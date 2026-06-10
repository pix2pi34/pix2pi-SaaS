-- FAZ 3 / 9.4.1 rollback
-- Sales document tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_sales_invoice_lines_tenant_isolation_policy ON erp_sales_invoice_lines;
DROP POLICY IF EXISTS erp_sales_invoices_tenant_isolation_policy ON erp_sales_invoices;
DROP POLICY IF EXISTS erp_sales_delivery_lines_tenant_isolation_policy ON erp_sales_delivery_lines;
DROP POLICY IF EXISTS erp_sales_deliveries_tenant_isolation_policy ON erp_sales_deliveries;
DROP POLICY IF EXISTS erp_sales_order_lines_tenant_isolation_policy ON erp_sales_order_lines;
DROP POLICY IF EXISTS erp_sales_orders_tenant_isolation_policy ON erp_sales_orders;
DROP POLICY IF EXISTS erp_sales_quotation_lines_tenant_isolation_policy ON erp_sales_quotation_lines;
DROP POLICY IF EXISTS erp_sales_quotations_tenant_isolation_policy ON erp_sales_quotations;

DROP TABLE IF EXISTS erp_sales_invoice_lines;
DROP TABLE IF EXISTS erp_sales_invoices;
DROP TABLE IF EXISTS erp_sales_delivery_lines;
DROP TABLE IF EXISTS erp_sales_deliveries;
DROP TABLE IF EXISTS erp_sales_order_lines;
DROP TABLE IF EXISTS erp_sales_orders;
DROP TABLE IF EXISTS erp_sales_quotation_lines;
DROP TABLE IF EXISTS erp_sales_quotations;
