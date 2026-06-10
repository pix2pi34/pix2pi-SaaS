package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type restartRowMock struct {
	values []any
	err    error
}

func (r *restartRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type restartQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *restartQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestRestartSQLStoreRequestRestartAction_Success(t *testing.T) {
	db := &restartQueryRowProviderMock{
		row: &restartRowMock{
			values: []any{"act-1", "requested"},
		},
	}

	store := NewRestartSQLStore(db)

	result, err := store.RequestRestartAction(context.Background(), RequestRestartActionCommand{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
		DryRun:          false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ActionID != "act-1" {
		t.Fatalf("beklenen action_id act-1, alinan: %s", result.ActionID)
	}

	if result.ActionStatus != "requested" {
		t.Fatalf("beklenen action_status requested, alinan: %s", result.ActionStatus)
	}

	if !strings.Contains(db.lastQuery, "runtime.mission_control_incidents") {
		t.Fatalf("mission_control_incidents query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.mission_control_actions") {
		t.Fatalf("mission_control_actions query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestRestartSQLStoreRequestRestartAction_NoDB(t *testing.T) {
	store := NewRestartSQLStore(nil)

	_, err := store.RequestRestartAction(context.Background(), RequestRestartActionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestRestartSQLStoreRequestRestartAction_ScanError(t *testing.T) {
	db := &restartQueryRowProviderMock{
		row: &restartRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewRestartSQLStore(db)

	_, err := store.RequestRestartAction(context.Background(), RequestRestartActionCommand{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
		DryRun:          true,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
