package notifications

import (
	"context"
	"errors"
	"strings"
	"time"
)

type UpdateNotificationDeliveryCommand struct {
	TenantID           string
	NotificationID     string
	WorkerID           string
	Status             string
	AttemptNo          int
	DeliveryRef        string
	ProviderCode       string
	ErrorCode          string
	LeaseExtendSeconds int
}

type UpdateNotificationDeliveryResult struct {
	NotificationID string
	Status         string
	AttemptNo      int
	DeliveryRef    string
	ProviderCode   string
	ErrorCode      string
	LeaseExpiresAt *time.Time
}

type UpdateNotificationDeliveryStore interface {
	UpdateNotificationDelivery(ctx context.Context, cmd UpdateNotificationDeliveryCommand) (UpdateNotificationDeliveryResult, error)
}

type UpdateNotificationDeliveryUsecase struct {
	store UpdateNotificationDeliveryStore
	nowFn func() time.Time
}

func NewUpdateNotificationDeliveryUsecase(store UpdateNotificationDeliveryStore) *UpdateNotificationDeliveryUsecase {
	return &UpdateNotificationDeliveryUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *UpdateNotificationDeliveryUsecase) Update(ctx context.Context, req UpdateNotificationDeliveryRequest) (UpdateNotificationDeliveryResponse, error) {
	if u == nil || u.store == nil {
		return UpdateNotificationDeliveryResponse{}, errors.New("update notification delivery usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.NotificationID = strings.TrimSpace(req.NotificationID)
	req.WorkerID = strings.TrimSpace(req.WorkerID)
	req.Status = strings.TrimSpace(req.Status)
	req.DeliveryRef = strings.TrimSpace(req.DeliveryRef)
	req.ProviderCode = strings.TrimSpace(req.ProviderCode)
	req.ErrorCode = strings.TrimSpace(req.ErrorCode)

	if err := req.Validate(); err != nil {
		return UpdateNotificationDeliveryResponse{}, err
	}

	result, err := u.store.UpdateNotificationDelivery(ctx, UpdateNotificationDeliveryCommand{
		TenantID:           req.TenantID,
		NotificationID:     req.NotificationID,
		WorkerID:           req.WorkerID,
		Status:             req.Status,
		AttemptNo:          req.AttemptNo,
		DeliveryRef:        req.DeliveryRef,
		ProviderCode:       req.ProviderCode,
		ErrorCode:          req.ErrorCode,
		LeaseExtendSeconds: req.LeaseExtendSeconds,
	})
	if err != nil {
		return UpdateNotificationDeliveryResponse{}, err
	}

	resp := UpdateNotificationDeliveryResponse{
		NotificationID: firstNonEmpty(strings.TrimSpace(result.NotificationID), req.NotificationID),
		WorkerID:       req.WorkerID,
		Status:         firstNonEmpty(strings.TrimSpace(result.Status), req.Status),
		AttemptNo:      firstNonZero(result.AttemptNo, req.AttemptNo),
		DeliveryRef:    firstNonEmpty(strings.TrimSpace(result.DeliveryRef), req.DeliveryRef),
		ProviderCode:   firstNonEmpty(strings.TrimSpace(result.ProviderCode), req.ProviderCode),
		ErrorCode:      firstNonEmpty(strings.TrimSpace(result.ErrorCode), req.ErrorCode),
		LeaseExpiresAt: cloneTimePtr(result.LeaseExpiresAt),
		UpdatedAt:      u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return UpdateNotificationDeliveryResponse{}, err
	}

	return resp, nil
}

func firstNonZero(values ...int) int {
	for _, v := range values {
		if v != 0 {
			return v
		}
	}
	return 0
}
