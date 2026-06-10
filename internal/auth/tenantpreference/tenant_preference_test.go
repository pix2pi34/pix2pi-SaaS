package tenantpreference

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
	persistent  map[string]string
	session     map[string]TenantPreference
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

func (s *memoryStore) GetPersistentTenantID(_ context.Context, userID string) (string, error) {
	tenantID, ok := s.persistent[userID]
	if !ok {
		return "", errors.New("preference missing")
	}
	return tenantID, nil
}

func (s *memoryStore) SavePersistentTenantPreference(_ context.Context, preference TenantPreference) error {
	s.persistent[preference.UserID] = preference.TenantID
	return nil
}

func (s *memoryStore) SaveSessionTenantPreference(_ context.Context, preference TenantPreference) error {
	s.session[preference.UserID+"|"+preference.SessionID] = preference
	return nil
}

func testService() (*Service, *memoryStore) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	store := &memoryStore{
		memberships: []Membership{
			{UserID: "user-001", TenantID: "tenant-002", RoleCode: "manager", Status: "active"},
			{UserID: "user-001", TenantID: "tenant-001", RoleCode: "owner", Status: "active"},
			{UserID: "user-001", TenantID: "tenant-003", RoleCode: "cashier", Status: "inactive"},
		},
		tenants: map[string]Tenant{
			"tenant-001": {ID: "tenant-001", Slug: "alpha", Name: "Alpha Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-002": {ID: "tenant-002", Slug: "beta", Name: "Beta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-003": {ID: "tenant-003", Slug: "gamma", Name: "Gamma Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
			"tenant-004": {ID: "tenant-004", Slug: "closed", Name: "Closed Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "inactive"},
		},
		persistent: map[string]string{},
		session:    map[string]TenantPreference{},
	}
	return NewService(store, func() time.Time { return now }), store
}

func TestRememberTenantSavesPersistentAndSessionPreference(t *testing.T) {
	service, store := testService()

	result, err := service.RememberTenant(context.Background(), SetPreferenceInput{
		UserID:    "user-001",
		SessionID: "session-001",
		TenantID:  "tenant-002",
		Source:    "tenant_selection",
	})
	if err != nil {
		t.Fatalf("RememberTenant error: %v", err)
	}

	if result.TenantID != "tenant-002" {
		t.Fatalf("tenant mismatch: %s", result.TenantID)
	}
	if store.persistent["user-001"] != "tenant-002" {
		t.Fatalf("persistent preference missing")
	}
	if store.session["user-001|session-001"].TenantID != "tenant-002" {
		t.Fatalf("session preference missing")
	}
}

func TestResolveRememberedTenantReturnsAccessiblePreference(t *testing.T) {
	service, store := testService()
	store.persistent["user-001"] = "tenant-002"

	result, err := service.ResolveRememberedTenant(context.Background(), ResolvePreferenceInput{
		UserID:    "user-001",
		SessionID: "session-002",
	})
	if err != nil {
		t.Fatalf("ResolveRememberedTenant error: %v", err)
	}

	if result.TenantID != "tenant-002" {
		t.Fatalf("tenant mismatch: %s", result.TenantID)
	}
	if result.Source != "remembered" {
		t.Fatalf("source mismatch: %s", result.Source)
	}
}

func TestResolveFallsBackWhenPreferenceNotAccessible(t *testing.T) {
	service, store := testService()
	store.persistent["user-001"] = "tenant-999"

	result, err := service.ResolveRememberedTenant(context.Background(), ResolvePreferenceInput{
		UserID:    "user-001",
		SessionID: "session-003",
	})
	if err != nil {
		t.Fatalf("ResolveRememberedTenant fallback error: %v", err)
	}

	if result.TenantID != "tenant-001" {
		t.Fatalf("expected sorted first active tenant-001, got %s", result.TenantID)
	}
	if result.Source != "first_active" {
		t.Fatalf("source mismatch: %s", result.Source)
	}
}

func TestRememberTenantRejectsInaccessibleTenant(t *testing.T) {
	service, _ := testService()

	_, err := service.RememberTenant(context.Background(), SetPreferenceInput{
		UserID:    "user-001",
		SessionID: "session-001",
		TenantID:  "tenant-004",
	})
	if !errors.Is(err, ErrTenantAccessDenied) {
		t.Fatalf("expected ErrTenantAccessDenied, got %v", err)
	}
}

func TestGetPreferenceHTTP(t *testing.T) {
	service, store := testService()
	store.persistent["user-001"] = "tenant-002"

	req := httptest.NewRequest(http.MethodGet, "/api/auth/tenant/preference", nil)
	req.Header.Set("X-User-ID", "user-001")
	req.Header.Set("X-Session-ID", "session-004")
	rec := httptest.NewRecorder()

	service.GetPreferenceHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var result TenantPreference
	if err := json.Unmarshal(rec.Body.Bytes(), &result); err != nil {
		t.Fatalf("json error: %v", err)
	}
	if result.TenantID != "tenant-002" {
		t.Fatalf("tenant mismatch: %s", result.TenantID)
	}
}

func TestSetPreferenceHTTP(t *testing.T) {
	service, store := testService()

	body := bytes.NewBufferString(`{"tenant_id":"tenant-001","source":"tenant_selection"}`)
	req := httptest.NewRequest(http.MethodPut, "/api/auth/tenant/preference", body)
	req.Header.Set("X-User-ID", "user-001")
	req.Header.Set("X-Session-ID", "session-005")
	rec := httptest.NewRecorder()

	service.SetPreferenceHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}
	if store.persistent["user-001"] != "tenant-001" {
		t.Fatalf("persistent preference missing")
	}
}
