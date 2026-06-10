package plugins

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ApplyPluginLifecycleCommand struct {
	TenantID    string
	PluginKey   string
	ActionType  string
	RequestedBy string
	Reason      string
}

type ApplyPluginLifecycleResult struct {
	PluginKey       string
	ActionType      string
	LifecycleStatus string
	RuntimeEnabled  bool
	Applied         bool
}

type PluginLifecycleStore interface {
	ApplyPluginLifecycle(ctx context.Context, cmd ApplyPluginLifecycleCommand) (ApplyPluginLifecycleResult, error)
}

type ApplyPluginLifecycleUsecase struct {
	store PluginLifecycleStore
	nowFn func() time.Time
}

func NewApplyPluginLifecycleUsecase(store PluginLifecycleStore) *ApplyPluginLifecycleUsecase {
	return &ApplyPluginLifecycleUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ApplyPluginLifecycleUsecase) Apply(ctx context.Context, req ApplyPluginLifecycleRequest) (ApplyPluginLifecycleResponse, error) {
	if u == nil || u.store == nil {
		return ApplyPluginLifecycleResponse{}, errors.New("plugin lifecycle usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.PluginKey = strings.TrimSpace(req.PluginKey)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.Reason = strings.TrimSpace(req.Reason)

	if err := req.Validate(); err != nil {
		return ApplyPluginLifecycleResponse{}, err
	}

	result, err := u.store.ApplyPluginLifecycle(ctx, ApplyPluginLifecycleCommand{
		TenantID:    req.TenantID,
		PluginKey:   req.PluginKey,
		ActionType:  req.ActionType,
		RequestedBy: req.RequestedBy,
		Reason:      req.Reason,
	})
	if err != nil {
		return ApplyPluginLifecycleResponse{}, err
	}

	lifecycleStatus, runtimeEnabled := resolveFallbackPluginLifecycle(req.ActionType)
	if strings.TrimSpace(result.LifecycleStatus) != "" {
		lifecycleStatus = strings.TrimSpace(result.LifecycleStatus)
		runtimeEnabled = result.RuntimeEnabled
	}

	applied := result.Applied
	if !applied {
		applied = true
	}

	resp := ApplyPluginLifecycleResponse{
		PluginKey:       firstNonEmpty(strings.TrimSpace(result.PluginKey), req.PluginKey),
		ActionType:      firstNonEmpty(strings.TrimSpace(result.ActionType), req.ActionType),
		LifecycleStatus: lifecycleStatus,
		RuntimeEnabled:  runtimeEnabled,
		Applied:         applied,
		Reason:          req.Reason,
		RequestedBy:     req.RequestedBy,
		AppliedAt:       u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return ApplyPluginLifecycleResponse{}, err
	}

	return resp, nil
}

func resolveFallbackPluginLifecycle(actionType string) (string, bool) {
	switch strings.TrimSpace(actionType) {
	case "activate", "resume":
		return "active", true
	case "deactivate":
		return "inactive", false
	case "suspend":
		return "suspended", false
	default:
		return "", false
	}
}
