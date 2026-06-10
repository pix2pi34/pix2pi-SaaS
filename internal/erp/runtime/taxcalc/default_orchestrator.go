package taxcalc

import (
	"context"
)

var _ TaxOrchestrator = (*DefaultTaxOrchestrator)(nil)
var _ TaxDraftBuilder = (*DefaultTaxDraftBuilder)(nil)

type DefaultTaxDraftBuilder struct{}

func NewDefaultTaxDraftBuilder() *DefaultTaxDraftBuilder {
	return &DefaultTaxDraftBuilder{}
}

func (b *DefaultTaxDraftBuilder) BuildTaxCalculationDraft(ctx context.Context, req TaxCalculationRequest) (TaxCalculationDraft, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return TaxCalculationDraft{}, ctx.Err()
	default:
	}

	return BuildTaxCalculationDraft(req)
}

type DefaultTaxOrchestrator struct {
	builder   TaxDraftBuilder
	store     TaxStore
	publisher TaxPublisher
}

func NewDefaultTaxOrchestrator(
	builder TaxDraftBuilder,
	store TaxStore,
	publisher TaxPublisher,
) *DefaultTaxOrchestrator {
	if builder == nil {
		builder = NewDefaultTaxDraftBuilder()
	}

	return &DefaultTaxOrchestrator{
		builder:   builder,
		store:     store,
		publisher: publisher,
	}
}

func (o *DefaultTaxOrchestrator) CalculateTax(ctx context.Context, req TaxCalculationRequest) (TaxCalculationResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return TaxCalculationResult{}, ctx.Err()
	default:
	}

	if err := ValidateTaxCalculationRequest(req); err != nil {
		return TaxCalculationResult{}, err
	}

	if o.store == nil {
		return TaxCalculationResult{}, ErrTaxStoreRequired
	}

	draft, err := o.builder.BuildTaxCalculationDraft(ctx, req)
	if err != nil {
		return TaxCalculationResult{}, err
	}

	persistedDraft, err := o.store.PersistTaxDraft(ctx, draft)
	if err != nil {
		return TaxCalculationResult{}, err
	}

	postedDraft, err := o.store.MarkTaxPosted(ctx, persistedDraft)
	if err != nil {
		return TaxCalculationResult{}, err
	}

	result, err := BuildTaxCalculationResult(req, postedDraft, "tax calculated")
	if err != nil {
		return TaxCalculationResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishTaxCalculated(ctx, result); err != nil {
			return TaxCalculationResult{}, err
		}
	}

	return result, nil
}
