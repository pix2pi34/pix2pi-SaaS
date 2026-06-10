package e2eflow

import "context"

type RuntimeDocumentAdapter interface {
	PersistDocument(ctx context.Context, plan RuntimeFlowPlan) error
}

type RuntimeTaxAdapter interface {
	CalculateTax(ctx context.Context, plan RuntimeFlowPlan) error
}

type RuntimeCashBankAdapter interface {
	ExecuteCashBankPayment(ctx context.Context, plan RuntimeFlowPlan) error
}

type RuntimeJournalAdapter interface {
	PostJournal(ctx context.Context, plan RuntimeFlowPlan) error
}

type RuntimeLedgerAdapter interface {
	PostLedger(ctx context.Context, plan RuntimeFlowPlan) error
}

type RuntimePublisherAdapter interface {
	PublishRuntimeEvent(ctx context.Context, plan RuntimeFlowPlan) error
}

type RuntimeStepAdapterPorts struct {
	Document  RuntimeDocumentAdapter
	Tax       RuntimeTaxAdapter
	CashBank  RuntimeCashBankAdapter
	Journal   RuntimeJournalAdapter
	Ledger    RuntimeLedgerAdapter
	Publisher RuntimePublisherAdapter
}
