package publicapi

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ResolvePublicAPIGatewayCommand struct {
	TenantID    string
	RequestID   string
	AppID       string
	APIKeyID    string
	Method      string
	Path        string
	Origin      string
	RequestedBy string
}

type ResolvePublicAPIGatewayResult struct {
	RequestID       string
	AppID           string
	APIKeyID        string
	Method          string
	Path            string
	TargetService   string
	TargetPath      string
	GatewayStatus   string
	Accepted        bool
	RejectionReason string
}

type PublicAPIGatewayStore interface {
	ResolveRoute(ctx context.Context, cmd ResolvePublicAPIGatewayCommand) (ResolvePublicAPIGatewayResult, error)
}

type ResolvePublicAPIGatewayUsecase struct {
	store PublicAPIGatewayStore
	nowFn func() time.Time
}

func NewResolvePublicAPIGatewayUsecase(store PublicAPIGatewayStore) *ResolvePublicAPIGatewayUsecase {
	return &ResolvePublicAPIGatewayUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ResolvePublicAPIGatewayUsecase) Resolve(ctx context.Context, req ResolvePublicAPIGatewayRequest) (ResolvePublicAPIGatewayResponse, error) {
	if u == nil || u.store == nil {
		return ResolvePublicAPIGatewayResponse{}, errors.New("public api gateway usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.RequestID = strings.TrimSpace(req.RequestID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.APIKeyID = strings.TrimSpace(req.APIKeyID)
	req.Method = strings.ToUpper(strings.TrimSpace(req.Method))
	req.Path = normalizePublicAPIPath(req.Path)
	req.Origin = strings.TrimSpace(req.Origin)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return ResolvePublicAPIGatewayResponse{}, err
	}

	result, err := u.store.ResolveRoute(ctx, ResolvePublicAPIGatewayCommand{
		TenantID:    req.TenantID,
		RequestID:   req.RequestID,
		AppID:       req.AppID,
		APIKeyID:    req.APIKeyID,
		Method:      req.Method,
		Path:        req.Path,
		Origin:      req.Origin,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return ResolvePublicAPIGatewayResponse{}, err
	}

	status := firstNonEmpty(strings.TrimSpace(result.GatewayStatus), "accepted")
	accepted := result.Accepted
	rejectionReason := strings.TrimSpace(result.RejectionReason)

	if status == "accepted" {
		accepted = true
		rejectionReason = ""
	}

	if status == "rejected" {
		accepted = false
		if rejectionReason == "" {
			rejectionReason = "public api route rejected"
		}
	}

	resp := ResolvePublicAPIGatewayResponse{
		RequestID:       firstNonEmpty(strings.TrimSpace(result.RequestID), req.RequestID),
		AppID:           firstNonEmpty(strings.TrimSpace(result.AppID), req.AppID),
		APIKeyID:        firstNonEmpty(strings.TrimSpace(result.APIKeyID), req.APIKeyID),
		Method:          firstNonEmpty(strings.ToUpper(strings.TrimSpace(result.Method)), req.Method),
		Path:            firstNonEmpty(normalizePublicAPIPath(result.Path), req.Path),
		TargetService:   strings.TrimSpace(result.TargetService),
		TargetPath:      normalizePublicAPIPath(result.TargetPath),
		GatewayStatus:   status,
		Accepted:        accepted,
		RejectionReason: rejectionReason,
		ResolvedAt:      u.nowFn().UTC(),
	}

	if resp.Accepted {
		if resp.TargetService == "" {
			resp.TargetService = resolveFallbackPublicAPITargetService(req.Path)
		}
		if resp.TargetPath == "" {
			resp.TargetPath = resolveFallbackPublicAPITargetPath(req.Path)
		}
	}

	if err := resp.Validate(); err != nil {
		return ResolvePublicAPIGatewayResponse{}, err
	}

	return resp, nil
}

func normalizePublicAPIPath(path string) string {
	path = strings.TrimSpace(path)
	if path == "" {
		return ""
	}

	if !strings.HasPrefix(path, "/") {
		return "/" + path
	}

	return path
}

func resolveFallbackPublicAPITargetService(path string) string {
	path = normalizePublicAPIPath(path)

	switch {
	case strings.HasPrefix(path, "/v1/erp"):
		return "erp-api"
	case strings.HasPrefix(path, "/v1/public"):
		return "public-api"
	case strings.HasPrefix(path, "/v1/developer"):
		return "developer-api"
	default:
		return "public-api"
	}
}

func resolveFallbackPublicAPITargetPath(path string) string {
	return normalizePublicAPIPath(path)
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}
