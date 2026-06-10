package plugins

import (
	"context"
	"errors"
	"strings"
	"time"
)

type CheckPluginVersionCompatibilityCommand struct {
	TenantID       string
	PluginKey      string
	PluginVersion  int
	RuntimeMode    string
	HostAPIVersion int
	RequestedBy    string
}

type CheckPluginVersionCompatibilityResult struct {
	PluginKey               string
	PluginVersion           int
	RuntimeMode             string
	HostAPIVersion          int
	MinSupportedHostVersion int
	MaxSupportedHostVersion int
	CompatibilityStatus     string
	Compatible              bool
	Reason                  string
}

type PluginVersionCompatibilityStore interface {
	CheckVersionCompatibility(ctx context.Context, cmd CheckPluginVersionCompatibilityCommand) (CheckPluginVersionCompatibilityResult, error)
}

type CheckPluginVersionCompatibilityUsecase struct {
	store PluginVersionCompatibilityStore
	nowFn func() time.Time
}

func NewCheckPluginVersionCompatibilityUsecase(store PluginVersionCompatibilityStore) *CheckPluginVersionCompatibilityUsecase {
	return &CheckPluginVersionCompatibilityUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *CheckPluginVersionCompatibilityUsecase) Check(ctx context.Context, req CheckPluginVersionCompatibilityRequest) (CheckPluginVersionCompatibilityResponse, error) {
	if u == nil || u.store == nil {
		return CheckPluginVersionCompatibilityResponse{}, errors.New("plugin version compatibility usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.PluginKey = strings.TrimSpace(req.PluginKey)
	req.RuntimeMode = strings.TrimSpace(req.RuntimeMode)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return CheckPluginVersionCompatibilityResponse{}, err
	}

	result, err := u.store.CheckVersionCompatibility(ctx, CheckPluginVersionCompatibilityCommand{
		TenantID:       req.TenantID,
		PluginKey:      req.PluginKey,
		PluginVersion:  req.PluginVersion,
		RuntimeMode:    req.RuntimeMode,
		HostAPIVersion: req.HostAPIVersion,
		RequestedBy:    req.RequestedBy,
	})
	if err != nil {
		return CheckPluginVersionCompatibilityResponse{}, err
	}

	minSupported, maxSupported := resolveFallbackPluginCompatibilityRange(req.PluginVersion, req.HostAPIVersion, req.RuntimeMode)
	if result.MinSupportedHostVersion != 0 {
		minSupported = result.MinSupportedHostVersion
	}
	if result.MaxSupportedHostVersion != 0 {
		maxSupported = result.MaxSupportedHostVersion
	}

	status, compatible, reason := evaluatePluginCompatibilityRange(req.HostAPIVersion, minSupported, maxSupported)

	if strings.TrimSpace(result.CompatibilityStatus) != "" {
		status = strings.TrimSpace(result.CompatibilityStatus)
	}
	if result.Compatible {
		compatible = true
		if status == "" {
			status = "compatible"
		}
		reason = ""
	}
	if strings.TrimSpace(result.Reason) != "" {
		reason = strings.TrimSpace(result.Reason)
		if !result.Compatible {
			compatible = false
			if status == "" {
				status = "blocked"
			}
		}
	}

	resp := CheckPluginVersionCompatibilityResponse{
		PluginKey:               firstNonEmpty(strings.TrimSpace(result.PluginKey), req.PluginKey),
		PluginVersion:           firstNonZeroPluginInt(result.PluginVersion, req.PluginVersion),
		RuntimeMode:             firstNonEmpty(strings.TrimSpace(result.RuntimeMode), req.RuntimeMode),
		HostAPIVersion:          firstNonZeroPluginInt(result.HostAPIVersion, req.HostAPIVersion),
		MinSupportedHostVersion: minSupported,
		MaxSupportedHostVersion: maxSupported,
		CompatibilityStatus:     status,
		Compatible:              compatible,
		Reason:                  reason,
		CheckedAt:               u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return CheckPluginVersionCompatibilityResponse{}, err
	}

	return resp, nil
}

func resolveFallbackPluginCompatibilityRange(pluginVersion, hostAPIVersion int, runtimeMode string) (int, int) {
	switch strings.TrimSpace(runtimeMode) {
	case "native":
		return pluginVersion, pluginVersion
	case "wasm":
		minSupported := pluginVersion - 1
		if minSupported < 1 {
			minSupported = 1
		}
		return minSupported, pluginVersion + 1
	case "http_bridge":
		maxSupported := pluginVersion + 2
		if maxSupported < hostAPIVersion {
			maxSupported = hostAPIVersion
		}
		return 1, maxSupported
	default:
		return pluginVersion, pluginVersion
	}
}

func evaluatePluginCompatibilityRange(hostAPIVersion, minSupported, maxSupported int) (string, bool, string) {
	switch {
	case hostAPIVersion < minSupported || hostAPIVersion > maxSupported:
		return "blocked", false, "host api surumu destek araligi disinda"
	case hostAPIVersion == maxSupported:
		return "warning", true, "desteklenen ust sinirda calisiyor"
	default:
		return "compatible", true, ""
	}
}

func firstNonZeroPluginInt(values ...int) int {
	for _, v := range values {
		if v != 0 {
			return v
		}
	}
	return 0
}
