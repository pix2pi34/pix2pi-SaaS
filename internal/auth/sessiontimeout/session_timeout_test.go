package sessiontimeout

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type memoryStore struct {
	sessions map[string]SessionRecord
	touched  map[string]time.Time
	revoked  map[string]time.Time
	events   []SessionEvent
}

func (s *memoryStore) GetSessionByID(_ context.Context, sessionID string) (SessionRecord, error) {
	session, ok := s.sessions[sessionID]
	if !ok {
		return SessionRecord{}, errors.New("missing")
	}
	return session, nil
}

func (s *memoryStore) TouchSession(_ context.Context, sessionID string, lastSeenAt time.Time) error {
	s.touched[sessionID] = lastSeenAt
	return nil
}

func (s *memoryStore) RevokeSession(_ context.Context, sessionID string, revokedAt time.Time) error {
	s.revoked[sessionID] = revokedAt
	session := s.sessions[sessionID]
	session.RevokedAt = &revokedAt
	s.sessions[sessionID] = session
	return nil
}

func (s *memoryStore) RecordSessionEvent(_ context.Context, event SessionEvent) error {
	s.events = append(s.events, event)
	return nil
}

func testServiceWithSession(session SessionRecord) (*Service, *memoryStore, time.Time) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	store := &memoryStore{
		sessions: map[string]SessionRecord{session.SessionID: session},
		touched:  map[string]time.Time{},
		revoked:  map[string]time.Time{},
		events:   []SessionEvent{},
	}
	service := NewService(store, TimeoutPolicy{
		IdleTimeout:     30 * time.Minute,
		AbsoluteTimeout: 12 * time.Hour,
	}, func() time.Time { return now })
	return service, store, now
}

func activeSession(now time.Time) SessionRecord {
	return SessionRecord{
		TenantID:              "tenant-001",
		UserID:                "user-001",
		SessionID:             "session-001",
		AccessTokenID:         "access-001",
		RefreshTokenID:        "refresh-001",
		IssuedAt:              now.Add(-time.Hour),
		AccessTokenExpiresAt:  now.Add(time.Hour),
		RefreshTokenExpiresAt: now.Add(24 * time.Hour),
		LastSeenAt:            now.Add(-5 * time.Minute),
		IPAddress:             "127.0.0.1",
		UserAgent:             "test-agent",
	}
}

func TestValidateActiveSessionTouchesLastSeen(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	service, store, _ := testServiceWithSession(activeSession(now))

	result, err := service.ValidateSession(context.Background(), ValidationInput{
		SessionID:     "session-001",
		AccessTokenID: "access-001",
	})
	if err != nil {
		t.Fatalf("ValidateSession error: %v", err)
	}

	if result.TenantID != "tenant-001" {
		t.Fatalf("tenant mismatch: %s", result.TenantID)
	}
	if store.touched["session-001"].IsZero() {
		t.Fatalf("last seen was not updated")
	}
	if len(store.events) == 0 || store.events[len(store.events)-1].ReasonCode != "active" {
		t.Fatalf("session validation event was not recorded")
	}
}

func TestRejectsExpiredAccessToken(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	session := activeSession(now)
	session.AccessTokenExpiresAt = now.Add(-time.Minute)
	service, _, _ := testServiceWithSession(session)

	_, err := service.ValidateSession(context.Background(), ValidationInput{
		SessionID:     "session-001",
		AccessTokenID: "access-001",
	})
	if !errors.Is(err, ErrAccessExpired) {
		t.Fatalf("expected ErrAccessExpired, got %v", err)
	}
}

func TestRejectsExpiredRefreshToken(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	session := activeSession(now)
	session.RefreshTokenExpiresAt = now.Add(-time.Minute)
	service, _, _ := testServiceWithSession(session)

	_, err := service.ValidateSession(context.Background(), ValidationInput{
		SessionID:     "session-001",
		AccessTokenID: "access-001",
	})
	if !errors.Is(err, ErrRefreshExpired) {
		t.Fatalf("expected ErrRefreshExpired, got %v", err)
	}
}

func TestRejectsIdleTimeout(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	session := activeSession(now)
	session.LastSeenAt = now.Add(-31 * time.Minute)
	service, _, _ := testServiceWithSession(session)

	_, err := service.ValidateSession(context.Background(), ValidationInput{
		SessionID:     "session-001",
		AccessTokenID: "access-001",
	})
	if !errors.Is(err, ErrIdleTimeoutExceeded) {
		t.Fatalf("expected ErrIdleTimeoutExceeded, got %v", err)
	}
}

func TestRejectsAbsoluteTimeout(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	session := activeSession(now)
	session.IssuedAt = now.Add(-13 * time.Hour)
	session.LastSeenAt = now.Add(-5 * time.Minute)
	service, _, _ := testServiceWithSession(session)

	_, err := service.ValidateSession(context.Background(), ValidationInput{
		SessionID:     "session-001",
		AccessTokenID: "access-001",
	})
	if !errors.Is(err, ErrAbsoluteTimeoutEnded) {
		t.Fatalf("expected ErrAbsoluteTimeoutEnded, got %v", err)
	}
}

func TestRejectsRevokedSession(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	session := activeSession(now)
	revokedAt := now.Add(-time.Minute)
	session.RevokedAt = &revokedAt
	service, _, _ := testServiceWithSession(session)

	_, err := service.ValidateSession(context.Background(), ValidationInput{
		SessionID:     "session-001",
		AccessTokenID: "access-001",
	})
	if !errors.Is(err, ErrSessionRevoked) {
		t.Fatalf("expected ErrSessionRevoked, got %v", err)
	}
}

func TestLogoutRevokesSession(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	service, store, _ := testServiceWithSession(activeSession(now))

	if err := service.Logout(context.Background(), "session-001"); err != nil {
		t.Fatalf("Logout error: %v", err)
	}

	if store.revoked["session-001"].IsZero() {
		t.Fatalf("session was not revoked")
	}
}

func TestValidateHTTP(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	service, _, _ := testServiceWithSession(activeSession(now))

	req := httptest.NewRequest(http.MethodGet, "/api/auth/session/validate", nil)
	req.Header.Set("X-Session-ID", "session-001")
	req.Header.Set("X-Access-Token-ID", "access-001")
	rec := httptest.NewRecorder()

	service.ValidateHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestLogoutHTTP(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	service, store, _ := testServiceWithSession(activeSession(now))

	req := httptest.NewRequest(http.MethodPost, "/api/auth/session/logout", bytes.NewBufferString(`{"session_id":"session-001"}`))
	rec := httptest.NewRecorder()

	service.LogoutHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
	if store.revoked["session-001"].IsZero() {
		t.Fatalf("session was not revoked")
	}
}
