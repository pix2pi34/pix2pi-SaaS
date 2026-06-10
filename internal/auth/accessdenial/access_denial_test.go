package accessdenial

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type memoryStore struct {
	events []Event
}

func (s *memoryStore) RecordAccessDenial(_ context.Context, event Event) error {
	s.events = append(s.events, event)
	return nil
}

func testService() (*Service, *memoryStore) {
	store := &memoryStore{events: []Event{}}
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	return NewService(store, func() time.Time { return now }), store
}

func TestCatalogIsComplete(t *testing.T) {
	if err := ValidateCatalog(); err != nil {
		t.Fatalf("ValidateCatalog error: %v", err)
	}
}

func TestUnauthorizedDecision(t *testing.T) {
	service, store := testService()

	decision := service.Decide(context.Background(), ErrMissingToken, RequestContext{
		RoutePath:     "/dashboard/",
		ActionCode:    "panel:dashboard:view",
		CorrelationID: "corr-401",
		Locale:        LocaleTR,
	})

	if decision.HTTPStatus != http.StatusUnauthorized {
		t.Fatalf("status mismatch: %d", decision.HTTPStatus)
	}
	if decision.Screen != ScreenUnauthorized {
		t.Fatalf("screen mismatch: %s", decision.Screen)
	}
	if decision.Message != "Bu sayfayı görmek için giriş yapmalısınız." {
		t.Fatalf("message mismatch: %s", decision.Message)
	}
	if len(store.events) != 1 {
		t.Fatalf("event was not recorded")
	}
}

func TestForbiddenDecision(t *testing.T) {
	service, store := testService()

	decision := service.Decide(context.Background(), ErrPermissionDenied, RequestContext{
		TenantID:      "tenant-001",
		UserID:        "user-001",
		RoleCode:      "cashier",
		RoutePath:     "/billing/",
		ActionCode:    "billing:view",
		CorrelationID: "corr-403",
		Locale:        LocaleEN,
	})

	if decision.HTTPStatus != http.StatusForbidden {
		t.Fatalf("status mismatch: %d", decision.HTTPStatus)
	}
	if decision.Screen != ScreenForbidden {
		t.Fatalf("screen mismatch: %s", decision.Screen)
	}
	if decision.Message != "You do not have permission for this action." {
		t.Fatalf("message mismatch: %s", decision.Message)
	}
	if store.events[0].TenantID != "tenant-001" || store.events[0].RoleCode != "cashier" {
		t.Fatalf("event context mismatch")
	}
}

func TestCodeFromErrorMappings(t *testing.T) {
	cases := []struct {
		err  error
		code DenialCode
	}{
		{ErrMissingToken, CodeMissingToken},
		{ErrInvalidToken, CodeInvalidToken},
		{ErrExpiredSession, CodeExpiredSession},
		{ErrTenantAccessDenied, CodeTenantAccessDenied},
		{ErrPermissionDenied, CodePermissionDenied},
		{ErrRoleDenied, CodeRoleDenied},
		{errors.New("unknown"), CodePermissionDenied},
	}

	for _, item := range cases {
		if got := CodeFromError(item.err); got != item.code {
			t.Fatalf("code mismatch for %v: got %s want %s", item.err, got, item.code)
		}
	}
}

func TestWriteHTTP(t *testing.T) {
	service, _ := testService()
	rec := httptest.NewRecorder()

	service.WriteHTTP(context.Background(), rec, ErrTenantAccessDenied, RequestContext{
		RoutePath:     "/products/",
		ActionCode:    "products:write",
		CorrelationID: "corr-http",
		Locale:        LocaleEN,
	})

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status mismatch: %d", rec.Code)
	}
	if rec.Header().Get("X-Correlation-ID") != "corr-http" {
		t.Fatalf("correlation header missing")
	}
	if rec.Header().Get("X-Access-Denial-Screen") != string(ScreenForbidden) {
		t.Fatalf("screen header mismatch")
	}

	var decision Decision
	if err := json.Unmarshal(rec.Body.Bytes(), &decision); err != nil {
		t.Fatalf("json error: %v", err)
	}
	if decision.Code != CodeTenantAccessDenied {
		t.Fatalf("code mismatch: %s", decision.Code)
	}
}

func TestLocaleFallback(t *testing.T) {
	service, _ := testService()

	decision := service.Decide(context.Background(), ErrRoleDenied, RequestContext{
		CorrelationID: "corr-locale",
		Locale:        "ota",
	})

	if decision.Message != "Rolünüz bu sayfaya erişim için yeterli değil." {
		t.Fatalf("fallback message mismatch: %s", decision.Message)
	}
}
