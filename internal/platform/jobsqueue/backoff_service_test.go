package jobsqueue

import (
	"context"
	"testing"
	"time"
)

func TestCalculateJobBackoffRequestValidate_Success(t *testing.T) {
	req := CalculateJobBackoffRequest{
		TenantID:         "tenant-a",
		JobID:            "job-1",
		Strategy:         "exponential",
		AttemptNo:        3,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  600,
		JitterPercent:    20,
		LastErrorCode:    "EMAIL_TIMEOUT",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCalculateJobBackoffRequestValidate_InvalidStrategy(t *testing.T) {
	req := CalculateJobBackoffRequest{
		JobID:            "job-1",
		Strategy:         "adaptive",
		AttemptNo:        3,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  600,
		JitterPercent:    20,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCalculateJobBackoffRequestValidate_InvalidAttemptNo(t *testing.T) {
	req := CalculateJobBackoffRequest{
		JobID:            "job-1",
		Strategy:         "fixed",
		AttemptNo:        0,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  600,
		JitterPercent:    20,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCalculateJobBackoffRequestValidate_InvalidMaxDelay(t *testing.T) {
	req := CalculateJobBackoffRequest{
		JobID:            "job-1",
		Strategy:         "fixed",
		AttemptNo:        1,
		BaseDelaySeconds: 60,
		MaxDelaySeconds:  30,
		JitterPercent:    20,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCalculateJobBackoffUsecaseCalculate_FixedSuccess(t *testing.T) {
	usecase := NewCalculateJobBackoffUsecase()
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 14, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		TenantID:         "tenant-a",
		JobID:            "job-1",
		Strategy:         "fixed",
		AttemptNo:        2,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  300,
		JitterPercent:    0,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.PlannedDelaySeconds != 30 {
		t.Fatalf("beklenen delay 30, alinan: %d", resp.PlannedDelaySeconds)
	}

	expectedRetryAt := time.Date(2026, 4, 25, 14, 0, 30, 0, time.UTC)
	if !resp.RetryAt.Equal(expectedRetryAt) {
		t.Fatalf("beklenen retry_at %v, alinan: %v", expectedRetryAt, resp.RetryAt)
	}
}

func TestCalculateJobBackoffUsecaseCalculate_LinearSuccess(t *testing.T) {
	usecase := NewCalculateJobBackoffUsecase()
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 14, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		JobID:            "job-2",
		Strategy:         "linear",
		AttemptNo:        3,
		BaseDelaySeconds: 20,
		MaxDelaySeconds:  300,
		JitterPercent:    0,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.PlannedDelaySeconds != 60 {
		t.Fatalf("beklenen delay 60, alinan: %d", resp.PlannedDelaySeconds)
	}
}

func TestCalculateJobBackoffUsecaseCalculate_ExponentialCappedSuccess(t *testing.T) {
	usecase := NewCalculateJobBackoffUsecase()
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 14, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		JobID:            "job-3",
		Strategy:         "exponential",
		AttemptNo:        6,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  300,
		JitterPercent:    0,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.PlannedDelaySeconds != 300 {
		t.Fatalf("beklenen capped delay 300, alinan: %d", resp.PlannedDelaySeconds)
	}
}

func TestCalculateJobBackoffUsecaseCalculate_DeterministicJitterSuccess(t *testing.T) {
	usecase := NewCalculateJobBackoffUsecase()
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 14, 0, 0, 0, time.UTC)
	}

	resp1, err := usecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		JobID:            "job-4",
		Strategy:         "fixed",
		AttemptNo:        2,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  300,
		JitterPercent:    20,
		LastErrorCode:    "EMAIL_TIMEOUT",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	resp2, err := usecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		JobID:            "job-4",
		Strategy:         "fixed",
		AttemptNo:        2,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  300,
		JitterPercent:    20,
		LastErrorCode:    "EMAIL_TIMEOUT",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp1.PlannedDelaySeconds != resp2.PlannedDelaySeconds {
		t.Fatalf("beklenen deterministic jitter aynı sonucu vermeliydi")
	}
}

func TestCalculateJobBackoffUsecaseCalculate_ValidationError(t *testing.T) {
	usecase := NewCalculateJobBackoffUsecase()

	_, err := usecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		JobID:            "",
		Strategy:         "fixed",
		AttemptNo:        1,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  300,
		JitterPercent:    0,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCalculateJobBackoffResponseValidate_InvalidCalculatedAt(t *testing.T) {
	resp := CalculateJobBackoffResponse{
		JobID:               "job-1",
		Strategy:            "fixed",
		AttemptNo:           1,
		BaseDelaySeconds:    30,
		MaxDelaySeconds:     300,
		JitterPercent:       0,
		PlannedDelaySeconds: 30,
		RetryAt:             time.Date(2026, 4, 25, 14, 0, 30, 0, time.UTC),
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
