package plugins

import (
	"context"
	"errors"
	"regexp"
	"strings"
	"time"
)

var (
	pluginKeyPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	actorRefPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

type LoadPluginCommand struct {
	TenantID    string
	PluginKey   string
	RequestedBy string
}

type LoadPluginResult struct {
	PluginKey         string
	Version           int
	RuntimeMode       string
	EntrypointRef     string
	PermissionProfile string
	SandboxRequired   bool
	Loaded            bool
}

type PluginLoaderStore interface {
	LoadPlugin(ctx context.Context, cmd LoadPluginCommand) (LoadPluginResult, error)
}

type LoadPluginUsecase struct {
	store PluginLoaderStore
	nowFn func() time.Time
}

func NewLoadPluginUsecase(store PluginLoaderStore) *LoadPluginUsecase {
	return &LoadPluginUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *LoadPluginUsecase) Load(ctx context.Context, req LoadPluginRequest) (LoadPluginResponse, error) {
	if u == nil || u.store == nil {
		return LoadPluginResponse{}, errors.New("plugin loader usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.PluginKey = strings.TrimSpace(req.PluginKey)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return LoadPluginResponse{}, err
	}

	result, err := u.store.LoadPlugin(ctx, LoadPluginCommand{
		TenantID:    req.TenantID,
		PluginKey:   req.PluginKey,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return LoadPluginResponse{}, err
	}

	resp := LoadPluginResponse{
		PluginKey:         firstNonEmpty(strings.TrimSpace(result.PluginKey), req.PluginKey),
		Version:           result.Version,
		RuntimeMode:       strings.TrimSpace(result.RuntimeMode),
		EntrypointRef:     strings.TrimSpace(result.EntrypointRef),
		PermissionProfile: strings.TrimSpace(result.PermissionProfile),
		SandboxRequired:   result.SandboxRequired,
		Loaded:            result.Loaded,
		LoadedAt:          u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return LoadPluginResponse{}, err
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
