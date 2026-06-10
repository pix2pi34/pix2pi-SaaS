package salesinvoice

import "context"

type SalesInvoiceOrchestrator interface {
	PostSalesInvoice(ctx context.Context, req SalesInvoiceRequest) (SalesInvoiceResult, error)
}

type SalesInvoiceDraftBuilder interface {
	BuildSalesInvoiceDraft(ctx context.Context, req SalesInvoiceRequest) (SalesInvoiceDraft, error)
}

type SalesInvoiceStore interface {
	PersistSalesInvoiceDraft(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error)
	MarkSalesInvoicePosted(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error)
}

type SalesInvoiceTaxCalculator interface {
	CalculateSalesInvoiceTax(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error)
}

type SalesInvoiceJournalPoster interface {
	PostSalesInvoiceJournal(ctx context.Context, draft SalesInvoiceDraft) error
}

type SalesInvoiceLedgerPoster interface {
	PostSalesInvoiceLedger(ctx context.Context, draft SalesInvoiceDraft) error
}

type SalesInvoicePublisher interface {
	PublishSalesInvoicePosted(ctx context.Context, result SalesInvoiceResult) error
}
