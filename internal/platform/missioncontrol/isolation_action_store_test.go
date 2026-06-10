package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type isolationRowMock struct {
	values []any
	err    error
}

func (r *isolationRowMock) Scan(dest ...any) error {
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

type isolationQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *isolationQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestIsolationSQLStoreRequestIsolationAction_Success(t *testing.T) {
	db := &isolationQueryRowProviderMock{
		row: &isolationRowMock{
			values: []any{"act-iso-1", "requested"},
		},
	}

	store := NewIsolationSQLStore(db)

	result, err := store.RequestIsolationAction(context.Background(), RequestIsolationActionCommand{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "quarantine",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
		DryRun:          true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ActionID != "act-iso-1" {
		t.Fatalf("beklenen action_id act-iso-1, alinan: %s", result.ActionID)
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

	if !strings.Contains(db.lastQuery, "action_type") {
		t.Fatalf("action_type query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestIsolationSQLStoreRequestIsolationAction_NoDB(t *testing.T) {
	store := NewIsolationSQLStore(nil)

	_, err := store.RequestIsolationAction(context.Background(), RequestIsolationActionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestIsolationSQLStoreRequestIsolationAction_ScanError(t *testing.T) {
	db := &isolationQueryRowProviderMock{
		row: &isolationRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewIsolationSQLStore(db)

	_, err := store.RequestIsolationAction(context.Background(), RequestIsolationActionCommand{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "isolate",
		RequestedBy:     "operator-a",
		RequestedReason: "riskli trafik goruldu",
		DryRun:          false,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
