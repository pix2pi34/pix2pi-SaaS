package e2eflow

import (
	"context"
	"time"
)

type ValidateRequestStepAdapter struct{}

func NewValidateRequestStepAdapter() *ValidateRequestStepAdapter {
	return &ValidateRequestStepAdapter{}
}

func (a *ValidateRequestStepAdapter) StepKind() FlowStepKind {
	return FlowStepValidateRequest
}

func (a *ValidateRequestStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := ValidateRuntimeFlowStep(step); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "request validated"), nil
}

type PersistDocumentStepAdapter struct {
	document RuntimeDocumentAdapter
}

func NewPersistDocumentStepAdapter(document RuntimeDocumentAdapter) *PersistDocumentStepAdapter {
	return &PersistDocumentStepAdapter{document: document}
}

func (a *PersistDocumentStepAdapter) StepKind() FlowStepKind {
	return FlowStepPersistDocument
}

func (a *PersistDocumentStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if a.document == nil {
		return RuntimeFlowStep{}, ErrDocumentAdapterRequired
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := a.document.PersistDocument(ctx, plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "document persisted"), nil
}

type CalculateTaxStepAdapter struct {
	tax RuntimeTaxAdapter
}

func NewCalculateTaxStepAdapter(tax RuntimeTaxAdapter) *CalculateTaxStepAdapter {
	return &CalculateTaxStepAdapter{tax: tax}
}

func (a *CalculateTaxStepAdapter) StepKind() FlowStepKind {
	return FlowStepCalculateTax
}

func (a *CalculateTaxStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if a.tax == nil {
		return RuntimeFlowStep{}, ErrTaxAdapterRequired
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := a.tax.CalculateTax(ctx, plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "tax calculated"), nil
}

type CashBankPaymentStepAdapter struct {
	cashbank RuntimeCashBankAdapter
}

func NewCashBankPaymentStepAdapter(cashbank RuntimeCashBankAdapter) *CashBankPaymentStepAdapter {
	return &CashBankPaymentStepAdapter{cashbank: cashbank}
}

func (a *CashBankPaymentStepAdapter) StepKind() FlowStepKind {
	return FlowStepCashBankPayment
}

func (a *CashBankPaymentStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if a.cashbank == nil {
		return RuntimeFlowStep{}, ErrCashBankAdapterRequired
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := a.cashbank.ExecuteCashBankPayment(ctx, plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "cashbank payment executed"), nil
}

type PostJournalStepAdapter struct {
	journal RuntimeJournalAdapter
}

func NewPostJournalStepAdapter(journal RuntimeJournalAdapter) *PostJournalStepAdapter {
	return &PostJournalStepAdapter{journal: journal}
}

func (a *PostJournalStepAdapter) StepKind() FlowStepKind {
	return FlowStepPostJournal
}

func (a *PostJournalStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if a.journal == nil {
		return RuntimeFlowStep{}, ErrJournalAdapterRequired
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := a.journal.PostJournal(ctx, plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "journal posted"), nil
}

type PostLedgerStepAdapter struct {
	ledger RuntimeLedgerAdapter
}

func NewPostLedgerStepAdapter(ledger RuntimeLedgerAdapter) *PostLedgerStepAdapter {
	return &PostLedgerStepAdapter{ledger: ledger}
}

func (a *PostLedgerStepAdapter) StepKind() FlowStepKind {
	return FlowStepPostLedger
}

func (a *PostLedgerStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if a.ledger == nil {
		return RuntimeFlowStep{}, ErrLedgerAdapterRequired
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := a.ledger.PostLedger(ctx, plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "ledger posted"), nil
}

type PublishEventStepAdapter struct {
	publisher RuntimePublisherAdapter
}

func NewPublishEventStepAdapter(publisher RuntimePublisherAdapter) *PublishEventStepAdapter {
	return &PublishEventStepAdapter{publisher: publisher}
}

func (a *PublishEventStepAdapter) StepKind() FlowStepKind {
	return FlowStepPublishEvent
}

func (a *PublishEventStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if err := validateAdapterContext(ctx); err != nil {
		return RuntimeFlowStep{}, err
	}

	if a.publisher == nil {
		return RuntimeFlowStep{}, ErrPublisherAdapterRequired
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := a.publisher.PublishRuntimeEvent(ctx, plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	return completeAdapterStep(step, "runtime event published"), nil
}

func NewRuntimeStepAdapterRegistry(ports RuntimeStepAdapterPorts) (*DefaultRuntimeFlowAdapterRegistry, error) {
	registry := NewDefaultRuntimeFlowAdapterRegistry()

	adapters := []RuntimeFlowStepAdapter{
		NewValidateRequestStepAdapter(),
		NewPersistDocumentStepAdapter(ports.Document),
		NewCalculateTaxStepAdapter(ports.Tax),
		NewCashBankPaymentStepAdapter(ports.CashBank),
		NewPostJournalStepAdapter(ports.Journal),
		NewPostLedgerStepAdapter(ports.Ledger),
		NewPublishEventStepAdapter(ports.Publisher),
	}

	for _, adapter := range adapters {
		if err := registry.Register(adapter); err != nil {
			return nil, err
		}
	}

	return registry, nil
}

func completeAdapterStep(step RuntimeFlowStep, message string) RuntimeFlowStep {
	now := time.Now().UTC()

	if step.StartedAt.IsZero() {
		step.StartedAt = now
	}

	step.CompletedAt = now
	step.Status = FlowStepStatusCompleted
	step.Message = message

	return step
}

func validateAdapterContext(ctx context.Context) error {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return nil
	}
}
