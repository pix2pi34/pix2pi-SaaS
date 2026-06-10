package plugins

import (
	"context"
	"errors"
	"strings"
	"time"
)

type EvaluatePluginPermissionCommand struct {
	TenantID          string
	PluginKey         string
	PermissionProfile string
	Operation         string
	ResourceScope     string
	RequestedBy       string
}

type EvaluatePluginPermissionResult struct {
	PluginKey         string
	PermissionProfile string
	Operation         string
	ResourceScope     string
	Permitted         bool
	DenialReason      string
}

type PluginPermissionStore interface {
	EvaluatePermission(ctx context.Context, cmd EvaluatePluginPermissionCommand) (EvaluatePluginPermissionResult, error)
}

type EvaluatePluginPermissionUsecase struct {
	store PluginPermissionStore
	nowFn func() time.Time
}

func NewEvaluatePluginPermissionUsecase(store PluginPermissionStore) *EvaluatePluginPermissionUsecase {
	return &EvaluatePluginPermissionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *EvaluatePluginPermissionUsecase) Evaluate(ctx context.Context, req EvaluatePluginPermissionRequest) (EvaluatePluginPermissionResponse, error) {
	if u == nil || u.store == nil {
		return EvaluatePluginPermissionResponse{}, errors.New("plugin permission usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.PluginKey = strings.TrimSpace(req.PluginKey)
	req.PermissionProfile = strings.TrimSpace(req.PermissionProfile)
	req.Operation = strings.TrimSpace(req.Operation)
	req.ResourceScope = strings.TrimSpace(req.ResourceScope)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return EvaluatePluginPermissionResponse{}, err
	}

	result, err := u.store.EvaluatePermission(ctx, EvaluatePluginPermissionCommand{
		TenantID:          req.TenantID,
		PluginKey:         req.PluginKey,
		PermissionProfile: req.PermissionProfile,
		Operation:         req.Operation,
		ResourceScope:     req.ResourceScope,
		RequestedBy:       req.RequestedBy,
	})
	if err != nil {
		return EvaluatePluginPermissionResponse{}, err
	}

	permitted, denialReason := resolveFallbackPluginPermission(
		firstNonEmpty(strings.TrimSpace(result.PermissionProfile), req.PermissionProfile),
		firstNonEmpty(strings.TrimSpace(result.Operation), req.Operation),
		firstNonEmpty(strings.TrimSpace(result.ResourceScope), req.ResourceScope),
	)

	if result.Permitted {
		permitted = true
		denialReason = ""
	} else if strings.TrimSpace(result.DenialReason) != "" {
		permitted = false
		denialReason = strings.TrimSpace(result.DenialReason)
	}

	resp := EvaluatePluginPermissionResponse{
		PluginKey:         firstNonEmpty(strings.TrimSpace(result.PluginKey), req.PluginKey),
		PermissionProfile: firstNonEmpty(strings.TrimSpace(result.PermissionProfile), req.PermissionProfile),
		Operation:         firstNonEmpty(strings.TrimSpace(result.Operation), req.Operation),
		ResourceScope:     firstNonEmpty(strings.TrimSpace(result.ResourceScope), req.ResourceScope),
		Permitted:         permitted,
		DenialReason:      denialReason,
		EvaluatedAt:       u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return EvaluatePluginPermissionResponse{}, err
	}

	return resp, nil
}

func resolveFallbackPluginPermission(profile, operation, resourceScope string) (bool, string) {
	profile = strings.TrimSpace(profile)
	operation = strings.TrimSpace(operation)
	resourceScope = strings.TrimSpace(resourceScope)

	switch profile {
	case "system_ops":
		return true, ""
	case "tenant_ops":
		if resourceScope == "tenant_data" || resourceScope == "tenant_runtime" {
			if operation == "read" || operation == "write" || operation == "execute" {
				return true, ""
			}
		}
		return false, "tenant_ops profili bu islem veya scope icin yetkisiz"
	case "read_only":
		if operation == "read" && resourceScope == "tenant_data" {
			return true, ""
		}
		return false, "read_only profili sadece tenant_data read izni verir"
	default:
		return false, "yetki profili tanimsiz"
	}
}
