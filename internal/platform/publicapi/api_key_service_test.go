package publicapi

import (
	"context"
	"errors"
	"testing"
	"time"
)

type publicAPIKeyIssuerStoreMock struct {
	lastCmd IssuePublicAPIKeyCommand
	result  IssuePublicAPIKeyResult
	err     error
	called  bool
}

func (m *publicAPIKeyIssuerStoreMock) IssueAPIKey(_ context.Context, cmd IssuePublicAPIKeyCommand) (IssuePublicAPIKeyResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestIssuePublicAPIKeyRequestValidate_Success(t *testing.T) {
	req := IssuePublicAPIKeyRequest{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "production",
		Scopes:      []string{"erp.read", "erp.write"},
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestIssuePublicAPIKeyRequestValidate_InvalidEnvironment(t *testing.T) {
	req := IssuePublicAPIKeyRequest{
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "prod",
		Scopes:      []string{"erp.read"},
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIssuePublicAPIKeyRequestValidate_EmptyScopes(t *testing.T) {
	req := IssuePublicAPIKeyRequest{
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "sandbox",
		Scopes:      []string{},
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIssuePublicAPIKeyRequestValidate_DuplicateScopes(t *testing.T) {
	req := IssuePublicAPIKeyRequest{
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "sandbox",
		Scopes:      []string{"erp.read", "erp.read"},
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestIssuePublicAPIKeyUsecaseIssue_Success(t *testing.T) {
	expiresAt := time.Date(2026, 12, 31, 23, 59, 0, 0, time.UTC)

	store := &publicAPIKeyIssuerStoreMock{
		result: IssuePublicAPIKeyResult{
			APIKeyID:       "key-001",
			AppID:          "app-001",
			KeyName:        "erp-main-key",
			Environment:    "production",
			Scopes:         []string{"erp.read", "erp.write"},
			KeyPrefix:      "pix_live",
			KeyPreview:     "pix_live...abcd",
			KeyFingerprint: "fingerprint-001",
			Status:         "active",
			Issued:         true,
			ExpiresAt:      &expiresAt,
		},
	}

	usecase := NewIssuePublicAPIKeyUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 15, 30, 0, 0, time.UTC)
	}
	usecase.secretFn = func(_ IssuePublicAPIKeyRequest, _ time.Time) string {
		return "pix_live_1234567890abcdef"
	}

	resp, err := usecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "production",
		Scopes:      []string{"erp.read", "erp.write"},
		ExpiresAt:   &expiresAt,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.KeyHash == "" {
		t.Fatalf("key_hash bos olmamaliydi")
	}

	if store.lastCmd.KeyFingerprint == "" {
		t.Fatalf("key_fingerprint bos olmamaliydi")
	}

	if store.lastCmd.KeyPrefix != "pix_live" {
		t.Fatalf("beklenen key_prefix pix_live, alinan: %s", store.lastCmd.KeyPrefix)
	}

	if resp.APIKeyID != "key-001" {
		t.Fatalf("beklenen api_key_id key-001, alinan: %s", resp.APIKeyID)
	}

	if resp.Environment != "production" {
		t.Fatalf("beklenen environment production, alinan: %s", resp.Environment)
	}

	if resp.Status != "active" {
		t.Fatalf("beklenen status active, alinan: %s", resp.Status)
	}

	if !resp.Issued {
		t.Fatalf("beklenen issued true")
	}

	if !resp.IssuedAt.Equal(time.Date(2026, 4, 26, 15, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen issued_at sabit zaman")
	}
}

func TestIssuePublicAPIKeyUsecaseIssue_FallbackSuccess(t *testing.T) {
	store := &publicAPIKeyIssuerStoreMock{
		result: IssuePublicAPIKeyResult{},
	}

	usecase := NewIssuePublicAPIKeyUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 15, 40, 0, 0, time.UTC)
	}
	usecase.secretFn = func(_ IssuePublicAPIKeyRequest, _ time.Time) string {
		return "pix_test_1234567890abcdef"
	}

	resp, err := usecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		AppID:       "app-002",
		KeyName:     "sandbox-key",
		Environment: "sandbox",
		Scopes:      []string{"usage.read"},
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.APIKeyID == "" {
		t.Fatalf("fallback api_key_id dolu olmaliydi")
	}

	if resp.KeyPrefix != "pix_test" {
		t.Fatalf("beklenen key_prefix pix_test, alinan: %s", resp.KeyPrefix)
	}

	if resp.KeyPreview == "" {
		t.Fatalf("key_preview dolu olmaliydi")
	}

	if resp.KeyFingerprint == "" {
		t.Fatalf("key_fingerprint dolu olmaliydi")
	}

	if !resp.Issued {
		t.Fatalf("issued true olmaliydi")
	}
}

func TestIssuePublicAPIKeyUsecaseIssue_ValidationError(t *testing.T) {
	store := &publicAPIKeyIssuerStoreMock{}
	usecase := NewIssuePublicAPIKeyUsecase(store)

	_, err := usecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "prod",
		Scopes:      []string{"erp.read"},
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestIssuePublicAPIKeyUsecaseIssue_StoreError(t *testing.T) {
	store := &publicAPIKeyIssuerStoreMock{
		err: errors.New("issue api key failed"),
	}

	usecase := NewIssuePublicAPIKeyUsecase(store)

	_, err := usecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		AppID:       "app-001",
		KeyName:     "erp-main-key",
		Environment: "sandbox",
		Scopes:      []string{"erp.read"},
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestIssuePublicAPIKeyResponseValidate_InvalidIssuedAt(t *testing.T) {
	resp := IssuePublicAPIKeyResponse{
		APIKeyID:       "key-001",
		AppID:          "app-001",
		KeyName:        "erp-main-key",
		Environment:    "sandbox",
		Scopes:         []string{"erp.read"},
		KeyPrefix:      "pix_test",
		KeyPreview:     "pix_test...abcd",
		KeyFingerprint: "fingerprint-001",
		Status:         "active",
		Issued:         true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
