package taxcalc

import "context"

type TaxOrchestrator interface {
	CalculateTax(ctx context.Context, req TaxCalculationRequest) (TaxCalculationResult, error)
}

type TaxDraftBuilder interface {
	BuildTaxCalculationDraft(ctx context.Context, req TaxCalculationRequest) (TaxCalculationDraft, error)
}

type TaxStore interface {
	PersistTaxDraft(ctx context.Context, draft TaxCalculationDraft) (TaxCalculationDraft, error)
	MarkTaxPosted(ctx context.Context, draft TaxCalculationDraft) (TaxCalculationDraft, error)
}

type TaxPublisher interface {
	PublishTaxCalculated(ctx context.Context, result TaxCalculationResult) error
}
