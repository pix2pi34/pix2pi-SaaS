package sales

import "context"

type SalesQuotationRepository interface {
	CreateSalesQuotation(ctx context.Context, input CreateSalesQuotationInput) (SalesQuotation, error)
	CreateSalesQuotationLine(ctx context.Context, input CreateSalesQuotationLineInput) (SalesQuotationLine, error)
	GetSalesQuotationByID(ctx context.Context, tenantID string, quotationID string) (SalesQuotation, error)
	ListSalesQuotations(ctx context.Context, tenantID string, filter ListSalesQuotationsFilter) ([]SalesQuotation, error)
	ListSalesQuotationLines(ctx context.Context, tenantID string, quotationID string) ([]SalesQuotationLine, error)
}

type ListSalesQuotationsFilter struct {
	CustomerID string
	Query      string
	Status     SalesQuotationStatus
	Limit      int
	Offset     int
}

type SalesOrderRepository interface {
	CreateSalesOrder(ctx context.Context, input CreateSalesOrderInput) (SalesOrder, error)
	CreateSalesOrderLine(ctx context.Context, input CreateSalesOrderLineInput) (SalesOrderLine, error)
	GetSalesOrderByID(ctx context.Context, tenantID string, salesOrderID string) (SalesOrder, error)
	ListSalesOrders(ctx context.Context, tenantID string, filter ListSalesOrdersFilter) ([]SalesOrder, error)
	ListSalesOrderLines(ctx context.Context, tenantID string, salesOrderID string) ([]SalesOrderLine, error)
}

type ListSalesOrdersFilter struct {
	CustomerID  string
	QuotationID string
	Query       string
	Status      SalesOrderStatus
	Limit       int
	Offset      int
}

type SalesDeliveryRepository interface {
	CreateSalesDelivery(ctx context.Context, input CreateSalesDeliveryInput) (SalesDelivery, error)
	CreateSalesDeliveryLine(ctx context.Context, input CreateSalesDeliveryLineInput) (SalesDeliveryLine, error)
	GetSalesDeliveryByID(ctx context.Context, tenantID string, deliveryID string) (SalesDelivery, error)
	ListSalesDeliveries(ctx context.Context, tenantID string, filter ListSalesDeliveriesFilter) ([]SalesDelivery, error)
	ListSalesDeliveryLines(ctx context.Context, tenantID string, deliveryID string) ([]SalesDeliveryLine, error)
}

type ListSalesDeliveriesFilter struct {
	CustomerID   string
	SalesOrderID string
	WarehouseID  string
	Query        string
	Status       SalesDeliveryStatus
	Limit        int
	Offset       int
}

type SalesInvoiceRepository interface {
	CreateSalesInvoice(ctx context.Context, input CreateSalesInvoiceInput) (SalesInvoice, error)
	CreateSalesInvoiceLine(ctx context.Context, input CreateSalesInvoiceLineInput) (SalesInvoiceLine, error)
	GetSalesInvoiceByID(ctx context.Context, tenantID string, salesInvoiceID string) (SalesInvoice, error)
	ListSalesInvoices(ctx context.Context, tenantID string, filter ListSalesInvoicesFilter) ([]SalesInvoice, error)
	ListSalesInvoiceLines(ctx context.Context, tenantID string, salesInvoiceID string) ([]SalesInvoiceLine, error)
}

type ListSalesInvoicesFilter struct {
	CustomerID   string
	SalesOrderID string
	DeliveryID   string
	Query        string
	Status       SalesInvoiceStatus
	Limit        int
	Offset       int
}
