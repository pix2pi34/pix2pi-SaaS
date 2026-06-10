package procurement

import "context"

type PurchaseOrderRepository interface {
	CreatePurchaseOrder(ctx context.Context, input CreatePurchaseOrderInput) (PurchaseOrder, error)
	CreatePurchaseOrderLine(ctx context.Context, input CreatePurchaseOrderLineInput) (PurchaseOrderLine, error)
	GetPurchaseOrderByID(ctx context.Context, tenantID string, purchaseOrderID string) (PurchaseOrder, error)
	ListPurchaseOrders(ctx context.Context, tenantID string, filter ListPurchaseOrdersFilter) ([]PurchaseOrder, error)
	ListPurchaseOrderLines(ctx context.Context, tenantID string, purchaseOrderID string) ([]PurchaseOrderLine, error)
}

type ListPurchaseOrdersFilter struct {
	VendorID string
	Query    string
	Status   PurchaseOrderStatus
	Limit    int
	Offset   int
}

type PurchaseReceiptRepository interface {
	CreatePurchaseReceipt(ctx context.Context, input CreatePurchaseReceiptInput) (PurchaseReceipt, error)
	CreatePurchaseReceiptLine(ctx context.Context, input CreatePurchaseReceiptLineInput) (PurchaseReceiptLine, error)
	GetPurchaseReceiptByID(ctx context.Context, tenantID string, purchaseReceiptID string) (PurchaseReceipt, error)
	ListPurchaseReceipts(ctx context.Context, tenantID string, filter ListPurchaseReceiptsFilter) ([]PurchaseReceipt, error)
	ListPurchaseReceiptLines(ctx context.Context, tenantID string, purchaseReceiptID string) ([]PurchaseReceiptLine, error)
}

type ListPurchaseReceiptsFilter struct {
	VendorID        string
	PurchaseOrderID string
	WarehouseID     string
	Query           string
	Status          PurchaseReceiptStatus
	Limit           int
	Offset          int
}

type PurchaseInvoiceRepository interface {
	CreatePurchaseInvoice(ctx context.Context, input CreatePurchaseInvoiceInput) (PurchaseInvoice, error)
	CreatePurchaseInvoiceLine(ctx context.Context, input CreatePurchaseInvoiceLineInput) (PurchaseInvoiceLine, error)
	GetPurchaseInvoiceByID(ctx context.Context, tenantID string, purchaseInvoiceID string) (PurchaseInvoice, error)
	ListPurchaseInvoices(ctx context.Context, tenantID string, filter ListPurchaseInvoicesFilter) ([]PurchaseInvoice, error)
	ListPurchaseInvoiceLines(ctx context.Context, tenantID string, purchaseInvoiceID string) ([]PurchaseInvoiceLine, error)
}

type ListPurchaseInvoicesFilter struct {
	VendorID          string
	PurchaseOrderID   string
	PurchaseReceiptID string
	Query             string
	Status            PurchaseInvoiceStatus
	Limit             int
	Offset            int
}
