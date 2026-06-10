package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type maintenanceRowMock struct {
	values []any
	err    error
}

func (r *maintenanceRowMock) Scan(dest ...any) error {
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

type maintenanceQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *maintenanceQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestMaintenanceSQLStoreRequestMaintenanceAction_Success(t *testing.T) {
	db := &maintenanceQueryRowProviderMock{
		row: &maintenanceRowMock{
			values: []any{"act-maint-1", "requested"},
		},
	}

	store := NewMaintenanceSQLStore(db)

	result, err := store.RequestMaintenanceAction(context.Background(), RequestMaintenanceActionCommand{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "maintenance_on",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
		DryRun:          true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ActionID != "act-maint-1" {
		t.Fatalf("beklenen action_id act-maint-1, alinan: %s", result.ActionID)
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

func TestMaintenanceSQLStoreRequestMaintenanceAction_NoDB(t *testing.T) {
	store := NewMaintenanceSQLStore(nil)

	_, err := store.RequestMaintenanceAction(context.Background(), RequestMaintenanceActionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestMaintenanceSQLStoreRequestMaintenanceAction_ScanError(t *testing.T) {
	db := &maintenanceQueryRowProviderMock{
		row: &maintenanceRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewMaintenanceSQLStore(db)

	_, err := store.RequestMaintenanceAction(context.Background(), RequestMaintenanceActionCommand{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "maintenance_off",
		RequestedBy:     "operator-a",
		RequestedReason: "planned update",
		DryRun:          false,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
