package publicapi

import (
	"context"
	"errors"
	"testing"
	"time"
)

type publicAPIAppAuthStoreMock struct {
	lastCmd AuthenticatePublicAPIAppCommand
	result  AuthenticatePublicAPIAppResult
	err     error
	called  bool
}

func (m *publicAPIAppAuthStoreMock) AuthenticateApp(_ context.Context, cmd AuthenticatePublicAPIAppCommand) (AuthenticatePublicAPIAppResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestAuthenticatePublicAPIAppRequestValidate_Success(t *testing.T) {
	req := AuthenticatePublicAPIAppRequest{
		TenantID:       "tenant-a",
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "production",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestAuthenticatePublicAPIAppRequestValidate_InvalidEnvironment(t *testing.T) {
	req := AuthenticatePublicAPIAppRequest{
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "prod",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestAuthenticatePublicAPIAppRequestValidate_EmptyScopes(t *testing.T) {
	req := AuthenticatePublicAPIAppRequest{
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "sandbox",
		RequiredScopes: []string{},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestAuthenticatePublicAPIAppRequestValidate_DuplicateScopes(t *testing.T) {
	req := AuthenticatePublicAPIAppRequest{
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "sandbox",
		RequiredScopes: []string{"erp.read", "erp.read"},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestAuthenticatePublicAPIAppUsecaseAuthenticate_Success(t *testing.T) {
	store := &publicAPIAppAuthStoreMock{
		result: AuthenticatePublicAPIAppResult{
			RequestID:     "req-001",
			AppID:         "app-001",
			APIKeyID:      "key-001",
			Environment:   "production",
			GrantedScopes: []string{"erp.read", "erp.write"},
			AuthStatus:    "authenticated",
			Authenticated: true,
		},
	}

	usecase := NewAuthenticatePublicAPIAppUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 16, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		TenantID:       "tenant-a",
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "production",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Environment != "production" {
		t.Fatalf("beklenen environment production, alinan: %s", store.lastCmd.Environment)
	}

	if !resp.Authenticated {
		t.Fatalf("beklenen authenticated true")
	}

	if resp.AuthStatus != "authenticated" {
		t.Fatalf("beklenen auth_status authenticated, alinan: %s", resp.AuthStatus)
	}

	if resp.DenialReason != "" {
		t.Fatalf("authenticated durumda denial_reason bos olmaliydi")
	}

	if !resp.AuthenticatedAt.Equal(time.Date(2026, 4, 26, 16, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen authenticated_at sabit zaman")
	}
}

func TestAuthenticatePublicAPIAppUsecaseAuthenticate_DeniedSuccess(t *testing.T) {
	store := &publicAPIAppAuthStoreMock{
		result: AuthenticatePublicAPIAppResult{
			RequestID:     "req-002",
			AppID:         "app-001",
			APIKeyID:      "key-001",
			Environment:   "sandbox",
			GrantedScopes: []string{"erp.read"},
			AuthStatus:    "denied",
			Authenticated: false,
			DenialReason:  "scope not granted",
		},
	}

	usecase := NewAuthenticatePublicAPIAppUsecase(store)

	resp, err := usecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		RequestID:      "req-002",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "sandbox",
		RequiredScopes: []string{"erp.write"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Authenticated {
		t.Fatalf("beklenen authenticated false")
	}

	if resp.AuthStatus != "denied" {
		t.Fatalf("beklenen auth_status denied, alinan: %s", resp.AuthStatus)
	}

	if resp.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestAuthenticatePublicAPIAppUsecaseAuthenticate_FallbackDenied(t *testing.T) {
	store := &publicAPIAppAuthStoreMock{
		result: AuthenticatePublicAPIAppResult{},
	}

	usecase := NewAuthenticatePublicAPIAppUsecase(store)

	resp, err := usecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		RequestID:      "req-003",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "sandbox",
		RequiredScopes: []string{"usage.read"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Authenticated {
		t.Fatalf("beklenen authenticated false")
	}

	if resp.AuthStatus != "denied" {
		t.Fatalf("beklenen auth_status denied, alinan: %s", resp.AuthStatus)
	}

	if resp.DenialReason == "" {
		t.Fatalf("beklenen fallback denial_reason dolu")
	}
}

func TestAuthenticatePublicAPIAppUsecaseAuthenticate_ValidationError(t *testing.T) {
	store := &publicAPIAppAuthStoreMock{}
	usecase := NewAuthenticatePublicAPIAppUsecase(store)

	_, err := usecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "prod",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestAuthenticatePublicAPIAppUsecaseAuthenticate_StoreError(t *testing.T) {
	store := &publicAPIAppAuthStoreMock{
		err: errors.New("authenticate app failed"),
	}

	usecase := NewAuthenticatePublicAPIAppUsecase(store)

	_, err := usecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "sandbox",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestAuthenticatePublicAPIAppResponseValidate_InvalidAuthenticatedAt(t *testing.T) {
	resp := AuthenticatePublicAPIAppResponse{
		RequestID:     "req-001",
		AppID:         "app-001",
		APIKeyID:      "key-001",
		Environment:   "sandbox",
		GrantedScopes: []string{"erp.read"},
		AuthStatus:    "authenticated",
		Authenticated: true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
