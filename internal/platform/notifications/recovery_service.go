package notifications

import (
	"context"
	"errors"
	"strings"
	"time"
)

type RecoverNotificationCommand struct {
	TenantID      string
	NotificationID string
	ActionType    string
	RequestedBy   string
	TargetChannel string
	Reason        string
	ResetAttempts bool
}

type RecoverNotificationResult struct {
	NotificationID string
	Status         string
	Channel        string
	AttemptNo      int
	LeaseReleased  bool
}

type RecoverNotificationStore interface {
	RecoverNotification(ctx context.Context, cmd RecoverNotificationCommand) (RecoverNotificationResult, error)
}

type RecoverNotificationUsecase struct {
	store RecoverNotificationStore
	nowFn func() time.Time
}

func NewRecoverNotificationUsecase(store RecoverNotificationStore) *RecoverNotificationUsecase {
	return &RecoverNotificationUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *RecoverNotificationUsecase) Recover(ctx context.Context, req RecoverNotificationRequest) (RecoverNotificationResponse, error) {
	if u == nil || u.store == nil {
		return RecoverNotificationResponse{}, errors.New("recover notification usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.NotificationID = strings.TrimSpace(req.NotificationID)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.TargetChannel = strings.TrimSpace(req.TargetChannel)
	req.Reason = strings.TrimSpace(req.Reason)

	if err := req.Validate(); err != nil {
		return RecoverNotificationResponse{}, err
	}

	result, err := u.store.RecoverNotification(ctx, RecoverNotificationCommand{
		TenantID:      req.TenantID,
		NotificationID: req.NotificationID,
		ActionType:    req.ActionType,
		RequestedBy:   req.RequestedBy,
		TargetChannel: req.TargetChannel,
		Reason:        req.Reason,
		ResetAttempts: req.ResetAttempts,
	})
	if err != nil {
		return RecoverNotificationResponse{}, err
	}

	status := strings.TrimSpace(result.Status)
	if status == "" {
		switch req.ActionType {
		case "dead_letter":
			status = "dead_letter"
		default:
			status = "queued"
		}
	}

	channel := firstNonEmpty(strings.TrimSpace(result.Channel), req.TargetChannel)

	attemptNo := result.AttemptNo
	if req.ResetAttempts && attemptNo == 0 {
		attemptNo = 0
	}

	leaseReleased := result.LeaseReleased
	if !leaseReleased {
		leaseReleased = true
	}

	resp := RecoverNotificationResponse{
		NotificationID: firstNonEmpty(strings.TrimSpace(result.NotificationID), req.NotificationID),
		ActionType:     req.ActionType,
		Status:         status,
		Channel:        channel,
		AttemptNo:      attemptNo,
		LeaseReleased:  leaseReleased,
		RequestedBy:    req.RequestedBy,
		Reason:         req.Reason,
		RequestedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return RecoverNotificationResponse{}, err
	}

	return resp, nil
}
