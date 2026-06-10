package tenantpreference

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
	ErrUserIDRequired        = errors.New("user id required")
	ErrTenantIDRequired      = errors.New("tenant id required")
	ErrSessionIDRequired     = errors.New("session id required")
	ErrTenantAccessDenied    = errors.New("tenant access denied")
	ErrNoActiveTenant        = errors.New("no active tenant")
	ErrPreferenceUnavailable = errors.New("tenant preference unavailable")
	ErrMethodNotAllowed      = errors.New("method not allowed")
)

type Tenant struct {
	ID              string `json:"id"`
	Slug            string `json:"slug"`
	Name            string `json:"name"`
	DefaultLanguage string `json:"default_language"`
	Currency        string `json:"currency"`
	Status          string `json:"status"`
}

type Membership struct {
	UserID    string
	TenantID  string
	RoleCode  string
	Status    string
	CreatedAt time.Time
}

type TenantPreference struct {
	UserID          string    `json:"user_id"`
	SessionID       string    `json:"session_id,omitempty"`
	TenantID        string    `json:"tenant_id"`
	TenantSlug      string    `json:"tenant_slug"`
	TenantName      string    `json:"tenant_name"`
	RoleCode        string    `json:"role_code"`
	DefaultLanguage string    `json:"default_language"`
	Currency        string    `json:"currency"`
	SelectedAt      time.Time `json:"selected_at"`
	Source          string    `json:"source"`
}

type SetPreferenceInput struct {
	UserID    string `json:"user_id"`
	SessionID string `json:"session_id"`
	TenantID  string `json:"tenant_id"`
	Source    string `json:"source"`
}

type ResolvePreferenceInput struct {
	UserID    string
	SessionID string
}

type Store interface {
	ListMembershipsForUser(ctx context.Context, userID string) ([]Membership, error)
	GetTenant(ctx context.Context, tenantID string) (Tenant, error)
	GetPersistentTenantID(ctx context.Context, userID string) (string, error)
	SavePersistentTenantPreference(ctx context.Context, preference TenantPreference) error
	SaveSessionTenantPreference(ctx context.Context, preference TenantPreference) error
}

type Service struct {
	store Store
	now   func() time.Time
}

func NewService(store Store, now func() time.Time) *Service {
	if now == nil {
		now = time.Now
	}
	return &Service{store: store, now: now}
}

func (s *Service) RememberTenant(ctx context.Context, input SetPreferenceInput) (TenantPreference, error) {
	input.UserID = strings.TrimSpace(input.UserID)
	input.SessionID = strings.TrimSpace(input.SessionID)
	input.TenantID = strings.TrimSpace(input.TenantID)
	input.Source = strings.TrimSpace(input.Source)

	if input.UserID == "" {
		return TenantPreference{}, ErrUserIDRequired
	}
	if input.SessionID == "" {
		return TenantPreference{}, ErrSessionIDRequired
	}
	if input.TenantID == "" {
		return TenantPreference{}, ErrTenantIDRequired
	}
	if input.Source == "" {
		input.Source = "tenant_selection"
	}

	preference, err := s.buildPreferenceForTenant(ctx, input.UserID, input.SessionID, input.TenantID, input.Source)
	if err != nil {
		return TenantPreference{}, err
	}

	if err := s.store.SavePersistentTenantPreference(ctx, preference); err != nil {
		return TenantPreference{}, err
	}

	if err := s.store.SaveSessionTenantPreference(ctx, preference); err != nil {
		return TenantPreference{}, err
	}

	return preference, nil
}

func (s *Service) ResolveRememberedTenant(ctx context.Context, input ResolvePreferenceInput) (TenantPreference, error) {
	input.UserID = strings.TrimSpace(input.UserID)
	input.SessionID = strings.TrimSpace(input.SessionID)

	if input.UserID == "" {
		return TenantPreference{}, ErrUserIDRequired
	}
	if input.SessionID == "" {
		return TenantPreference{}, ErrSessionIDRequired
	}

	persistentTenantID, err := s.store.GetPersistentTenantID(ctx, input.UserID)
	if err == nil && persistentTenantID != "" {
		preference, buildErr := s.buildPreferenceForTenant(ctx, input.UserID, input.SessionID, persistentTenantID, "remembered")
		if buildErr == nil {
			if saveErr := s.store.SaveSessionTenantPreference(ctx, preference); saveErr != nil {
				return TenantPreference{}, saveErr
			}
			return preference, nil
		}
		if !errors.Is(buildErr, ErrTenantAccessDenied) {
			return TenantPreference{}, buildErr
		}
	}

	fallback, err := s.firstActiveTenant(ctx, input.UserID, input.SessionID)
	if err != nil {
		return TenantPreference{}, err
	}

	if err := s.store.SaveSessionTenantPreference(ctx, fallback); err != nil {
		return TenantPreference{}, err
	}

	return fallback, nil
}

