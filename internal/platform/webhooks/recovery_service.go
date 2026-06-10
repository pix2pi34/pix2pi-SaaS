package webhooks

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ApplyWebhookRecoveryCommand struct {
	TenantID      string
	WebhookID     string
	DeliveryRef   string
	ActionType    string
	RequestedBy   string
	Reason        string
	ResetAttempts bool
	NextAttemptAt *time.Time
}

type ApplyWebhookRecoveryResult struct {
	WebhookID      string
	DeliveryRef   string
	ActionType    string
	Status        string
	AttemptNo     int
	NextAttemptAt *time.Time
	LeaseReleased bool
}

type WebhookRecoveryStore interface {
	ApplyRecovery(ctx context.Context, cmd ApplyWebhookRecoveryCommand) (ApplyWebhookRecoveryResult, error)
}

type ApplyWebhookRecoveryUsecase struct {
	store WebhookRecoveryStore
	nowFn func() time.Time
}

func NewApplyWebhookRecoveryUsecase(store WebhookRecoveryStore) *ApplyWebhookRecoveryUsecase {
	return &ApplyWebhookRecoveryUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ApplyWebhookRecoveryUsecase) Apply(ctx context.Context, req ApplyWebhookRecoveryRequest) (ApplyWebhookRecoveryResponse, error) {
	if u == nil || u.store == nil {
		return ApplyWebhookRecoveryResponse{}, errors.New("webhook recovery usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WebhookID = strings.TrimSpace(req.WebhookID)
	req.DeliveryRef = strings.TrimSpace(req.DeliveryRef)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.Reason = strings.TrimSpace(req.Reason)
	req.NextAttemptAt = cloneWebhookTimePtr(req.NextAttemptAt)

	if err := req.Validate(); err != nil {
		return ApplyWebhookRecoveryResponse{}, err
	}

	result, err := u.store.ApplyRecovery(ctx, ApplyWebhookRecoveryCommand{
		TenantID:      req.TenantID,
		WebhookID:     req.WebhookID,
		DeliveryRef:   req.DeliveryRef,
		ActionType:    req.ActionType,
		RequestedBy:   req.RequestedBy,
		Reason:        req.Reason,
		ResetAttempts: req.ResetAttempts,
		NextAttemptAt: cloneWebhookTimePtr(req.NextAttemptAt),
	})
	if err != nil {
		return ApplyWebhookRecoveryResponse{}, err
	}

	status := strings.TrimSpace(result.Status)
	if status == "" {
		status = resolveFallbackWebhookRecoveryStatus(req.ActionType)
	}

	attemptNo := result.AttemptNo
	if req.ResetAttempts && attemptNo == 0 {
		attemptNo = 0
	}

	nextAttemptAt := cloneWebhookTimePtr(result.NextAttemptAt)
	if nextAttemptAt == nil {
		nextAttemptAt = cloneWebhookTimePtr(req.NextAttemptAt)
	}

	leaseReleased := result.LeaseReleased
	if !leaseReleased {
		leaseReleased = true
	}

	resp := ApplyWebhookRecoveryResponse{
		WebhookID:      firstNonEmpty(strings.TrimSpace(result.WebhookID), req.WebhookID),
		DeliveryRef:    firstNonEmpty(strings.TrimSpace(result.DeliveryRef), req.DeliveryRef),
		ActionType:     firstNonEmpty(strings.TrimSpace(result.ActionType), req.ActionType),
		Status:         status,
		AttemptNo:      attemptNo,
		NextAttemptAt:  nextAttemptAt,
		LeaseReleased:  leaseReleased,
		RequestedBy:    req.RequestedBy,
		Reason:         req.Reason,
		RequestedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return ApplyWebhookRecoveryResponse{}, err
	}

	return resp, nil
}

func resolveFallbackWebhookRecoveryStatus(actionType string) string {
	switch strings.TrimSpace(actionType) {
	case "retry", "requeue":
		return "pending"
	case "dead_letter":
		return "dead_letter"
	default:
		return ""
	}
}

func cloneWebhookTimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}
	t := in.UTC()
	return &t
}
