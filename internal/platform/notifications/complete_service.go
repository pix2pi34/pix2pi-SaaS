package notifications

import (
	"context"
	"errors"
	"strings"
	"time"
)

type CompleteNotificationDeliveryCommand struct {
	TenantID       string
	NotificationID string
	WorkerID       string
	Status         string
	AttemptNo      int
	DeliveryRef    string
	ProviderCode   string
	ErrorCode      string
	CompletionNote string
}

type CompleteNotificationDeliveryResult struct {
	NotificationID string
	Status         string
	AttemptNo      int
	DeliveryRef    string
	ProviderCode   string
	ErrorCode      string
	CompletionNote string
	LeaseReleased  bool
}

type CompleteNotificationDeliveryStore interface {
	CompleteNotificationDelivery(ctx context.Context, cmd CompleteNotificationDeliveryCommand) (CompleteNotificationDeliveryResult, error)
}

type CompleteNotificationDeliveryUsecase struct {
	store CompleteNotificationDeliveryStore
	nowFn func() time.Time
}

func NewCompleteNotificationDeliveryUsecase(store CompleteNotificationDeliveryStore) *CompleteNotificationDeliveryUsecase {
	return &CompleteNotificationDeliveryUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *CompleteNotificationDeliveryUsecase) Complete(ctx context.Context, req CompleteNotificationDeliveryRequest) (CompleteNotificationDeliveryResponse, error) {
	if u == nil || u.store == nil {
		return CompleteNotificationDeliveryResponse{}, errors.New("complete notification delivery usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.NotificationID = strings.TrimSpace(req.NotificationID)
	req.WorkerID = strings.TrimSpace(req.WorkerID)
	req.Status = strings.TrimSpace(req.Status)
	req.DeliveryRef = strings.TrimSpace(req.DeliveryRef)
	req.ProviderCode = strings.TrimSpace(req.ProviderCode)
	req.ErrorCode = strings.TrimSpace(req.ErrorCode)
	req.CompletionNote = strings.TrimSpace(req.CompletionNote)

	if err := req.Validate(); err != nil {
		return CompleteNotificationDeliveryResponse{}, err
	}

	result, err := u.store.CompleteNotificationDelivery(ctx, CompleteNotificationDeliveryCommand{
		TenantID:       req.TenantID,
		NotificationID: req.NotificationID,
		WorkerID:       req.WorkerID,
		Status:         req.Status,
		AttemptNo:      req.AttemptNo,
		DeliveryRef:    req.DeliveryRef,
		ProviderCode:   req.ProviderCode,
		ErrorCode:      req.ErrorCode,
		CompletionNote: req.CompletionNote,
	})
	if err != nil {
		return CompleteNotificationDeliveryResponse{}, err
	}

	leaseReleased := result.LeaseReleased
	if !leaseReleased {
		leaseReleased = true
	}

	resp := CompleteNotificationDeliveryResponse{
		NotificationID: firstNonEmpty(strings.TrimSpace(result.NotificationID), req.NotificationID),
		WorkerID:       req.WorkerID,
		Status:         firstNonEmpty(strings.TrimSpace(result.Status), req.Status),
		AttemptNo:      firstNonZero(result.AttemptNo, req.AttemptNo),
		DeliveryRef:    firstNonEmpty(strings.TrimSpace(result.DeliveryRef), req.DeliveryRef),
		ProviderCode:   firstNonEmpty(strings.TrimSpace(result.ProviderCode), req.ProviderCode),
		ErrorCode:      firstNonEmpty(strings.TrimSpace(result.ErrorCode), req.ErrorCode),
		CompletionNote: firstNonEmpty(strings.TrimSpace(result.CompletionNote), req.CompletionNote),
		LeaseReleased:  leaseReleased,
		CompletedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return CompleteNotificationDeliveryResponse{}, err
	}

	return resp, nil
}
