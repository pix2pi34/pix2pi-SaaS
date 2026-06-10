package notifications

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ClaimNotificationDeliveryCommand struct {
	TenantID     string
	Channel      string
	WorkerID     string
	LeaseSeconds int
}

type ClaimNotificationDeliveryResult struct {
	Claimed         bool
	NotificationID  string
	Channel         string
	NotificationKey string
	RecipientRef    string
	Subject         string
	MessageBody     string
	TemplateRef     string
	Priority        string
	Status          string
	AttemptNo       int
	LeaseExpiresAt  *time.Time
}

type ClaimNotificationDeliveryStore interface {
	ClaimNotificationForDelivery(ctx context.Context, cmd ClaimNotificationDeliveryCommand) (ClaimNotificationDeliveryResult, error)
}

type ClaimNotificationDeliveryUsecase struct {
	store ClaimNotificationDeliveryStore
	nowFn func() time.Time
}

func NewClaimNotificationDeliveryUsecase(store ClaimNotificationDeliveryStore) *ClaimNotificationDeliveryUsecase {
	return &ClaimNotificationDeliveryUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ClaimNotificationDeliveryUsecase) Claim(ctx context.Context, req ClaimNotificationDeliveryRequest) (ClaimNotificationDeliveryResponse, error) {
	if u == nil || u.store == nil {
		return ClaimNotificationDeliveryResponse{}, errors.New("claim notification delivery usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.Channel = strings.TrimSpace(req.Channel)
	req.WorkerID = strings.TrimSpace(req.WorkerID)

	if err := req.Validate(); err != nil {
		return ClaimNotificationDeliveryResponse{}, err
	}

	result, err := u.store.ClaimNotificationForDelivery(ctx, ClaimNotificationDeliveryCommand{
		TenantID:     req.TenantID,
		Channel:      req.Channel,
		WorkerID:     req.WorkerID,
		LeaseSeconds: req.LeaseSeconds,
	})
	if err != nil {
		return ClaimNotificationDeliveryResponse{}, err
	}

	resp := ClaimNotificationDeliveryResponse{
		Claimed:   result.Claimed,
		ClaimedAt: u.nowFn().UTC(),
	}

	if result.Claimed {
		resp.NotificationID = strings.TrimSpace(result.NotificationID)
		resp.Channel = firstNonEmpty(strings.TrimSpace(result.Channel), req.Channel)
		resp.NotificationKey = strings.TrimSpace(result.NotificationKey)
		resp.RecipientRef = strings.TrimSpace(result.RecipientRef)
		resp.Subject = strings.TrimSpace(result.Subject)
		resp.MessageBody = strings.TrimSpace(result.MessageBody)
		resp.TemplateRef = strings.TrimSpace(result.TemplateRef)
		resp.Priority = strings.TrimSpace(result.Priority)
		resp.Status = firstNonEmpty(strings.TrimSpace(result.Status), "sending")
		resp.AttemptNo = result.AttemptNo
		resp.WorkerID = req.WorkerID
		resp.LeaseExpiresAt = cloneTimePtr(result.LeaseExpiresAt)
	}

	if err := resp.Validate(); err != nil {
		return ClaimNotificationDeliveryResponse{}, err
	}

	return resp, nil
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}