func (s *Service) GetPreferenceHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}

	userID := r.Header.Get("X-User-ID")
	sessionID := r.Header.Get("X-Session-ID")

	result, err := s.ResolveRememberedTenant(r.Context(), ResolvePreferenceInput{
		UserID:    userID,
		SessionID: sessionID,
	})
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (s *Service) SetPreferenceHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}

	var input SetPreferenceInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, ErrTenantIDRequired)
		return
	}

	if input.UserID == "" {
		input.UserID = r.Header.Get("X-User-ID")
	}
	if input.SessionID == "" {
		input.SessionID = r.Header.Get("X-Session-ID")
	}

	result, err := s.RememberTenant(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (s *Service) buildPreferenceForTenant(ctx context.Context, userID string, sessionID string, tenantID string, source string) (TenantPreference, error) {
	membership, err := s.findActiveMembership(ctx, userID, tenantID)
	if err != nil {
		return TenantPreference{}, err
	}

	tenant, err := s.store.GetTenant(ctx, tenantID)
	if err != nil {
		return TenantPreference{}, ErrTenantAccessDenied
	}
	if tenant.Status != "active" {
		return TenantPreference{}, ErrTenantAccessDenied
	}

	return TenantPreference{
		UserID:          userID,
		SessionID:       sessionID,
		TenantID:        tenant.ID,
		TenantSlug:      tenant.Slug,
		TenantName:      tenant.Name,
		RoleCode:        membership.RoleCode,
		DefaultLanguage: tenant.DefaultLanguage,
		Currency:        tenant.Currency,
		SelectedAt:      s.now().UTC(),
		Source:          source,
	}, nil
}

func (s *Service) firstActiveTenant(ctx context.Context, userID string, sessionID string) (TenantPreference, error) {
	memberships, err := s.store.ListMembershipsForUser(ctx, userID)
	if err != nil {
		return TenantPreference{}, err
	}

	options := make([]TenantPreference, 0)
	for _, membership := range memberships {
		if membership.UserID != userID || membership.Status != "active" {
			continue
		}

		tenant, err := s.store.GetTenant(ctx, membership.TenantID)
		if err != nil || tenant.Status != "active" {
			continue
		}

		options = append(options, TenantPreference{
			UserID:          userID,
			SessionID:       sessionID,
			TenantID:        tenant.ID,
			TenantSlug:      tenant.Slug,
			TenantName:      tenant.Name,
			RoleCode:        membership.RoleCode,
			DefaultLanguage: tenant.DefaultLanguage,
			Currency:        tenant.Currency,
			SelectedAt:      s.now().UTC(),
			Source:          "first_active",
		})
	}

	sort.Slice(options, func(i, j int) bool {
		if options[i].TenantName == options[j].TenantName {
			return options[i].TenantID < options[j].TenantID
		}
		return options[i].TenantName < options[j].TenantName
	})

	if len(options) == 0 {
		return TenantPreference{}, ErrNoActiveTenant
	}

	return options[0], nil
}

func (s *Service) findActiveMembership(ctx context.Context, userID string, tenantID string) (Membership, error) {
	memberships, err := s.store.ListMembershipsForUser(ctx, userID)
	if err != nil {
		return Membership{}, err
	}

	for _, membership := range memberships {
		if membership.UserID == userID && membership.TenantID == tenantID && membership.Status == "active" {
			return membership, nil
		}
	}

	return Membership{}, ErrTenantAccessDenied
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrUserIDRequired), errors.Is(err, ErrSessionIDRequired), errors.Is(err, ErrTenantIDRequired):
		writeError(w, http.StatusBadRequest, err)
	case errors.Is(err, ErrTenantAccessDenied), errors.Is(err, ErrNoActiveTenant), errors.Is(err, ErrPreferenceUnavailable):
		writeError(w, http.StatusForbidden, err)
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
