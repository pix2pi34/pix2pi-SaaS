package cashbankpay

import (
	"context"
)

var _ PaymentOrchestrator = (*DefaultPaymentOrchestrator)(nil)
var _ PaymentDraftBuilder = (*DefaultPaymentDraftBuilder)(nil)

type DefaultPaymentDraftBuilder struct{}

func NewDefaultPaymentDraftBuilder() *DefaultPaymentDraftBuilder {
	return &DefaultPaymentDraftBuilder{}
}

func (b *DefaultPaymentDraftBuilder) BuildPaymentDraft(ctx context.Context, req PaymentRequest) (PaymentDraft, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return PaymentDraft{}, ctx.Err()
	default:
	}

	return BuildPaymentDraft(req)
}

type DefaultPaymentOrchestrator struct {
	builder   PaymentDraftBuilder
	store     PaymentStore
	publisher PaymentPublisher
}

func NewDefaultPaymentOrchestrator(
	builder PaymentDraftBuilder,
	store PaymentStore,
	publisher PaymentPublisher,
) *DefaultPaymentOrchestrator {
	if builder == nil {
		builder = NewDefaultPaymentDraftBuilder()
	}

	return &DefaultPaymentOrchestrator{
		builder:   builder,
		store:     store,
		publisher: publisher,
	}
}

func (o *DefaultPaymentOrchestrator) PostPayment(ctx context.Context, req PaymentRequest) (PaymentResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return PaymentResult{}, ctx.Err()
	default:
	}

	if err := ValidatePaymentRequest(req); err != nil {
		return PaymentResult{}, err
	}

	if o.store == nil {
		return PaymentResult{}, ErrPaymentStoreRequired
	}

	draft, err := o.builder.BuildPaymentDraft(ctx, req)
	if err != nil {
		return PaymentResult{}, err
	}

	persistedDraft, err := o.store.PersistPaymentDraft(ctx, draft)
	if err != nil {
		return PaymentResult{}, err
	}

	postedDraft, err := o.store.MarkPaymentPosted(ctx, persistedDraft)
	if err != nil {
		return PaymentResult{}, err
	}

	result, err := BuildPaymentResult(req, postedDraft, "payment posted")
	if err != nil {
		return PaymentResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishPaymentPosted(ctx, result); err != nil {
			return PaymentResult{}, err
		}
	}

	return result, nil
}
