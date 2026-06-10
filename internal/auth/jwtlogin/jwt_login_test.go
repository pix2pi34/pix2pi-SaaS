package jwtlogin

import (
	"context"
	"errors"
	"testing"
	"time"
)

type memoryStore struct {
	users       map[string]User
	memberships map[string]TenantMembership
	sessions    []SessionRecord
}

func (s *memoryStore) FindUserByEmail(_ context.Context, email string) (User, error) {
	user, ok := s.users[email]
	if !ok {
		return User{}, errors.New("not found")
	}
	return user, nil
}

func (s *memoryStore) FindTenantMembership(_ context.Context, userID string, tenantID string) (TenantMembership, error) {
	membership, ok := s.memberships[userID+"|"+tenantID]
	if !ok {
		return TenantMembership{}, errors.New("not found")
	}
	return membership, nil
}

func (s *memoryStore) RecordLoginSession(_ context.Context, record SessionRecord) error {
	s.sessions = append(s.sessions, record)
	return nil
}

func testService(t *testing.T) (*Service, *memoryStore, HMACPasswordVerifier) {
	t.Helper()

	verifier := HMACPasswordVerifier{Secret: []byte("password-secret-which-is-long-enough-32")}
	store := &memoryStore{
		users: map[string]User{
			"owner@example.com": {
				ID:           "user-001",
				Email:        "owner@example.com",
				PasswordHash: verifier.HashPassword("correct-password"),
				Status:       "active",
			},
		},
		memberships: map[string]TenantMembership{
			"user-001|tenant-001": {
				TenantID: "tenant-001",
				UserID:   "user-001",
				RoleCode: "owner",
				Status:   "active",
			},
		},
	}

	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	service, err := NewService(Config{
		Issuer:          "pix2pi-auth",
		Audience:        "pix2pi-panel",
		Secret:          []byte("jwt-secret-which-is-long-enough-32-bytes"),
		AccessTokenTTL:  time.Hour,
		RefreshTokenTTL: 30 * 24 * time.Hour,
		Now:             func() time.Time { return now },
	}, store, verifier)
	if err != nil {
		t.Fatalf("NewService error: %v", err)
	}

	return service, store, verifier
}

func TestLoginIssuesAndVerifiesJWT(t *testing.T) {
	service, store, _ := testService(t)

	result, err := service.Login(context.Background(), LoginInput{
		Email:     "owner@example.com",
		Password:  "correct-password",
		TenantID:  "tenant-001",
		IPAddress: "127.0.0.1",
		UserAgent: "go-test",
	})
	if err != nil {
		t.Fatalf("Login error: %v", err)
	}

	if result.AccessToken == "" || result.RefreshToken == "" {
		t.Fatalf("expected access and refresh tokens")
	}
	if len(store.sessions) != 1 {
		t.Fatalf("expected one session record, got %d", len(store.sessions))
	}

	claims, err := service.Verify(result.AccessToken)
	if err != nil {
		t.Fatalf("Verify access token error: %v", err)
	}

	if claims.Subject != "user-001" {
		t.Fatalf("subject mismatch: %s", claims.Subject)
	}
	if claims.TenantID != "tenant-001" {
		t.Fatalf("tenant mismatch: %s", claims.TenantID)
	}
	if claims.RoleCode != "owner" {
		t.Fatalf("role mismatch: %s", claims.RoleCode)
	}
	if claims.TokenUse != "access" {
		t.Fatalf("token use mismatch: %s", claims.TokenUse)
	}
}

func TestLoginRejectsWrongPassword(t *testing.T) {
	service, _, _ := testService(t)

	_, err := service.Login(context.Background(), LoginInput{
		Email:    "owner@example.com",
		Password: "wrong-password",
		TenantID: "tenant-001",
	})
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}
}

func TestLoginRejectsTenantWithoutMembership(t *testing.T) {
	service, _, _ := testService(t)

	_, err := service.Login(context.Background(), LoginInput{
		Email:    "owner@example.com",
		Password: "correct-password",
		TenantID: "tenant-999",
	})
	if !errors.Is(err, ErrTenantForbidden) {
		t.Fatalf("expected ErrTenantForbidden, got %v", err)
	}
}

func TestVerifyRejectsExpiredToken(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)

	service, err := NewService(Config{
		Secret:          []byte("jwt-secret-which-is-long-enough-32-bytes"),
		AccessTokenTTL:  time.Hour,
		RefreshTokenTTL: time.Hour,
		Now:             func() time.Time { return now },
	}, &memoryStore{}, HMACPasswordVerifier{Secret: []byte("password-secret-which-is-long-enough-32")})
	if err != nil {
		t.Fatalf("NewService error: %v", err)
	}

	token, err := service.Sign(Claims{
		Issuer:    "pix2pi-auth",
		Audience:  "pix2pi-panel",
		Subject:   "user-001",
		TenantID:  "tenant-001",
		RoleCode:  "owner",
		SessionID: "sess-001",
		TokenID:   "token-001",
		TokenUse:  "access",
		IssuedAt:  now.Add(-2 * time.Hour).Unix(),
		ExpiresAt: now.Add(-time.Minute).Unix(),
	})
	if err != nil {
		t.Fatalf("Sign error: %v", err)
	}

	_, err = service.Verify(token)
	if !errors.Is(err, ErrTokenExpired) {
		t.Fatalf("expected ErrTokenExpired, got %v", err)
	}
}

func TestVerifyRejectsTamperedToken(t *testing.T) {
	service, _, _ := testService(t)

	result, err := service.Login(context.Background(), LoginInput{
		Email:    "owner@example.com",
		Password: "correct-password",
		TenantID: "tenant-001",
	})
	if err != nil {
		t.Fatalf("Login error: %v", err)
	}

	_, err = service.Verify(result.AccessToken + "tamper")
	if !errors.Is(err, ErrTokenInvalid) {
		t.Fatalf("expected ErrTokenInvalid, got %v", err)
	}
}
