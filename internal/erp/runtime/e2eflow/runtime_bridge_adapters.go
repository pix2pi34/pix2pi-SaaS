package e2eflow

import "context"

type RuntimeBridgeHandler func(ctx context.Context, plan RuntimeFlowPlan) error

type RuntimeBridgeHandlers struct {
	PersistDocument        RuntimeBridgeHandler
	CalculateTax           RuntimeBridgeHandler
	ExecuteCashBankPayment RuntimeBridgeHandler
	PostJournal            RuntimeBridgeHandler
	PostLedger             RuntimeBridgeHandler
	PublishRuntimeEvent    RuntimeBridgeHandler
}

type RuntimeBridgeDocumentAdapter struct {
	handler RuntimeBridgeHandler
}

func NewRuntimeBridgeDocumentAdapter(handler RuntimeBridgeHandler) *RuntimeBridgeDocumentAdapter {
	return &RuntimeBridgeDocumentAdapter{handler: handler}
}

func (a *RuntimeBridgeDocumentAdapter) PersistDocument(ctx context.Context, plan RuntimeFlowPlan) error {
	if a.handler == nil {
		return ErrRuntimeBridgeHandlerRequired
	}

	return a.handler(ctx, plan)
}

type RuntimeBridgeTaxAdapter struct {
	handler RuntimeBridgeHandler
}

func NewRuntimeBridgeTaxAdapter(handler RuntimeBridgeHandler) *RuntimeBridgeTaxAdapter {
	return &RuntimeBridgeTaxAdapter{handler: handler}
}

func (a *RuntimeBridgeTaxAdapter) CalculateTax(ctx context.Context, plan RuntimeFlowPlan) error {
	if a.handler == nil {
		return ErrRuntimeBridgeHandlerRequired
	}

	return a.handler(ctx, plan)
}

type RuntimeBridgeCashBankAdapter struct {
	handler RuntimeBridgeHandler
}

func NewRuntimeBridgeCashBankAdapter(handler RuntimeBridgeHandler) *RuntimeBridgeCashBankAdapter {
	return &RuntimeBridgeCashBankAdapter{handler: handler}
}

func (a *RuntimeBridgeCashBankAdapter) ExecuteCashBankPayment(ctx context.Context, plan RuntimeFlowPlan) error {
	if a.handler == nil {
		return ErrRuntimeBridgeHandlerRequired
	}

	return a.handler(ctx, plan)
}

type RuntimeBridgeJournalAdapter struct {
	handler RuntimeBridgeHandler
}

func NewRuntimeBridgeJournalAdapter(handler RuntimeBridgeHandler) *RuntimeBridgeJournalAdapter {
	return &RuntimeBridgeJournalAdapter{handler: handler}
}

func (a *RuntimeBridgeJournalAdapter) PostJournal(ctx context.Context, plan RuntimeFlowPlan) error {
	if a.handler == nil {
		return ErrRuntimeBridgeHandlerRequired
	}

	return a.handler(ctx, plan)
}

type RuntimeBridgeLedgerAdapter struct {
	handler RuntimeBridgeHandler
}

func NewRuntimeBridgeLedgerAdapter(handler RuntimeBridgeHandler) *RuntimeBridgeLedgerAdapter {
	return &RuntimeBridgeLedgerAdapter{handler: handler}
}

func (a *RuntimeBridgeLedgerAdapter) PostLedger(ctx context.Context, plan RuntimeFlowPlan) error {
	if a.handler == nil {
		return ErrRuntimeBridgeHandlerRequired
	}

	return a.handler(ctx, plan)
}

type RuntimeBridgePublisherAdapter struct {
	handler RuntimeBridgeHandler
}

func NewRuntimeBridgePublisherAdapter(handler RuntimeBridgeHandler) *RuntimeBridgePublisherAdapter {
	return &RuntimeBridgePublisherAdapter{handler: handler}
}

func (a *RuntimeBridgePublisherAdapter) PublishRuntimeEvent(ctx context.Context, plan RuntimeFlowPlan) error {
	if a.handler == nil {
		return ErrRuntimeBridgeHandlerRequired
	}

	return a.handler(ctx, plan)
}

func NewRuntimeBridgePorts(handlers RuntimeBridgeHandlers) RuntimeStepAdapterPorts {
	return RuntimeStepAdapterPorts{
		Document:  NewRuntimeBridgeDocumentAdapter(handlers.PersistDocument),
		Tax:       NewRuntimeBridgeTaxAdapter(handlers.CalculateTax),
		CashBank:  NewRuntimeBridgeCashBankAdapter(handlers.ExecuteCashBankPayment),
		Journal:   NewRuntimeBridgeJournalAdapter(handlers.PostJournal),
		Ledger:    NewRuntimeBridgeLedgerAdapter(handlers.PostLedger),
		Publisher: NewRuntimeBridgePublisherAdapter(handlers.PublishRuntimeEvent),
	}
}

func NewRuntimeBridgeStepAdapterRegistry(handlers RuntimeBridgeHandlers) (*DefaultRuntimeFlowAdapterRegistry, error) {
	return NewRuntimeStepAdapterRegistry(NewRuntimeBridgePorts(handlers))
}
