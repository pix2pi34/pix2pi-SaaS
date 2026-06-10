package multitenantuser

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"
)

var (
	ErrUserIDRequired      = errors.New("user id required")
	ErrTenantIDRequired    = errors.New("tenant id required")
	ErrSessionIDRequired   = errors.New("session id required")
	ErrTenantAccessDenied  = errors.New("tenant access denied")
	ErrNoActiveMemberships = errors.New("no active memberships")
	ErrPreferenceMissing   = errors.New("tenant preference missing")
)

type Tenant struct {
	ID              string
	Slug            string
	Name            string
	DefaultLanguage string
	Currency        string
	Status          string
}

type Membership struct {
	UserID    string
	TenantID  string
	RoleCode  string
	Status    string
	CreatedAt time.Time
}

type TenantOption struct {
	TenantID        string
	TenantSlug      string
	TenantName      string
	RoleCode        string
	DefaultLanguage string
	Currency        string
}

type CurrentTenantContext struct {
	UserID          string
	SessionID       string
	TenantID        string
	TenantSlug      string
	TenantName      string
	RoleCode        string
	DefaultLanguage string
	Currency        string
	SelectedAt      time.Time
}

type SwitchTenantInput struct {
	UserID    string
	SessionID string
	TenantID  string
}

type Store interface {
	ListMembershipsForUser(ctx context.Context, userID string) ([]Membership, error)
	GetTenant(ctx context.Context, tenantID string) (Tenant, error)
	SaveCurrentTenant(ctx context.Context, context CurrentTenantContext) error
	GetCurrentTenantID(ctx context.Context, userID string, sessionID string) (string, error)
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

func (s *Service) ListTenantOptions(ctx context.Context, userID string) ([]TenantOption, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return nil, ErrUserIDRequired
	}

	memberships, err := s.store.ListMembershipsForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	options := make([]TenantOption, 0, len(memberships))
	for _, membership := range memberships {
		if membership.UserID != userID || membership.Status != "active" {
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
		return nil, ErrNoActiveMemberships
	}

	return options, nil
}

func (s *Service) SwitchTenant(ctx context.Context, input SwitchTenantInput) (CurrentTenantContext, error) {
	input.UserID = strings.TrimSpace(input.UserID)
	input.SessionID = strings.TrimSpace(input.SessionID)
	input.TenantID = strings.TrimSpace(input.TenantID)

	if input.UserID == "" {
		return CurrentTenantContext{}, ErrUserIDRequired
	}
	if input.SessionID == "" {
		return CurrentTenantContext{}, ErrSessionIDRequired
	}
	if input.TenantID == "" {
		return CurrentTenantContext{}, ErrTenantIDRequired
	}

	option, err := s.findAccessibleTenant(ctx, input.UserID, input.TenantID)
	if err != nil {
		return CurrentTenantContext{}, err
	}

	contextValue := CurrentTenantContext{
		UserID:          input.UserID,
		SessionID:       input.SessionID,
		TenantID:        option.TenantID,
		TenantSlug:      option.TenantSlug,
		TenantName:      option.TenantName,
		RoleCode:        option.RoleCode,
		DefaultLanguage: option.DefaultLanguage,
		Currency:        option.Currency,
		SelectedAt:      s.now().UTC(),
	}

	if err := s.store.SaveCurrentTenant(ctx, contextValue); err != nil {
		return CurrentTenantContext{}, err
	}

	return contextValue, nil
}

func (s *Service) ResolveCurrentTenant(ctx context.Context, userID string, sessionID string) (CurrentTenantContext, error) {
	userID = strings.TrimSpace(userID)
	sessionID = strings.TrimSpace(sessionID)

	if userID == "" {
		return CurrentTenantContext{}, ErrUserIDRequired
	}
	if sessionID == "" {
		return CurrentTenantContext{}, ErrSessionIDRequired
	}

	tenantID, err := s.store.GetCurrentTenantID(ctx, userID, sessionID)
	if err != nil {
		return CurrentTenantContext{}, ErrPreferenceMissing
	}

	option, err := s.findAccessibleTenant(ctx, userID, tenantID)
	if err != nil {
		return CurrentTenantContext{}, err
	}

	return CurrentTenantContext{
		UserID:          userID,
		SessionID:       sessionID,
		TenantID:        option.TenantID,
		TenantSlug:      option.TenantSlug,
		TenantName:      option.TenantName,
		RoleCode:        option.RoleCode,
		DefaultLanguage: option.DefaultLanguage,
		Currency:        option.Currency,
		SelectedAt:      s.now().UTC(),
	}, nil
}

func (s *Service) CanAccessTenant(ctx context.Context, userID string, tenantID string) (bool, error) {
	userID = strings.TrimSpace(userID)
	tenantID = strings.TrimSpace(tenantID)

	if userID == "" {
		return false, ErrUserIDRequired
	}
	if tenantID == "" {
		return false, ErrTenantIDRequired
	}

	_, err := s.findAccessibleTenant(ctx, userID, tenantID)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, ErrTenantAccessDenied) || errors.Is(err, ErrNoActiveMemberships) {
		return false, nil
	}

	return false, err
}

func (s *Service) findAccessibleTenant(ctx context.Context, userID string, tenantID string) (TenantOption, error) {
	options, err := s.ListTenantOptions(ctx, userID)
	if err != nil {
		return TenantOption{}, err
	}

	for _, option := range options {
		if option.TenantID == tenantID {
			return option, nil
		}
	}

	return TenantOption{}, ErrTenantAccessDenied
}
