package salesinvoice

import "context"

var _ SalesInvoiceOrchestrator = (*DefaultSalesInvoiceOrchestrator)(nil)
var _ SalesInvoiceDraftBuilder = (*DefaultSalesInvoiceDraftBuilder)(nil)

type DefaultSalesInvoiceDraftBuilder struct{}

func NewDefaultSalesInvoiceDraftBuilder() *DefaultSalesInvoiceDraftBuilder {
	return &DefaultSalesInvoiceDraftBuilder{}
}

func (b *DefaultSalesInvoiceDraftBuilder) BuildSalesInvoiceDraft(ctx context.Context, req SalesInvoiceRequest) (SalesInvoiceDraft, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return SalesInvoiceDraft{}, ctx.Err()
	default:
	}

	return BuildSalesInvoiceDraft(req)
}

type DefaultSalesInvoiceOrchestrator struct {
	builder       SalesInvoiceDraftBuilder
	store         SalesInvoiceStore
	taxCalculator SalesInvoiceTaxCalculator
	journalPoster SalesInvoiceJournalPoster
	ledgerPoster  SalesInvoiceLedgerPoster
	publisher     SalesInvoicePublisher
}

func NewDefaultSalesInvoiceOrchestrator(
	builder SalesInvoiceDraftBuilder,
	store SalesInvoiceStore,
	taxCalculator SalesInvoiceTaxCalculator,
	journalPoster SalesInvoiceJournalPoster,
	ledgerPoster SalesInvoiceLedgerPoster,
	publisher SalesInvoicePublisher,
) *DefaultSalesInvoiceOrchestrator {
	if builder == nil {
		builder = NewDefaultSalesInvoiceDraftBuilder()
	}

	return &DefaultSalesInvoiceOrchestrator{
		builder:       builder,
		store:         store,
		taxCalculator: taxCalculator,
		journalPoster: journalPoster,
		ledgerPoster:  ledgerPoster,
		publisher:     publisher,
	}
}

func (o *DefaultSalesInvoiceOrchestrator) PostSalesInvoice(ctx context.Context, req SalesInvoiceRequest) (SalesInvoiceResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return SalesInvoiceResult{}, ctx.Err()
	default:
	}

	if err := ValidateSalesInvoiceRequest(req); err != nil {
		return SalesInvoiceResult{}, err
	}

	if o.store == nil {
		return SalesInvoiceResult{}, ErrSalesInvoiceStoreRequired
	}

	draft, err := o.builder.BuildSalesInvoiceDraft(ctx, req)
	if err != nil {
		return SalesInvoiceResult{}, err
	}

	if o.taxCalculator != nil {
		draft, err = o.taxCalculator.CalculateSalesInvoiceTax(ctx, draft)
		if err != nil {
			return SalesInvoiceResult{}, err
		}
	}

	persistedDraft, err := o.store.PersistSalesInvoiceDraft(ctx, draft)
	if err != nil {
		return SalesInvoiceResult{}, err
	}

	if o.journalPoster != nil {
		if err := o.journalPoster.PostSalesInvoiceJournal(ctx, persistedDraft); err != nil {
			return SalesInvoiceResult{}, err
		}
	}

	if o.ledgerPoster != nil {
		if err := o.ledgerPoster.PostSalesInvoiceLedger(ctx, persistedDraft); err != nil {
			return SalesInvoiceResult{}, err
		}
	}

	postedDraft, err := o.store.MarkSalesInvoicePosted(ctx, persistedDraft)
	if err != nil {
		return SalesInvoiceResult{}, err
	}

	result, err := BuildSalesInvoiceResult(req, postedDraft, "sales invoice posted")
	if err != nil {
		return SalesInvoiceResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishSalesInvoicePosted(ctx, result); err != nil {
			return SalesInvoiceResult{}, err
		}
	}

	return result, nil
}
