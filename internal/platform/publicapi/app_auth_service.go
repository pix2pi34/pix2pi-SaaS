package publicapi

import (
	"context"
	"errors"
	"strings"
	"time"
)

type AuthenticatePublicAPIAppCommand struct {
	TenantID       string
	RequestID      string
	AppID          string
	APIKeyID       string
	KeyFingerprint string
	Environment    string
	RequiredScopes []string
	RequestedBy    string
}

type AuthenticatePublicAPIAppResult struct {
	RequestID     string
	AppID         string
	APIKeyID      string
	Environment   string
	GrantedScopes []string
	AuthStatus    string
	Authenticated bool
	DenialReason  string
}

type PublicAPIAppAuthStore interface {
	AuthenticateApp(ctx context.Context, cmd AuthenticatePublicAPIAppCommand) (AuthenticatePublicAPIAppResult, error)
}

type AuthenticatePublicAPIAppUsecase struct {
	store PublicAPIAppAuthStore
	nowFn func() time.Time
}

func NewAuthenticatePublicAPIAppUsecase(store PublicAPIAppAuthStore) *AuthenticatePublicAPIAppUsecase {
	return &AuthenticatePublicAPIAppUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *AuthenticatePublicAPIAppUsecase) Authenticate(ctx context.Context, req AuthenticatePublicAPIAppRequest) (AuthenticatePublicAPIAppResponse, error) {
	if u == nil || u.store == nil {
		return AuthenticatePublicAPIAppResponse{}, errors.New("public api app auth usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.RequestID = strings.TrimSpace(req.RequestID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.APIKeyID = strings.TrimSpace(req.APIKeyID)
	req.KeyFingerprint = strings.TrimSpace(req.KeyFingerprint)
	req.Environment = strings.TrimSpace(req.Environment)
	req.RequiredScopes = normalizePublicAPIKeyScopes(req.RequiredScopes)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return AuthenticatePublicAPIAppResponse{}, err
	}

	result, err := u.store.AuthenticateApp(ctx, AuthenticatePublicAPIAppCommand{
		TenantID:       req.TenantID,
		RequestID:      req.RequestID,
		AppID:          req.AppID,
		APIKeyID:       req.APIKeyID,
		KeyFingerprint: req.KeyFingerprint,
		Environment:    req.Environment,
		RequiredScopes: cloneStringSlice(req.RequiredScopes),
		RequestedBy:    req.RequestedBy,
	})
	if err != nil {
		return AuthenticatePublicAPIAppResponse{}, err
	}

	status := strings.TrimSpace(result.AuthStatus)
	authenticated := result.Authenticated
	denialReason := strings.TrimSpace(result.DenialReason)

	if status == "" {
		status = "denied"
		denialReason = "app auth sonucu bulunamadi"
	}

	if authenticated {
		status = "authenticated"
		denialReason = ""
	}

	if status == "denied" {
		authenticated = false
		if denialReason == "" {
			denialReason = "app auth denied"
		}
	}

	resp := AuthenticatePublicAPIAppResponse{
		RequestID:       firstNonEmpty(strings.TrimSpace(result.RequestID), req.RequestID),
		AppID:           firstNonEmpty(strings.TrimSpace(result.AppID), req.AppID),
		APIKeyID:        firstNonEmpty(strings.TrimSpace(result.APIKeyID), req.APIKeyID),
		Environment:     firstNonEmpty(strings.TrimSpace(result.Environment), req.Environment),
		GrantedScopes:   firstNonEmptyStringSlice(result.GrantedScopes, req.RequiredScopes),
		AuthStatus:      status,
		Authenticated:   authenticated,
		DenialReason:    denialReason,
		AuthenticatedAt: u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return AuthenticatePublicAPIAppResponse{}, err
	}

	return resp, nil
}
