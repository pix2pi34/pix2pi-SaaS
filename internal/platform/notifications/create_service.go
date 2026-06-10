package notifications

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type CreateNotificationCommand struct {
	TenantID        string
	Channel         string
	NotificationKey string
	RecipientRef    string
	Subject         string
	MessageBody     string
	TemplateRef     string
	Priority        string
	DedupKey        string
	ScheduledAt     *time.Time
	RequestedBy     string
	Metadata        map[string]any
}

type CreateNotificationResult struct {
	NotificationID string
	Status         string
	DedupMatched   bool
	ScheduledAt    *time.Time
}

type CreateNotificationStore interface {
	CreateNotification(ctx context.Context, cmd CreateNotificationCommand) (CreateNotificationResult, error)
}

type CreateNotificationUsecase struct {
	store CreateNotificationStore
	nowFn func() time.Time
}

func NewCreateNotificationUsecase(store CreateNotificationStore) *CreateNotificationUsecase {
	return &CreateNotificationUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *CreateNotificationUsecase) Create(ctx context.Context, req CreateNotificationRequest) (CreateNotificationResponse, error) {
	if u == nil || u.store == nil {
		return CreateNotificationResponse{}, errors.New("create notification usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.Channel = strings.TrimSpace(req.Channel)
	req.NotificationKey = strings.TrimSpace(req.NotificationKey)
	req.RecipientRef = strings.TrimSpace(req.RecipientRef)
	req.Subject = strings.TrimSpace(req.Subject)
	req.MessageBody = strings.TrimSpace(req.MessageBody)
	req.TemplateRef = strings.TrimSpace(req.TemplateRef)
	req.Priority = strings.TrimSpace(req.Priority)
	req.DedupKey = strings.TrimSpace(req.DedupKey)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return CreateNotificationResponse{}, err
	}

	result, err := u.store.CreateNotification(ctx, CreateNotificationCommand{
		TenantID:        req.TenantID,
		Channel:         req.Channel,
		NotificationKey: req.NotificationKey,
		RecipientRef:    req.RecipientRef,
		Subject:         req.Subject,
		MessageBody:     req.MessageBody,
		TemplateRef:     req.TemplateRef,
		Priority:        req.Priority,
		DedupKey:        req.DedupKey,
		ScheduledAt:     cloneTimePtr(req.ScheduledAt),
		RequestedBy:     req.RequestedBy,
		Metadata:        cloneMap(req.Metadata),
	})
	if err != nil {
		return CreateNotificationResponse{}, err
	}

	notificationID := strings.TrimSpace(result.NotificationID)
	if notificationID == "" {
		notificationID = uuid.NewString()
	}

	status := strings.TrimSpace(result.Status)
	if status == "" {
		if req.ScheduledAt != nil {
			status = "scheduled"
		} else {
			status = "queued"
		}
	}

	scheduledAt := cloneTimePtr(result.ScheduledAt)
	if scheduledAt == nil {
		scheduledAt = cloneTimePtr(req.ScheduledAt)
	}

	resp := CreateNotificationResponse{
		NotificationID:  notificationID,
		Channel:         req.Channel,
		NotificationKey: req.NotificationKey,
		RecipientRef:    req.RecipientRef,
		Priority:        req.Priority,
		Status:          status,
		DedupMatched:    result.DedupMatched,
		ScheduledAt:     scheduledAt,
		EnqueuedAt:      u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return CreateNotificationResponse{}, err
	}

	return resp, nil
}

func cloneMap(in map[string]any) map[string]any {
	if len(in) == 0 {
		return map[string]any{}
	}

	out := make(map[string]any, len(in))
	for k, v := range in {
		out[k] = v
	}

	return out
}

func cloneTimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}

	t := in.UTC()
	return &t
}
