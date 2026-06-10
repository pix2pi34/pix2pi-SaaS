package passwordflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

func testService(t *testing.T) (*Service, *MemoryRepo) {
	t.Helper()

	repo := NewMemoryRepo()
	membership := StaticMembership{Allowed: map[string]bool{
		key("user-1", "tenant-1"): true,
	}}

	service := NewService(repo, membership, DefaultPasswordPolicy())
	service.SetClock(func() time.Time {
		return time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	})

	return service, repo
}

func TestSetupPasswordHashesAndAudits(t *testing.T) {
	ctx := context.Background()
	service, repo := testService(t)

	err := service.SetupPassword(ctx, "tenant-1", "user-1", "StrongPass1!", "StrongPass1!", "corr-1")
	if err != nil {
		t.Fatalf("setup password failed: %v", err)
	}

	credential, err := repo.GetCredential(ctx, "user-1", "tenant-1")
	if err != nil {
		t.Fatalf("credential missing: %v", err)
	}
	if credential.PasswordHash == "" || credential.PasswordSalt == "" {
		t.Fatalf("credential hash/salt not stored")
	}
	if credential.PasswordHash == "StrongPass1!" {
		t.Fatalf("password stored in plain text")
	}
	if !VerifyPassword("StrongPass1!", credential.PasswordSalt, credential.PasswordHash) {
		t.Fatalf("password verification failed")
	}
	if len(repo.AuditEvents()) == 0 {
		t.Fatalf("audit event not recorded")
	}
}

func TestWeakPasswordRejected(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	err := service.SetupPassword(ctx, "tenant-1", "user-1", "weak", "weak", "corr-2")
	if !errors.Is(err, ErrWeakPassword) {
		t.Fatalf("expected weak password error, got %v", err)
	}
}

func TestPasswordConfirmationMismatchRejected(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	err := service.SetupPassword(ctx, "tenant-1", "user-1", "StrongPass1!", "StrongPass2!", "corr-3")
	if !errors.Is(err, ErrPasswordMismatch) {
		t.Fatalf("expected mismatch error, got %v", err)
	}
}

func TestLoginCreatesSessionAndTenantSelectionHandoff(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	if err := service.SetupPassword(ctx, "tenant-1", "user-1", "StrongPass1!", "StrongPass1!", "corr-4"); err != nil {
		t.Fatalf("setup failed: %v", err)
	}

	session, nextRoute, err := service.Login(ctx, "tenant-1", "user-1", "StrongPass1!", "corr-5")
	if err != nil {
		t.Fatalf("login failed: %v", err)
	}
	if session.SessionID == "" || session.AccessTokenHash == "" || session.RefreshTokenHash == "" {
		t.Fatalf("session tokens not created")
	}
	if nextRoute != "/tenant-select/" {
		t.Fatalf("unexpected handoff route: %s", nextRoute)
	}
}

func TestWrongPasswordRejected(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	if err := service.SetupPassword(ctx, "tenant-1", "user-1", "StrongPass1!", "StrongPass1!", "corr-6"); err != nil {
		t.Fatalf("setup failed: %v", err)
	}

	_, _, err := service.Login(ctx, "tenant-1", "user-1", "WrongPass1!", "corr-7")
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected invalid credentials, got %v", err)
	}
}

func TestTenantMembershipRequired(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	err := service.SetupPassword(ctx, "tenant-2", "user-1", "StrongPass1!", "StrongPass1!", "corr-8")
	if !errors.Is(err, ErrTenantForbidden) {
		t.Fatalf("expected tenant forbidden, got %v", err)
	}
}

func TestPasswordResetFlow(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	if err := service.SetupPassword(ctx, "tenant-1", "user-1", "StrongPass1!", "StrongPass1!", "corr-9"); err != nil {
		t.Fatalf("setup failed: %v", err)
	}

	raw, token, err := service.RequestPasswordReset(ctx, "tenant-1", "user-1", "127.0.0.1", "corr-10")
	if err != nil {
		t.Fatalf("reset request failed: %v", err)
	}
	if raw == "" || token.TokenHash == "" {
		t.Fatalf("reset token missing")
	}

	if err := service.ConsumePasswordReset(ctx, raw, "NewStrong1!", "NewStrong1!", "corr-11"); err != nil {
		t.Fatalf("consume reset failed: %v", err)
	}

	if _, _, err := service.Login(ctx, "tenant-1", "user-1", "NewStrong1!", "corr-12"); err != nil {
		t.Fatalf("login with new password failed: %v", err)
	}
}

func TestSessionValidationAndLogout(t *testing.T) {
	ctx := context.Background()
	service, _ := testService(t)

	if err := service.SetupPassword(ctx, "tenant-1", "user-1", "StrongPass1!", "StrongPass1!", "corr-13"); err != nil {
		t.Fatalf("setup failed: %v", err)
	}

	session, _, err := service.Login(ctx, "tenant-1", "user-1", "StrongPass1!", "corr-14")
	if err != nil {
		t.Fatalf("login failed: %v", err)
	}

	if _, err := service.ValidateSession(ctx, session.SessionID); err != nil {
		t.Fatalf("session validation failed: %v", err)
	}

	if err := service.Logout(ctx, session.SessionID); err != nil {
		t.Fatalf("logout failed: %v", err)
	}

	if _, err := service.ValidateSession(ctx, session.SessionID); !errors.Is(err, ErrSessionRevoked) {
		t.Fatalf("expected revoked session, got %v", err)
	}
}
