package multitenantuser

import (
	"context"
	"errors"
	"testing"
	"time"
)

type memoryStore struct {
	memberships []Membership
	tenants     map[string]Tenant
	current     map[string]string
	saved       []CurrentTenantContext
}

func (s *memoryStore) ListMembershipsForUser(_ context.Context, userID string) ([]Membership, error) {
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
		return Tenant{}, errors.New("tenant missing")
	}
	return tenant, nil
}

func (s *memoryStore) SaveCurrentTenant(_ context.Context, contextValue CurrentTenantContext) error {
	key := contextValue.UserID + "|" + contextValue.SessionID
	s.current[key] = contextValue.TenantID
	s.saved = append(s.saved, contextValue)
	return nil
}

func (s *memoryStore) GetCurrentTenantID(_ context.Context, userID string, sessionID string) (string, error) {
	tenantID, ok := s.current[userID+"|"+sessionID]
	if !ok {
		return "", errors.New("preference missing")
	}
	return tenantID, nil
}

func testService() (*Service, *memoryStore) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	store := &memoryStore{
		memberships: []Membership{
			{UserID: "user-001", TenantID: "tenant-002", RoleCode: "manager", Status: "active"},
			{UserID: "user-001", TenantID: "tenant-001", RoleCode: "owner", Status: "active"},
			{UserID: "user-001", TenantID: "tenant-003", RoleCode: "cashier", Status: "inactive"},
			{UserID: "user-002", TenantID: "tenant-004", RoleCode: "owner", Status: "active"},
		},
		tenants: map[string]Tenant{
			"tenant-001": {ID: "tenant-001", Slug: "alpha", Name: "Alpha Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-002": {ID: "tenant-002", Slug: "beta", Name: "Beta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-003": {ID: "tenant-003", Slug: "gamma", Name: "Gamma Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-004": {ID: "tenant-004", Slug: "delta", Name: "Delta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-005": {ID: "tenant-005", Slug: "closed", Name: "Closed Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "inactive"},
		},
		current: map[string]string{},
		saved:   []CurrentTenantContext{},
	}
	return NewService(store, func() time.Time { return now }), store
}

func TestListsMultipleTenantMemberships(t *testing.T) {
	service, _ := testService()

	options, err := service.ListTenantOptions(context.Background(), "user-001")
	if err != nil {
		t.Fatalf("ListTenantOptions error: %v", err)
	}

	if len(options) != 2 {
		t.Fatalf("expected 2 active tenant options, got %d", len(options))
	}
	if options[0].TenantID != "tenant-001" {
		t.Fatalf("expected sorted tenant-001 first, got %s", options[0].TenantID)
	}
	if options[1].RoleCode != "manager" {
		t.Fatalf("expected manager role on second tenant, got %s", options[1].RoleCode)
	}
}

func TestSwitchTenantPersistsCurrentTenant(t *testing.T) {
	service, store := testService()

	contextValue, err := service.SwitchTenant(context.Background(), SwitchTenantInput{
		UserID:    "user-001",
		SessionID: "session-001",
		TenantID:  "tenant-002",
	})
	if err != nil {
		t.Fatalf("SwitchTenant error: %v", err)
	}

	if contextValue.TenantID != "tenant-002" {
		t.Fatalf("tenant mismatch: %s", contextValue.TenantID)
	}
	if contextValue.RoleCode != "manager" {
		t.Fatalf("role mismatch: %s", contextValue.RoleCode)
	}
	if store.current["user-001|session-001"] != "tenant-002" {
		t.Fatalf("current tenant preference missing")
	}
	if len(store.saved) != 1 {
		t.Fatalf("expected one saved context, got %d", len(store.saved))
	}
}

func TestRejectsTenantWithoutMembership(t *testing.T) {
	service, _ := testService()

	_, err := service.SwitchTenant(context.Background(), SwitchTenantInput{
		UserID:    "user-001",
		SessionID: "session-001",
		TenantID:  "tenant-004",
	})
	if !errors.Is(err, ErrTenantAccessDenied) {
		t.Fatalf("expected ErrTenantAccessDenied, got %v", err)
	}
}

func TestRejectsInactiveMembershipAndTenant(t *testing.T) {
	service, store := testService()

	_, err := service.SwitchTenant(context.Background(), SwitchTenantInput{
		UserID:    "user-001",
		SessionID: "session-001",
		TenantID:  "tenant-003",
	})
	if !errors.Is(err, ErrTenantAccessDenied) {
		t.Fatalf("expected ErrTenantAccessDenied for inactive membership, got %v", err)
	}

	store.memberships = append(store.memberships, Membership{
		UserID: "user-001", TenantID: "tenant-005", RoleCode: "owner", Status: "active",
	})

	_, err = service.SwitchTenant(context.Background(), SwitchTenantInput{
		UserID:    "user-001",
		SessionID: "session-001",
		TenantID:  "tenant-005",
	})
	if !errors.Is(err, ErrTenantAccessDenied) {
		t.Fatalf("expected ErrTenantAccessDenied for inactive tenant, got %v", err)
	}
}

func TestResolveCurrentTenantFromSession(t *testing.T) {
	service, store := testService()
	store.current["user-001|session-001"] = "tenant-001"

	contextValue, err := service.ResolveCurrentTenant(context.Background(), "user-001", "session-001")
	if err != nil {
		t.Fatalf("ResolveCurrentTenant error: %v", err)
	}

	if contextValue.TenantID != "tenant-001" {
		t.Fatalf("tenant mismatch: %s", contextValue.TenantID)
	}
	if contextValue.RoleCode != "owner" {
		t.Fatalf("role mismatch: %s", contextValue.RoleCode)
	}
}

func TestCanAccessTenant(t *testing.T) {
	service, _ := testService()

	ok, err := service.CanAccessTenant(context.Background(), "user-001", "tenant-001")
	if err != nil {
		t.Fatalf("CanAccessTenant error: %v", err)
	}
	if !ok {
		t.Fatalf("expected access to tenant-001")
	}

	ok, err = service.CanAccessTenant(context.Background(), "user-001", "tenant-004")
	if err != nil {
		t.Fatalf("CanAccessTenant error: %v", err)
	}
	if ok {
		t.Fatalf("expected no access to tenant-004")
	}
}
