package purchaseinvoice

import "context"

var _ PurchaseInvoiceOrchestrator = (*DefaultPurchaseInvoiceOrchestrator)(nil)
var _ PurchaseInvoiceDraftBuilder = (*DefaultPurchaseInvoiceDraftBuilder)(nil)

type DefaultPurchaseInvoiceDraftBuilder struct{}

func NewDefaultPurchaseInvoiceDraftBuilder() *DefaultPurchaseInvoiceDraftBuilder {
	return &DefaultPurchaseInvoiceDraftBuilder{}
}

func (b *DefaultPurchaseInvoiceDraftBuilder) BuildPurchaseInvoiceDraft(ctx context.Context, req PurchaseInvoiceRequest) (PurchaseInvoiceDraft, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return PurchaseInvoiceDraft{}, ctx.Err()
	default:
	}

	return BuildPurchaseInvoiceDraft(req)
}

type DefaultPurchaseInvoiceOrchestrator struct {
	builder       PurchaseInvoiceDraftBuilder
	store         PurchaseInvoiceStore
	taxCalculator PurchaseInvoiceTaxCalculator
	journalPoster PurchaseInvoiceJournalPoster
	ledgerPoster  PurchaseInvoiceLedgerPoster
	publisher     PurchaseInvoicePublisher
}

func NewDefaultPurchaseInvoiceOrchestrator(
	builder PurchaseInvoiceDraftBuilder,
	store PurchaseInvoiceStore,
	taxCalculator PurchaseInvoiceTaxCalculator,
	journalPoster PurchaseInvoiceJournalPoster,
	ledgerPoster PurchaseInvoiceLedgerPoster,
	publisher PurchaseInvoicePublisher,
) *DefaultPurchaseInvoiceOrchestrator {
	if builder == nil {
		builder = NewDefaultPurchaseInvoiceDraftBuilder()
	}

	return &DefaultPurchaseInvoiceOrchestrator{
		builder:       builder,
		store:         store,
		taxCalculator: taxCalculator,
		journalPoster: journalPoster,
		ledgerPoster:  ledgerPoster,
		publisher:     publisher,
	}
}

func (o *DefaultPurchaseInvoiceOrchestrator) PostPurchaseInvoice(ctx context.Context, req PurchaseInvoiceRequest) (PurchaseInvoiceResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return PurchaseInvoiceResult{}, ctx.Err()
	default:
	}

	if err := ValidatePurchaseInvoiceRequest(req); err != nil {
		return PurchaseInvoiceResult{}, err
	}

	if o.store == nil {
		return PurchaseInvoiceResult{}, ErrPurchaseInvoiceStoreRequired
	}

	draft, err := o.builder.BuildPurchaseInvoiceDraft(ctx, req)
	if err != nil {
		return PurchaseInvoiceResult{}, err
	}

	if o.taxCalculator != nil {
		draft, err = o.taxCalculator.CalculatePurchaseInvoiceTax(ctx, draft)
		if err != nil {
			return PurchaseInvoiceResult{}, err
		}
	}

	persistedDraft, err := o.store.PersistPurchaseInvoiceDraft(ctx, draft)
	if err != nil {
		return PurchaseInvoiceResult{}, err
	}

	if o.journalPoster != nil {
		if err := o.journalPoster.PostPurchaseInvoiceJournal(ctx, persistedDraft); err != nil {
			return PurchaseInvoiceResult{}, err
		}
	}

	if o.ledgerPoster != nil {
		if err := o.ledgerPoster.PostPurchaseInvoiceLedger(ctx, persistedDraft); err != nil {
			return PurchaseInvoiceResult{}, err
		}
	}

	postedDraft, err := o.store.MarkPurchaseInvoicePosted(ctx, persistedDraft)
	if err != nil {
		return PurchaseInvoiceResult{}, err
	}

	result, err := BuildPurchaseInvoiceResult(req, postedDraft, "purchase invoice posted")
	if err != nil {
		return PurchaseInvoiceResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishPurchaseInvoicePosted(ctx, result); err != nil {
			return PurchaseInvoiceResult{}, err
		}
	}

	return result, nil
}
