package tenantselection

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"sort"
	"strings"
	"time"
)

var (
	ErrAuthRequired      = errors.New("authorization required")
	ErrInvalidToken      = errors.New("invalid token")
	ErrNoTenantAccess    = errors.New("tenant access denied")
	ErrNoActiveTenants   = errors.New("no active tenants")
	ErrTenantIDRequired  = errors.New("tenant id required")
	ErrMethodNotAllowed  = errors.New("method not allowed")
	ErrPreferenceFailure = errors.New("tenant preference record failed")
)

type AuthClaims struct {
	UserID    string
	Email     string
	TenantID  string
	SessionID string
	TokenUse  string
	ExpiresAt time.Time
}

type TokenVerifier interface {
	VerifyAccessToken(ctx context.Context, token string) (AuthClaims, error)
}

type Tenant struct {
	ID              string `json:"id"`
	Slug            string `json:"slug"`
	Name            string `json:"name"`
	DefaultLanguage string `json:"default_language"`
	Currency        string `json:"currency"`
	Status          string `json:"status"`
}

type Membership struct {
	TenantID string
	UserID   string
	RoleCode string
	Status   string
}

type TenantOption struct {
	TenantID        string `json:"tenant_id"`
	TenantSlug      string `json:"tenant_slug"`
	TenantName      string `json:"tenant_name"`
	RoleCode        string `json:"role_code"`
	DefaultLanguage string `json:"default_language"`
	Currency        string `json:"currency"`
}

type TenantListResult struct {
	UserID  string         `json:"user_id"`
	Email   string         `json:"email"`
	Tenants []TenantOption `json:"tenants"`
}

type SelectTenantInput struct {
	TenantID string `json:"tenant_id"`
}

type SelectedTenantResult struct {
	UserID          string    `json:"user_id"`
	TenantID        string    `json:"tenant_id"`
	TenantSlug      string    `json:"tenant_slug"`
	TenantName      string    `json:"tenant_name"`
	RoleCode        string    `json:"role_code"`
	DefaultLanguage string    `json:"default_language"`
	Currency        string    `json:"currency"`
	SelectedAt      time.Time `json:"selected_at"`
}

type Store interface {
	ListActiveMemberships(ctx context.Context, userID string) ([]Membership, error)
	GetTenant(ctx context.Context, tenantID string) (Tenant, error)
	SaveTenantPreference(ctx context.Context, userID string, tenantID string) error
}

type Service struct {
	store    Store
	verifier TokenVerifier
	now      func() time.Time
}

func NewService(store Store, verifier TokenVerifier, now func() time.Time) *Service {
	if now == nil {
		now = time.Now
	}
	return &Service{store: store, verifier: verifier, now: now}
}

func (s *Service) ListTenants(ctx context.Context, accessToken string) (TenantListResult, error) {
	claims, err := s.authClaims(ctx, accessToken)
	if err != nil {
		return TenantListResult{}, err
	}

	memberships, err := s.store.ListActiveMemberships(ctx, claims.UserID)
	if err != nil {
		return TenantListResult{}, err
	}

	options := make([]TenantOption, 0, len(memberships))
	for _, membership := range memberships {
		if membership.Status != "active" {
			continue
		}

		tenant, err := s.store.GetTenant(ctx, membership.TenantID)
		if err != nil {
			continue
		}
		if tenant.Status != "active" {
			continue
		}

		options = append(options, TenantOption{
			TenantID:        tenant.ID,
			TenantSlug:      tenant.Slug,
			TenantName:      tenant.Name,
			RoleCode:        membership.RoleCode,
			DefaultLanguage: tenant.DefaultLanguage,
			Currency:        tenant.Currency,
		})
	}

	sort.Slice(options, func(i, j int) bool {
		if options[i].TenantName == options[j].TenantName {
			return options[i].TenantID < options[j].TenantID
		}
		return options[i].TenantName < options[j].TenantName
	})

	if len(options) == 0 {
		return TenantListResult{}, ErrNoActiveTenants
	}

	return TenantListResult{
		UserID:  claims.UserID,
		Email:   claims.Email,
		Tenants: options,
	}, nil
}

func (s *Service) SelectTenant(ctx context.Context, accessToken string, tenantID string) (SelectedTenantResult, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return SelectedTenantResult{}, ErrTenantIDRequired
	}

	claims, err := s.authClaims(ctx, accessToken)
	if err != nil {
		return SelectedTenantResult{}, err
	}

	list, err := s.ListTenants(ctx, accessToken)
	if err != nil {
		return SelectedTenantResult{}, err
	}

	for _, option := range list.Tenants {
		if option.TenantID == tenantID {
			if err := s.store.SaveTenantPreference(ctx, claims.UserID, tenantID); err != nil {
				return SelectedTenantResult{}, ErrPreferenceFailure
			}

			return SelectedTenantResult{
				UserID:          claims.UserID,
				TenantID:        option.TenantID,
				TenantSlug:      option.TenantSlug,
				TenantName:      option.TenantName,
				RoleCode:        option.RoleCode,
				DefaultLanguage: option.DefaultLanguage,
				Currency:        option.Currency,
				SelectedAt:      s.now().UTC(),
			}, nil
		}
	}

	return SelectedTenantResult{}, ErrNoTenantAccess
}

func (s *Service) ListTenantsHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}

	result, err := s.ListTenants(r.Context(), bearerToken(r.Header.Get("Authorization")))
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (s *Service) SelectTenantHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}

	var input SelectTenantInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, ErrTenantIDRequired)
		return
	}

	result, err := s.SelectTenant(r.Context(), bearerToken(r.Header.Get("Authorization")), input.TenantID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (s *Service) authClaims(ctx context.Context, accessToken string) (AuthClaims, error) {
	accessToken = strings.TrimSpace(accessToken)
	if accessToken == "" {
		return AuthClaims{}, ErrAuthRequired
	}

	claims, err := s.verifier.VerifyAccessToken(ctx, accessToken)
	if err != nil {
		return AuthClaims{}, ErrInvalidToken
	}
	if claims.UserID == "" || claims.TokenUse != "access" {
		return AuthClaims{}, ErrInvalidToken
	}
	if !claims.ExpiresAt.IsZero() && !claims.ExpiresAt.After(s.now().UTC()) {
		return AuthClaims{}, ErrInvalidToken
	}

	return claims, nil
}

func bearerToken(header string) string {
	header = strings.TrimSpace(header)
	if header == "" {
		return ""
	}

	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}

	return strings.TrimSpace(parts[1])
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrAuthRequired), errors.Is(err, ErrInvalidToken):
		writeError(w, http.StatusUnauthorized, err)
	case errors.Is(err, ErrNoTenantAccess), errors.Is(err, ErrNoActiveTenants):
		writeError(w, http.StatusForbidden, err)
	case errors.Is(err, ErrTenantIDRequired):
		writeError(w, http.StatusBadRequest, err)
	default:
		writeError(w, http.StatusInternalServerError, err)
	}
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
