package plugins

import (
	"context"
	"errors"
	"strings"
	"time"
)

type EnsurePluginSandboxCommand struct {
	TenantID          string
	PluginKey         string
	RuntimeMode       string
	PermissionProfile string
	RequestedBy       string
}

type EnsurePluginSandboxResult struct {
	PluginKey         string
	RuntimeMode       string
	PermissionProfile string
	SandboxID         string
	IsolationMode     string
	NetworkPolicy     string
	TenantScoped      bool
	Ready             bool
	DenialReason      string
}

type PluginSandboxStore interface {
	EnsureTenantSandbox(ctx context.Context, cmd EnsurePluginSandboxCommand) (EnsurePluginSandboxResult, error)
}

type EnsurePluginSandboxUsecase struct {
	store PluginSandboxStore
	nowFn func() time.Time
}

func NewEnsurePluginSandboxUsecase(store PluginSandboxStore) *EnsurePluginSandboxUsecase {
	return &EnsurePluginSandboxUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *EnsurePluginSandboxUsecase) Ensure(ctx context.Context, req EnsurePluginSandboxRequest) (EnsurePluginSandboxResponse, error) {
	if u == nil || u.store == nil {
		return EnsurePluginSandboxResponse{}, errors.New("plugin sandbox usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.PluginKey = strings.TrimSpace(req.PluginKey)
	req.RuntimeMode = strings.TrimSpace(req.RuntimeMode)
	req.PermissionProfile = strings.TrimSpace(req.PermissionProfile)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return EnsurePluginSandboxResponse{}, err
	}

	result, err := u.store.EnsureTenantSandbox(ctx, EnsurePluginSandboxCommand{
		TenantID:          req.TenantID,
		PluginKey:         req.PluginKey,
		RuntimeMode:       req.RuntimeMode,
		PermissionProfile: req.PermissionProfile,
		RequestedBy:       req.RequestedBy,
	})
	if err != nil {
		return EnsurePluginSandboxResponse{}, err
	}

	sandboxID, isolationMode, networkPolicy, tenantScoped, ready, denialReason :=
		resolveFallbackPluginSandbox(req.PluginKey, req.RuntimeMode, req.PermissionProfile)

	if strings.TrimSpace(result.SandboxID) != "" {
		sandboxID = strings.TrimSpace(result.SandboxID)
	}
	if strings.TrimSpace(result.IsolationMode) != "" {
		isolationMode = strings.TrimSpace(result.IsolationMode)
	}
	if strings.TrimSpace(result.NetworkPolicy) != "" {
		networkPolicy = strings.TrimSpace(result.NetworkPolicy)
	}
	if result.TenantScoped {
		tenantScoped = true
	}
	if result.Ready {
		ready = true
		denialReason = ""
	}
	if strings.TrimSpace(result.DenialReason) != "" {
		ready = false
		denialReason = strings.TrimSpace(result.DenialReason)
	}

	resp := EnsurePluginSandboxResponse{
		PluginKey:         firstNonEmpty(strings.TrimSpace(result.PluginKey), req.PluginKey),
		RuntimeMode:       firstNonEmpty(strings.TrimSpace(result.RuntimeMode), req.RuntimeMode),
		PermissionProfile: firstNonEmpty(strings.TrimSpace(result.PermissionProfile), req.PermissionProfile),
		SandboxID:         sandboxID,
		IsolationMode:     isolationMode,
		NetworkPolicy:     networkPolicy,
		TenantScoped:      tenantScoped,
		Ready:             ready,
		DenialReason:      denialReason,
		CheckedAt:         u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return EnsurePluginSandboxResponse{}, err
	}

	return resp, nil
}

func resolveFallbackPluginSandbox(pluginKey, runtimeMode, permissionProfile string) (string, string, string, bool, bool, string) {
	switch {
	case strings.TrimSpace(permissionProfile) == "system_ops" && strings.TrimSpace(runtimeMode) == "native":
		return "", "", "", false, false, "system_ops native plugin tenant-safe sandbox zorunlulugunu karsilamiyor"
	case strings.TrimSpace(runtimeMode) == "wasm":
		return strings.TrimSpace(pluginKey) + "_sandbox", "tenant_process", "disabled", true, true, ""
	case strings.TrimSpace(runtimeMode) == "http_bridge":
		return strings.TrimSpace(pluginKey) + "_sandbox", "tenant_namespace", "tenant_egress_only", true, true, ""
	default:
		return strings.TrimSpace(pluginKey) + "_sandbox", "tenant_vm", "tenant_internal", true, true, ""
	}
}
