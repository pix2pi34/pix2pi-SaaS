package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type dispatchPolicyStoreMock struct {
	lastCmd ResolveDispatchCommand
	result  ResolveDispatchResult
	err     error
	called  bool
}

func (m *dispatchPolicyStoreMock) ResolveDispatchPolicy(_ context.Context, cmd ResolveDispatchCommand) (ResolveDispatchResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestResolveDispatchRequestValidate_Success(t *testing.T) {
	req := ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "notifications-email",
		JobID:          "job-1",
		Priority:       "high",
		RequestedPool:  "shared-default",
		AvailablePools: []string{"shared-default", "priority-burst"},
		FallbackPool:   "fallback-shared",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestResolveDispatchRequestValidate_InvalidPriority(t *testing.T) {
	req := ResolveDispatchRequest{
		QueueKey:       "notifications-email",
		JobID:          "job-1",
		Priority:       "urgent",
		AvailablePools: []string{"shared-default"},
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestResolveDispatchRequestValidate_InvalidRequestedPool(t *testing.T) {
	req := ResolveDispatchRequest{
		QueueKey:       "notifications-email",
		JobID:          "job-1",
		Priority:       "normal",
		RequestedPool:  "shared default",
		AvailablePools: []string{"shared-default"},
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestResolveDispatchRequestValidate_NoDispatchTarget(t *testing.T) {
	req := ResolveDispatchRequest{
		QueueKey:  "notifications-email",
		JobID:     "job-1",
		Priority:  "normal",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestResolveDispatchUsecaseResolve_PreferredPoolSuccess(t *testing.T) {
	store := &dispatchPolicyStoreMock{
		result: ResolveDispatchResult{
			EffectiveQueueKey: "notifications-email",
			PreferredPool:     "tenant-a-pool",
			DispatchMode:      "tenant_pinned",
			TenantAware:       true,
		},
	}

	usecase := NewResolveDispatchUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 15, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Resolve(context.Background(), ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "notifications-email",
		JobID:          "job-1",
		Priority:       "high",
		AvailablePools: []string{"tenant-a-pool", "shared-default"},
		FallbackPool:   "fallback-shared",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.TenantID != "tenant-a" {
		t.Fatalf("beklenen tenant_id tenant-a, alinan: %s", store.lastCmd.TenantID)
	}

	if resp.SelectedPool != "tenant-a-pool" {
		t.Fatalf("beklenen selected_pool tenant-a-pool, alinan: %s", resp.SelectedPool)
	}

	if resp.DispatchMode != "tenant_pinned" {
		t.Fatalf("beklenen dispatch_mode tenant_pinned, alinan: %s", resp.DispatchMode)
	}

	if !resp.DispatchedAt.Equal(time.Date(2026, 4, 25, 15, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen dispatched_at sabit zaman")
	}
}

func TestResolveDispatchUsecaseResolve_PriorityLaneSuccess(t *testing.T) {
	store := &dispatchPolicyStoreMock{
		result: ResolveDispatchResult{},
	}

	usecase := NewResolveDispatchUsecase(store)

	resp, err := usecase.Resolve(context.Background(), ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "notifications-email",
		JobID:          "job-2",
		Priority:       "critical",
		AvailablePools: []string{"shared-default", "priority-burst"},
		FallbackPool:   "fallback-shared",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.SelectedPool != "priority-burst" {
		t.Fatalf("beklenen selected_pool priority-burst, alinan: %s", resp.SelectedPool)
	}

	if resp.DispatchMode != "priority_lane" {
		t.Fatalf("beklenen dispatch_mode priority_lane, alinan: %s", resp.DispatchMode)
	}
}

func TestResolveDispatchUsecaseResolve_ValidationError(t *testing.T) {
	store := &dispatchPolicyStoreMock{}
	usecase := NewResolveDispatchUsecase(store)

	_, err := usecase.Resolve(context.Background(), ResolveDispatchRequest{
		QueueKey:  "notifications-email",
		JobID:     "",
		Priority:  "normal",
		FallbackPool: "fallback-shared",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestResolveDispatchUsecaseResolve_StoreError(t *testing.T) {
	store := &dispatchPolicyStoreMock{
		err: errors.New("dispatch policy load failed"),
	}
	usecase := NewResolveDispatchUsecase(store)

	_, err := usecase.Resolve(context.Background(), ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "notifications-email",
		JobID:          "job-1",
		Priority:       "normal",
		AvailablePools: []string{"shared-default"},
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestResolveDispatchResponseValidate_InvalidDispatchedAt(t *testing.T) {
	resp := ResolveDispatchResponse{
		DispatchKey:  "tenant-a|notifications-email|shared-default",
		JobID:        "job-1",
		QueueKey:     "notifications-email",
		Priority:     "normal",
		SelectedPool: "shared-default",
		DispatchMode: "shared_pool",
		TenantAware:  true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
