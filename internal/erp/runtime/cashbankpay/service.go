package cashbankpay

import "context"

type PaymentOrchestrator interface {
	PostPayment(ctx context.Context, req PaymentRequest) (PaymentResult, error)
}

type PaymentDraftBuilder interface {
	BuildPaymentDraft(ctx context.Context, req PaymentRequest) (PaymentDraft, error)
}

type PaymentStore interface {
	PersistPaymentDraft(ctx context.Context, draft PaymentDraft) (PaymentDraft, error)
	MarkPaymentPosted(ctx context.Context, draft PaymentDraft) (PaymentDraft, error)
}

type PaymentPublisher interface {
	PublishPaymentPosted(ctx context.Context, result PaymentResult) error
}
