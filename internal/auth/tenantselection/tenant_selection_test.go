package tenantselection

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type memoryStore struct {
	memberships []Membership
	tenants     map[string]Tenant
	preferences map[string]string
}

func (s *memoryStore) ListActiveMemberships(_ context.Context, userID string) ([]Membership, error) {
	out := make([]Membership, 0)
	for _, membership := range s.memberships {
		if membership.UserID == userID {
			out = append(out, membership)
		}
	}
	return out, nil
}

func (s *memoryStore) GetTenant(_ context.Context, tenantID string) (Tenant, error) {
	tenant, ok := s.tenants[tenantID]
	if !ok {
		return Tenant{}, errors.New("tenant not found")
	}
	return tenant, nil
}

func (s *memoryStore) SaveTenantPreference(_ context.Context, userID string, tenantID string) error {
	s.preferences[userID] = tenantID
	return nil
}

type tokenVerifier struct {
	claims map[string]AuthClaims
}

func (v tokenVerifier) VerifyAccessToken(_ context.Context, token string) (AuthClaims, error) {
	claims, ok := v.claims[token]
	if !ok {
		return AuthClaims{}, errors.New("token not found")
	}
	return claims, nil
}

func testService() (*Service, *memoryStore) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	store := &memoryStore{
		memberships: []Membership{
			{TenantID: "tenant-002", UserID: "user-001", RoleCode: "manager", Status: "active"},
			{TenantID: "tenant-001", UserID: "user-001", RoleCode: "owner", Status: "active"},
			{TenantID: "tenant-003", UserID: "user-001", RoleCode: "cashier", Status: "inactive"},
			{TenantID: "tenant-004", UserID: "user-002", RoleCode: "owner", Status: "active"},
		},
		tenants: map[string]Tenant{
			"tenant-001": {ID: "tenant-001", Slug: "alpha", Name: "Alpha Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-002": {ID: "tenant-002", Slug: "beta", Name: "Beta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-003": {ID: "tenant-003", Slug: "gamma", Name: "Gamma Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-004": {ID: "tenant-004", Slug: "delta", Name: "Delta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
		},
		preferences: map[string]string{},
	}

	verifier := tokenVerifier{
		claims: map[string]AuthClaims{
			"token-user-001": {
				UserID:    "user-001",
				Email:     "owner@example.com",
				SessionID: "session-001",
				TokenUse:  "access",
				ExpiresAt: now.Add(time.Hour),
			},
			"expired-token": {
				UserID:    "user-001",
				Email:     "owner@example.com",
				SessionID: "session-001",
				TokenUse:  "access",
				ExpiresAt: now.Add(-time.Minute),
			},
		},
	}

	return NewService(store, verifier, func() time.Time { return now }), store
}

func TestListTenantOptionsFromAccessToken(t *testing.T) {
	service, _ := testService()

	result, err := service.ListTenants(context.Background(), "token-user-001")
	if err != nil {
		t.Fatalf("ListTenants error: %v", err)
	}

	if result.UserID != "user-001" {
		t.Fatalf("user mismatch: %s", result.UserID)
	}
	if len(result.Tenants) != 2 {
		t.Fatalf("expected 2 active tenant options, got %d", len(result.Tenants))
	}
	if result.Tenants[0].TenantName != "Alpha Market" {
		t.Fatalf("expected sorted tenant list, got %s", result.Tenants[0].TenantName)
	}
}

func TestSelectTenantPersistsPreference(t *testing.T) {
	service, store := testService()

	result, err := service.SelectTenant(context.Background(), "token-user-001", "tenant-002")
	if err != nil {
		t.Fatalf("SelectTenant error: %v", err)
	}

	if result.TenantID != "tenant-002" {
		t.Fatalf("tenant mismatch: %s", result.TenantID)
	}
	if store.preferences["user-001"] != "tenant-002" {
		t.Fatalf("tenant preference was not recorded")
	}
}

func TestSelectTenantRejectsTenantWithoutMembership(t *testing.T) {
	service, _ := testService()

	_, err := service.SelectTenant(context.Background(), "token-user-001", "tenant-004")
	if !errors.Is(err, ErrNoTenantAccess) {
		t.Fatalf("expected ErrNoTenantAccess, got %v", err)
	}
}

func TestRequiresBearerToken(t *testing.T) {
	service, _ := testService()

	_, err := service.ListTenants(context.Background(), "")
	if !errors.Is(err, ErrAuthRequired) {
		t.Fatalf("expected ErrAuthRequired, got %v", err)
	}

	_, err = service.ListTenants(context.Background(), "expired-token")
	if !errors.Is(err, ErrInvalidToken) {
		t.Fatalf("expected ErrInvalidToken, got %v", err)
	}
}

func TestHTTPListTenants(t *testing.T) {
	service, _ := testService()

	req := httptest.NewRequest(http.MethodGet, "/api/auth/tenants", nil)
	req.Header.Set("Authorization", "Bearer token-user-001")
	rec := httptest.NewRecorder()

	service.ListTenantsHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var result TenantListResult
	if err := json.Unmarshal(rec.Body.Bytes(), &result); err != nil {
		t.Fatalf("json error: %v", err)
	}
	if len(result.Tenants) != 2 {
		t.Fatalf("expected 2 tenants, got %d", len(result.Tenants))
	}
}

func TestHTTPSelectTenant(t *testing.T) {
	service, store := testService()

	body := bytes.NewBufferString(`{"tenant_id":"tenant-001"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/tenant/select", body)
	req.Header.Set("Authorization", "Bearer token-user-001")
	rec := httptest.NewRecorder()

	service.SelectTenantHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}
	if store.preferences["user-001"] != "tenant-001" {
		t.Fatalf("tenant preference was not recorded")
	}
}
