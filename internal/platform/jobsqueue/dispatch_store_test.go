package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type dispatchRowMock struct {
	values []any
	err    error
}

func (r *dispatchRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type dispatchQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *dispatchQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestResolveDispatchSQLStoreResolveDispatchPolicy_TenantPinnedSuccess(t *testing.T) {
	db := &dispatchQueryRowProviderMock{
		row: &dispatchRowMock{
			values: []any{
				"notifications-email",
				"tenant_tenant_a_pool",
				"tenant_pinned",
				true,
			},
		},
	}

	store := NewResolveDispatchSQLStore(db)

	result, err := store.ResolveDispatchPolicy(context.Background(), ResolveDispatchCommand{
		TenantID: "tenant-a",
		QueueKey: "notifications-email",
		JobID:    "job-1",
		Priority: "high",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.EffectiveQueueKey != "notifications-email" {
		t.Fatalf("beklenen effective_queue_key notifications-email, alinan: %s", result.EffectiveQueueKey)
	}

	if result.DispatchMode != "tenant_pinned" {
		t.Fatalf("beklenen dispatch_mode tenant_pinned, alinan: %s", result.DispatchMode)
	}

	if !result.TenantAware {
		t.Fatalf("beklenen tenant_aware true")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.job_queues") {
		t.Fatalf("job_queues query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "preferred_pool") {
		t.Fatalf("preferred_pool select icinde olmaliydi")
	}

	if len(db.lastArgs) != 4 {
		t.Fatalf("beklenen 4 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestResolveDispatchSQLStoreResolveDispatchPolicy_ShardPriorityLaneSuccess(t *testing.T) {
	db := &dispatchQueryRowProviderMock{
		row: &dispatchRowMock{
			values: []any{
				"notifications-email",
				"priority-burst",
				"priority_lane",
				false,
			},
		},
	}

	store := NewResolveDispatchSQLStore(db)

	result, err := store.ResolveDispatchPolicy(context.Background(), ResolveDispatchCommand{
		TenantID: "",
		QueueKey: "notifications-email",
		JobID:    "job-2",
		Priority: "critical",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PreferredPool != "priority-burst" {
		t.Fatalf("beklenen preferred_pool priority-burst, alinan: %s", result.PreferredPool)
	}

	if result.DispatchMode != "priority_lane" {
		t.Fatalf("beklenen dispatch_mode priority_lane, alinan: %s", result.DispatchMode)
	}
}

func TestResolveDispatchSQLStoreResolveDispatchPolicy_NoDB(t *testing.T) {
	store := NewResolveDispatchSQLStore(nil)

	_, err := store.ResolveDispatchPolicy(context.Background(), ResolveDispatchCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestResolveDispatchSQLStoreResolveDispatchPolicy_ScanError(t *testing.T) {
	db := &dispatchQueryRowProviderMock{
		row: &dispatchRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewResolveDispatchSQLStore(db)

	_, err := store.ResolveDispatchPolicy(context.Background(), ResolveDispatchCommand{
		TenantID: "tenant-a",
		QueueKey: "notifications-email",
		JobID:    "job-1",
		Priority: "normal",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
