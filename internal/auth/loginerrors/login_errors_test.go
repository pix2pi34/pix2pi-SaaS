package loginerrors

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

func (s *memoryStore) RecordLoginError(_ context.Context, event Event) error {
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

func TestCodeFromErrorMappings(t *testing.T) {
	cases := []struct {
		err  error
		code Code
	}{
		{ErrValidationRequired, CodeValidationRequired},
		{ErrInvalidCredentials, CodeInvalidCredentials},
		{ErrAccountInactive, CodeAccountInactive},
		{ErrTenantAccessDenied, CodeTenantAccessDenied},
		{ErrTokenInvalid, CodeTokenInvalid},
		{ErrTokenExpired, CodeTokenExpired},
		{ErrSessionExpired, CodeSessionExpired},
		{ErrRateLimited, CodeRateLimited},
		{errors.New("database connection detail"), CodeInternal},
	}

	for _, item := range cases {
		if got := CodeFromError(item.err); got != item.code {
			t.Fatalf("code mismatch for %v: got %s want %s", item.err, got, item.code)
		}
	}
}

func TestBuildReturnsLocalizedSafeMessageAndRecordsEvent(t *testing.T) {
	service, store := testService()

	public := service.Build(context.Background(), ErrInvalidCredentials, RequestContext{
		TenantID:      "tenant-001",
		UserID:        "user-001",
		Email:         "OWNER@EXAMPLE.COM",
		CorrelationID: "corr-001",
		IPAddress:     "127.0.0.1",
		UserAgent:     "go-test",
		Locale:        LocaleTR,
	})

	if public.Code != CodeInvalidCredentials {
		t.Fatalf("code mismatch: %s", public.Code)
	}
	if public.HTTPStatus != http.StatusUnauthorized {
		t.Fatalf("status mismatch: %d", public.HTTPStatus)
	}
	if public.Message != "E-posta veya şifre hatalı." {
		t.Fatalf("message mismatch: %s", public.Message)
	}
	if public.CorrelationID != "corr-001" {
		t.Fatalf("correlation mismatch: %s", public.CorrelationID)
	}
	if len(store.events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(store.events))
	}
	if store.events[0].Email != "owner@example.com" {
		t.Fatalf("email normalization mismatch: %s", store.events[0].Email)
	}
}

func TestInternalErrorDoesNotExposeDetail(t *testing.T) {
	service, _ := testService()

	public := service.Build(context.Background(), errors.New("sql password hash read failed"), RequestContext{
		CorrelationID: "corr-internal",
		Locale:        LocaleEN,
	})

	if public.Code != CodeInternal {
		t.Fatalf("code mismatch: %s", public.Code)
	}
	if public.Message == "sql password hash read failed" {
		t.Fatalf("internal detail leaked")
	}
	if public.Message != "The sign-in process could not be completed right now." {
		t.Fatalf("safe internal message mismatch: %s", public.Message)
	}
}

func TestLocaleFallbackToTurkish(t *testing.T) {
	service, _ := testService()

	public := service.Build(context.Background(), ErrTokenExpired, RequestContext{
		CorrelationID: "corr-locale",
		Locale:        "ota",
	})

	if public.Message != "Oturum süreniz doldu. Tekrar giriş yapın." {
		t.Fatalf("fallback message mismatch: %s", public.Message)
	}
}

func TestWriteHTTP(t *testing.T) {
	service, _ := testService()

	rec := httptest.NewRecorder()
	service.WriteHTTP(context.Background(), rec, ErrTenantAccessDenied, RequestContext{
		CorrelationID: "corr-http",
		Locale:        LocaleEN,
	})

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status mismatch: %d", rec.Code)
	}
	if rec.Header().Get("X-Correlation-ID") != "corr-http" {
		t.Fatalf("correlation header mismatch")
	}

	var public PublicError
	if err := json.Unmarshal(rec.Body.Bytes(), &public); err != nil {
		t.Fatalf("json error: %v", err)
	}
	if public.Code != CodeTenantAccessDenied {
		t.Fatalf("code mismatch: %s", public.Code)
	}
}
