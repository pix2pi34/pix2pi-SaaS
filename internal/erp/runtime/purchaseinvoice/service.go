package purchaseinvoice

import "context"

type PurchaseInvoiceOrchestrator interface {
	PostPurchaseInvoice(ctx context.Context, req PurchaseInvoiceRequest) (PurchaseInvoiceResult, error)
}

type PurchaseInvoiceDraftBuilder interface {
	BuildPurchaseInvoiceDraft(ctx context.Context, req PurchaseInvoiceRequest) (PurchaseInvoiceDraft, error)
}

type PurchaseInvoiceStore interface {
	PersistPurchaseInvoiceDraft(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error)
	MarkPurchaseInvoicePosted(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error)
}

type PurchaseInvoiceTaxCalculator interface {
	CalculatePurchaseInvoiceTax(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error)
}

type PurchaseInvoiceJournalPoster interface {
	PostPurchaseInvoiceJournal(ctx context.Context, draft PurchaseInvoiceDraft) error
}

type PurchaseInvoiceLedgerPoster interface {
	PostPurchaseInvoiceLedger(ctx context.Context, draft PurchaseInvoiceDraft) error
}

type PurchaseInvoicePublisher interface {
	PublishPurchaseInvoicePosted(ctx context.Context, result PurchaseInvoiceResult) error
}
