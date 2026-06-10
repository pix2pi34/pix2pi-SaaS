package publicapi

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type publicAPIQuotaRowMock struct {
	values []any
	err    error
}

func (r *publicAPIQuotaRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type publicAPIQuotaQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *publicAPIQuotaQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestEvaluatePublicAPIQuotaSQLStoreEvaluateQuota_AllowedSuccess(t *testing.T) {
	db := &publicAPIQuotaQueryRowProviderMock{
		row: &publicAPIQuotaRowMock{
			values: []any{
				"req-001",
				"app-001",
				"key-001",
				"production",
				"minute",
				600,
				10,
				2,
				12,
				588,
				"allowed",
				true,
				0,
				"",
			},
		},
	}

	store := NewEvaluatePublicAPIQuotaSQLStore(db)

	result, err := store.EvaluateQuota(context.Background(), EvaluatePublicAPIQuotaCommand{
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

	if result.RequestID != "req-001" {
		t.Fatalf("beklenen request_id req-001, alinan: %s", result.RequestID)
	}

	if result.AppID != "app-001" {
		t.Fatalf("beklenen app_id app-001, alinan: %s", result.AppID)
	}

	if result.APIKeyID != "key-001" {
		t.Fatalf("beklenen api_key_id key-001, alinan: %s", result.APIKeyID)
	}

	if result.Environment != "production" {
		t.Fatalf("beklenen environment production, alinan: %s", result.Environment)
	}

	if result.QuotaWindow != "minute" {
		t.Fatalf("beklenen quota_window minute, alinan: %s", result.QuotaWindow)
	}

	if result.Limit != 600 {
		t.Fatalf("beklenen limit 600, alinan: %d", result.Limit)
	}

	if result.UsedBefore != 10 {
		t.Fatalf("beklenen used_before 10, alinan: %d", result.UsedBefore)
	}

	if result.Cost != 2 {
		t.Fatalf("beklenen cost 2, alinan: %d", result.Cost)
	}

	if result.UsedAfter != 12 {
		t.Fatalf("beklenen used_after 12, alinan: %d", result.UsedAfter)
	}

	if result.Remaining != 588 {
		t.Fatalf("beklenen remaining 588, alinan: %d", result.Remaining)
	}

	if result.RateLimitStatus != "allowed" {
		t.Fatalf("beklenen rate_limit_status allowed, alinan: %s", result.RateLimitStatus)
	}

	if !result.Allowed {
		t.Fatalf("beklenen allowed true")
	}

	if result.RetryAfterSeconds != 0 {
		t.Fatalf("allowed durumda retry_after_seconds 0 olmaliydi")
	}

	if result.DenialReason != "" {
		t.Fatalf("allowed durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_quotas") {
		t.Fatalf("public_api_quotas query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_usage") {
		t.Fatalf("public_api_usage query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "quota_window") {
		t.Fatalf("quota_window query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "retry_after_seconds") {
		t.Fatalf("retry_after_seconds query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "quota limit asildi") {
		t.Fatalf("quota limit denial reason query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestEvaluatePublicAPIQuotaSQLStoreEvaluateQuota_LimitedSuccess(t *testing.T) {
	db := &publicAPIQuotaQueryRowProviderMock{
		row: &publicAPIQuotaRowMock{
			values: []any{
				"req-002",
				"app-001",
				"key-001",
				"sandbox",
				"minute",
				60,
				60,
				1,
				61,
				0,
				"limited",
				false,
				60,
				"quota limit asildi",
			},
		},
	}

	store := NewEvaluatePublicAPIQuotaSQLStore(db)

	result, err := store.EvaluateQuota(context.Background(), EvaluatePublicAPIQuotaCommand{
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

	if result.Allowed {
		t.Fatalf("beklenen allowed false")
	}

	if result.RateLimitStatus != "limited" {
		t.Fatalf("beklenen rate_limit_status limited, alinan: %s", result.RateLimitStatus)
	}

	if result.RetryAfterSeconds != 60 {
		t.Fatalf("beklenen retry_after_seconds 60, alinan: %d", result.RetryAfterSeconds)
	}

	if result.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestEvaluatePublicAPIQuotaSQLStoreEvaluateQuota_NoDB(t *testing.T) {
	store := NewEvaluatePublicAPIQuotaSQLStore(nil)

	_, err := store.EvaluateQuota(context.Background(), EvaluatePublicAPIQuotaCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestEvaluatePublicAPIQuotaSQLStoreEvaluateQuota_ScanError(t *testing.T) {
	db := &publicAPIQuotaQueryRowProviderMock{
		row: &publicAPIQuotaRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewEvaluatePublicAPIQuotaSQLStore(db)

	_, err := store.EvaluateQuota(context.Background(), EvaluatePublicAPIQuotaCommand{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Environment: "production",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
