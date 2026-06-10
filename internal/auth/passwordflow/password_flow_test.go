package passwordflow

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
	invites     map[string]Invite
	accepted    map[string]time.Time
	credentials map[string]Credential
	tenantMap   map[string]map[string]bool
	resetTokens map[string]ResetToken
	sessions    map[string]Session
	touched     map[string]time.Time
	events      []Event
}

func (s *memoryStore) GetInviteByToken(_ context.Context, token string) (Invite, error) {
	invite, ok := s.invites[token]
	if !ok {
		return Invite{}, errors.New("invite missing")
	}
	return invite, nil
}

func (s *memoryStore) MarkInviteAccepted(_ context.Context, token string, acceptedAt time.Time) error {
	s.accepted[token] = acceptedAt
	invite := s.invites[token]
	invite.Status = "accepted"
	s.invites[token] = invite
	return nil
}

func (s *memoryStore) SaveCredential(_ context.Context, credential Credential) error {
	s.credentials[credential.Email] = credential
	return nil
}

func (s *memoryStore) GetCredentialByEmail(_ context.Context, email string) (Credential, error) {
	credential, ok := s.credentials[normalizeEmail(email)]
	if !ok {
		return Credential{}, errors.New("credential missing")
	}
	return credential, nil
}

func (s *memoryStore) UserHasTenant(_ context.Context, userID string, tenantID string) (bool, error) {
	return s.tenantMap[userID][tenantID], nil
}

func (s *memoryStore) SaveResetToken(_ context.Context, token ResetToken) error {
	s.resetTokens[token.TokenHash] = token
	return nil
}

func (s *memoryStore) GetResetToken(_ context.Context, tokenHash string) (ResetToken, error) {
	token, ok := s.resetTokens[tokenHash]
	if !ok {
		return ResetToken{}, errors.New("token missing")
	}
	return token, nil
}

func (s *memoryStore) ConsumeResetToken(_ context.Context, tokenHash string, consumedAt time.Time) error {
	token := s.resetTokens[tokenHash]
	token.ConsumedAt = &consumedAt
	s.resetTokens[tokenHash] = token
	return nil
}

func (s *memoryStore) SaveLoginSession(_ context.Context, session Session) error {
	s.sessions[session.SessionID] = session
	return nil
}

func (s *memoryStore) GetLoginSession(_ context.Context, sessionID string) (Session, error) {
	session, ok := s.sessions[sessionID]
	if !ok {
		return Session{}, errors.New("session missing")
	}
	return session, nil
}

func (s *memoryStore) TouchLoginSession(_ context.Context, sessionID string, lastSeenAt time.Time) error {
	s.touched[sessionID] = lastSeenAt
	session := s.sessions[sessionID]
	session.LastSeenAt = lastSeenAt
	s.sessions[sessionID] = session
	return nil
}

func (s *memoryStore) RecordEvent(_ context.Context, event Event) error {
	s.events = append(s.events, event)
	return nil
}

func testService() (*Service, *memoryStore, HMACPasswordHasher, time.Time) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	hasher := HMACPasswordHasher{Secret: []byte("password-flow-secret-which-is-long-enough")}
	store := &memoryStore{
		invites: map[string]Invite{
			"invite-001": {
				Token:     "invite-001",
				UserID:    "user-001",
				Email:     "owner@example.com",
				Status:    "pending",
				ExpiresAt: now.Add(time.Hour),
			},
		},
		accepted:    map[string]time.Time{},
		credentials: map[string]Credential{},
		tenantMap: map[string]map[string]bool{
			"user-001": {"tenant-001": true},
		},
		resetTokens: map[string]ResetToken{},
		sessions:    map[string]Session{},
		touched:     map[string]time.Time{},
		events:      []Event{},
	}

	service := NewService(store, hasher, PasswordPolicy{
		MinLength:    12,
		RequireUpper: true,
		RequireLower: true,
		RequireDigit: true,
	}, func() time.Time { return now })

	return service, store, hasher, now
}

func TestInitialPasswordSetupPersistsCredentialAndAcceptsInvite(t *testing.T) {
	service, store, _, _ := testService()

	result, err := service.SetInitialPassword(context.Background(), InitialPasswordInput{
		InviteToken:   "invite-001",
		Password:      "StrongPass123",
		Confirm:       "StrongPass123",
		CorrelationID: "corr-001",
	})
	if err != nil {
		t.Fatalf("SetInitialPassword error: %v", err)
	}

	if result.UserID != "user-001" {
		t.Fatalf("user mismatch: %s", result.UserID)
	}
	if store.credentials["owner@example.com"].PasswordHash == "" {
		t.Fatalf("password hash missing")
	}
	if store.accepted["invite-001"].IsZero() {
		t.Fatalf("invite was not accepted")
	}
}

