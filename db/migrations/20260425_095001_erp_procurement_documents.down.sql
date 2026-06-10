-- FAZ 3 / 9.5.1 rollback
-- Procurement document tablolarini ters sirayla kaldirir.

DROP POLICY IF EXISTS erp_purchase_invoice_lines_tenant_isolation_policy ON erp_purchase_invoice_lines;
DROP POLICY IF EXISTS erp_purchase_invoices_tenant_isolation_policy ON erp_purchase_invoices;
DROP POLICY IF EXISTS erp_purchase_receipt_lines_tenant_isolation_policy ON erp_purchase_receipt_lines;
DROP POLICY IF EXISTS erp_purchase_receipts_tenant_isolation_policy ON erp_purchase_receipts;
DROP POLICY IF EXISTS erp_purchase_order_lines_tenant_isolation_policy ON erp_purchase_order_lines;
DROP POLICY IF EXISTS erp_purchase_orders_tenant_isolation_policy ON erp_purchase_orders;

DROP TABLE IF EXISTS erp_purchase_invoice_lines;
DROP TABLE IF EXISTS erp_purchase_invoices;
DROP TABLE IF EXISTS erp_purchase_receipt_lines;
DROP TABLE IF EXISTS erp_purchase_receipts;
DROP TABLE IF EXISTS erp_purchase_order_lines;
DROP TABLE IF EXISTS erp_purchase_orders;
