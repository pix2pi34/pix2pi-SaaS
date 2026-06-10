package publicapi

import (
	"context"
	"errors"
	"testing"
	"time"
)

type publicAPIQuotaStoreMock struct {
	lastCmd EvaluatePublicAPIQuotaCommand
	result  EvaluatePublicAPIQuotaResult
	err     error
	called  bool
}

func (m *publicAPIQuotaStoreMock) EvaluateQuota(_ context.Context, cmd EvaluatePublicAPIQuotaCommand) (EvaluatePublicAPIQuotaResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestEvaluatePublicAPIQuotaRequestValidate_Success(t *testing.T) {
	req := EvaluatePublicAPIQuotaRequest{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "production",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestEvaluatePublicAPIQuotaRequestValidate_InvalidQuotaWindow(t *testing.T) {
	req := EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "production",
		QuotaWindow: "second",
		Cost:        1,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEvaluatePublicAPIQuotaRequestValidate_InvalidCost(t *testing.T) {
	req := EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "production",
		QuotaWindow: "minute",
		Cost:        0,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEvaluatePublicAPIQuotaRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "production",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEvaluatePublicAPIQuotaUsecaseEvaluate_AllowedSuccess(t *testing.T) {
	store := &publicAPIQuotaStoreMock{
		result: EvaluatePublicAPIQuotaResult{
			RequestID:       "req-001",
			AppID:           "app-001",
			APIKeyID:        "key-001",
			Environment:     "production",
			QuotaWindow:     "minute",
			Limit:           600,
			UsedBefore:      10,
			Cost:            2,
			UsedAfter:       12,
			Remaining:       588,
			RateLimitStatus: "allowed",
			Allowed:         true,
		},
	}

	usecase := NewEvaluatePublicAPIQuotaUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 16, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "production",
		QuotaWindow: "minute",
		Cost:        2,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Cost != 2 {
		t.Fatalf("beklenen cost 2, alinan: %d", store.lastCmd.Cost)
	}

	if !resp.Allowed {
		t.Fatalf("beklenen allowed true")
	}

	if resp.RateLimitStatus != "allowed" {
		t.Fatalf("beklenen rate_limit_status allowed, alinan: %s", resp.RateLimitStatus)
	}

	if resp.Remaining != 588 {
		t.Fatalf("beklenen remaining 588, alinan: %d", resp.Remaining)
	}

	if resp.RetryAfterSeconds != 0 {
		t.Fatalf("allowed durumda retry_after_seconds 0 olmaliydi")
	}

	if !resp.EvaluatedAt.Equal(time.Date(2026, 4, 26, 16, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen evaluated_at sabit zaman")
	}
}

func TestEvaluatePublicAPIQuotaUsecaseEvaluate_LimitedSuccess(t *testing.T) {
	store := &publicAPIQuotaStoreMock{
		result: EvaluatePublicAPIQuotaResult{
			RequestID:         "req-002",
			AppID:             "app-001",
			APIKeyID:          "key-001",
			Environment:       "sandbox",
			QuotaWindow:       "minute",
			Limit:             60,
			UsedBefore:        60,
			Cost:              1,
			UsedAfter:         61,
			Remaining:         0,
			RateLimitStatus:   "limited",
			Allowed:           false,
			RetryAfterSeconds: 60,
			DenialReason:      "quota limit asildi",
		},
	}

	usecase := NewEvaluatePublicAPIQuotaUsecase(store)

	resp, err := usecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-002",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "sandbox",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Allowed {
		t.Fatalf("beklenen allowed false")
	}

	if resp.RateLimitStatus != "limited" {
		t.Fatalf("beklenen rate_limit_status limited, alinan: %s", resp.RateLimitStatus)
	}

	if resp.RetryAfterSeconds != 60 {
		t.Fatalf("beklenen retry_after_seconds 60, alinan: %d", resp.RetryAfterSeconds)
	}

	if resp.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestEvaluatePublicAPIQuotaUsecaseEvaluate_FallbackAllowedSuccess(t *testing.T) {
	store := &publicAPIQuotaStoreMock{
		result: EvaluatePublicAPIQuotaResult{},
	}

	usecase := NewEvaluatePublicAPIQuotaUsecase(store)

	resp, err := usecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-003",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "sandbox",
		QuotaWindow: "hour",
		Cost:        5,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !resp.Allowed {
		t.Fatalf("beklenen allowed true")
	}

	if resp.Limit != 1000 {
		t.Fatalf("beklenen sandbox/hour limit 1000, alinan: %d", resp.Limit)
	}

	if resp.UsedAfter != 5 {
		t.Fatalf("beklenen used_after 5, alinan: %d", resp.UsedAfter)
	}

	if resp.Remaining != 995 {
		t.Fatalf("beklenen remaining 995, alinan: %d", resp.Remaining)
	}
}

func TestEvaluatePublicAPIQuotaUsecaseEvaluate_ValidationError(t *testing.T) {
	store := &publicAPIQuotaStoreMock{}
	usecase := NewEvaluatePublicAPIQuotaUsecase(store)

	_, err := usecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "sandbox",
		QuotaWindow: "second",
		Cost:        1,
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestEvaluatePublicAPIQuotaUsecaseEvaluate_StoreError(t *testing.T) {
	store := &publicAPIQuotaStoreMock{
		err: errors.New("evaluate quota failed"),
	}

	usecase := NewEvaluatePublicAPIQuotaUsecase(store)

	_, err := usecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "sandbox",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestEvaluatePublicAPIQuotaResponseValidate_InvalidEvaluatedAt(t *testing.T) {
	resp := EvaluatePublicAPIQuotaResponse{
		RequestID:       "req-001",
		AppID:           "app-001",
		APIKeyID:        "key-001",
		Environment:     "sandbox",
		QuotaWindow:     "minute",
		Limit:           60,
		UsedBefore:      1,
		Cost:            1,
		UsedAfter:       2,
		Remaining:       58,
		RateLimitStatus: "allowed",
		Allowed:         true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