func TestPasswordPolicyRejectsWeakAndMismatch(t *testing.T) {
	service, _, _, _ := testService()

	_, err := service.SetInitialPassword(context.Background(), InitialPasswordInput{
		InviteToken: "invite-001",
		Password:    "weak",
		Confirm:     "weak",
	})
	if !errors.Is(err, ErrPasswordWeak) {
		t.Fatalf("expected ErrPasswordWeak, got %v", err)
	}

	_, err = service.SetInitialPassword(context.Background(), InitialPasswordInput{
		InviteToken: "invite-001",
		Password:    "StrongPass123",
		Confirm:     "StrongPass124",
	})
	if !errors.Is(err, ErrPasswordMismatch) {
		t.Fatalf("expected ErrPasswordMismatch, got %v", err)
	}
}

func TestPasswordResetFlowUpdatesHashAndConsumesToken(t *testing.T) {
	service, store, hasher, now := testService()
	store.credentials["owner@example.com"] = Credential{
		UserID:       "user-001",
		Email:        "owner@example.com",
		PasswordHash: hasher.Hash("OldStrong123"),
		Status:       "active",
	}

	reset, err := service.RequestPasswordReset(context.Background(), PasswordResetRequestInput{
		Email:         "owner@example.com",
		CorrelationID: "corr-reset",
	})
	if err != nil {
		t.Fatalf("RequestPasswordReset error: %v", err)
	}
	if reset.Token == "" {
		t.Fatalf("reset token missing")
	}

	result, err := service.CompletePasswordReset(context.Background(), PasswordResetCompleteInput{
		ResetToken:    reset.Token,
		Password:      "NewStrong123",
		Confirm:       "NewStrong123",
		CorrelationID: "corr-reset-complete",
	})
	if err != nil {
		t.Fatalf("CompletePasswordReset error: %v", err)
	}
	if result.UserID != "user-001" {
		t.Fatalf("user mismatch: %s", result.UserID)
	}

	tokenHash := hasher.Hash(reset.Token)
	if store.resetTokens[tokenHash].ConsumedAt == nil {
		t.Fatalf("reset token was not consumed")
	}
	if !store.credentials["owner@example.com"].PasswordChangedAt.Equal(now) {
		t.Fatalf("password change timestamp mismatch")
	}
}

func TestLoginCreatesSessionForTenant(t *testing.T) {
	service, store, hasher, _ := testService()
	store.credentials["owner@example.com"] = Credential{
		UserID:       "user-001",
		Email:        "owner@example.com",
		PasswordHash: hasher.Hash("StrongPass123"),
		Status:       "active",
	}

	result, err := service.Login(context.Background(), LoginInput{
		Email:         "OWNER@EXAMPLE.COM",
		Password:      "StrongPass123",
		TenantID:      "tenant-001",
		CorrelationID: "corr-login",
	})
	if err != nil {
		t.Fatalf("Login error: %v", err)
	}

	if result.SessionID == "" || result.AccessTokenID == "" || result.RefreshTokenID == "" {
		t.Fatalf("session token ids missing")
	}
	if result.NextPath != "/tenant-select/" {
		t.Fatalf("next path mismatch: %s", result.NextPath)
	}
	if _, ok := store.sessions[result.SessionID]; !ok {
		t.Fatalf("session was not saved")
	}
}

func TestLoginRejectsWrongPasswordAndRequiresTenant(t *testing.T) {
	service, store, hasher, _ := testService()
	store.credentials["owner@example.com"] = Credential{
		UserID:       "user-001",
		Email:        "owner@example.com",
		PasswordHash: hasher.Hash("StrongPass123"),
		Status:       "active",
	}

	_, err := service.Login(context.Background(), LoginInput{
		Email:    "owner@example.com",
		Password: "WrongPass123",
		TenantID: "tenant-001",
	})
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}

	_, err = service.Login(context.Background(), LoginInput{
		Email:    "owner@example.com",
		Password: "StrongPass123",
	})
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestSessionValidationTouchesSession(t *testing.T) {
	service, store, hasher, _ := testService()
	store.credentials["owner@example.com"] = Credential{
		UserID:       "user-001",
		Email:        "owner@example.com",
		PasswordHash: hasher.Hash("StrongPass123"),
		Status:       "active",
	}

	login, err := service.Login(context.Background(), LoginInput{
		Email:    "owner@example.com",
		Password: "StrongPass123",
		TenantID: "tenant-001",
	})
	if err != nil {
		t.Fatalf("Login error: %v", err)
	}

	validated, err := service.ValidateSession(context.Background(), SessionValidationInput{
		SessionID:     login.SessionID,
		AccessTokenID: login.AccessTokenID,
	})
	if err != nil {
		t.Fatalf("ValidateSession error: %v", err)
	}
	if validated.SessionID != login.SessionID {
		t.Fatalf("session mismatch: %s", validated.SessionID)
	}
	if store.touched[login.SessionID].IsZero() {
		t.Fatalf("session was not touched")
	}
}

func TestHTTPHandlers(t *testing.T) {
	service, store, hasher, _ := testService()
	store.credentials["owner@example.com"] = Credential{
		UserID:       "user-001",
		Email:        "owner@example.com",
		PasswordHash: hasher.Hash("StrongPass123"),
		Status:       "active",
	}

	body := bytes.NewBufferString(`{"email":"owner@example.com","password":"StrongPass123","tenant_id":"tenant-001"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", body)
	rec := httptest.NewRecorder()

	service.LoginHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
}
