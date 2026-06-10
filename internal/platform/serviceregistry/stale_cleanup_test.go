package serviceregistry

import (
	"context"
	"errors"
	"testing"
	"time"
)

type staleCleanupStoreMock struct {
	lastCmd CleanupStaleInstancesCommand
	result  CleanupStaleInstancesResult
	err     error
	called  bool
}

func (m *staleCleanupStoreMock) CleanupStaleInstances(_ context.Context, cmd CleanupStaleInstancesCommand) (CleanupStaleInstancesResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestCleanupStaleInstancesRequestValidate_Success(t *testing.T) {
	req := CleanupStaleInstancesRequest{
		TenantID:           "tenant-a",
		GracePeriodSeconds: 300,
		Limit:              100,
		TargetStatus:       "stopped",
		DryRun:             false,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCleanupStaleInstancesRequestValidate_InvalidGracePeriod(t *testing.T) {
	req := CleanupStaleInstancesRequest{
		GracePeriodSeconds: 10,
		Limit:              100,
		TargetStatus:       "stopped",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCleanupStaleInstancesRequestValidate_InvalidLimit(t *testing.T) {
	req := CleanupStaleInstancesRequest{
		GracePeriodSeconds: 300,
		Limit:              0,
		TargetStatus:       "stopped",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCleanupStaleInstancesRequestValidate_InvalidTargetStatus(t *testing.T) {
	req := CleanupStaleInstancesRequest{
		GracePeriodSeconds: 300,
		Limit:              100,
		TargetStatus:       "ghost",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestStaleInstanceCleanupUsecaseRun_Success(t *testing.T) {
	store := &staleCleanupStoreMock{
		result: CleanupStaleInstancesResult{
			CleanedCount: 7,
		},
	}

	usecase := NewStaleInstanceCleanupUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 16, 0, 0, 0, time.UTC)
	}

	req := CleanupStaleInstancesRequest{
		TenantID:           "tenant-a",
		GracePeriodSeconds: 300,
		Limit:              100,
		TargetStatus:       "stopped",
		DryRun:             false,
	}

	resp, err := usecase.Run(context.Background(), req)
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if resp.CleanedCount != 7 {
		t.Fatalf("beklenen cleaned_count 7, alinan: %d", resp.CleanedCount)
	}

	expectedThreshold := time.Date(2026, 4, 24, 15, 55, 0, 0, time.UTC)
	if !resp.ThresholdTime.Equal(expectedThreshold) {
		t.Fatalf("beklenen threshold_time %v, alinan: %v", expectedThreshold, resp.ThresholdTime)
	}

	if store.lastCmd.TargetStatus != "stopped" {
		t.Fatalf("beklenen target_status stopped, alinan: %s", store.lastCmd.TargetStatus)
	}
}

func TestStaleInstanceCleanupUsecaseRun_ValidationError(t *testing.T) {
	store := &staleCleanupStoreMock{}
	usecase := NewStaleInstanceCleanupUsecase(store)

	req := CleanupStaleInstancesRequest{
		GracePeriodSeconds: 10,
		Limit:              100,
		TargetStatus:       "stopped",
	}

	_, err := usecase.Run(context.Background(), req)
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestStaleInstanceCleanupUsecaseRun_StoreError(t *testing.T) {
	store := &staleCleanupStoreMock{
		err: errors.New("cleanup failed"),
	}

	usecase := NewStaleInstanceCleanupUsecase(store)

	req := CleanupStaleInstancesRequest{
		GracePeriodSeconds: 300,
		Limit:              100,
		TargetStatus:       "stopped",
	}

	_, err := usecase.Run(context.Background(), req)
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestCleanupStaleInstancesResponseValidate_InvalidExecutedAt(t *testing.T) {
	resp := CleanupStaleInstancesResponse{
		CleanedCount:  1,
		ThresholdTime: time.Date(2026, 4, 24, 16, 0, 0, 0, time.UTC),
		TargetStatus:  "stopped",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
