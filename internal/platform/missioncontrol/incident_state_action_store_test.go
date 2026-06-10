package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type incidentStateRowMock struct {
	values []any
	err    error
}

func (r *incidentStateRowMock) Scan(dest ...any) error {
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

type incidentStateQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *incidentStateQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestIncidentStateSQLStoreRequestIncidentStateAction_AcknowledgeSuccess(t *testing.T) {
	db := &incidentStateQueryRowProviderMock{
		row: &incidentStateRowMock{
			values: []any{"act-incident-1", "requested", "acknowledged"},
		},
	}

	store := NewIncidentStateSQLStore(db)

	result, err := store.RequestIncidentStateAction(context.Background(), RequestIncidentStateActionCommand{
		TenantID:     "tenant-a",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "acknowledge",
		RequestedBy:  "operator-a",
		ResponseNote: "ilk inceleme alindi",
		DryRun:       false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ActionID != "act-incident-1" {
		t.Fatalf("beklenen action_id act-incident-1, alinan: %s", result.ActionID)
	}

	if result.IncidentStatus != "acknowledged" {
		t.Fatalf("beklenen incident_status acknowledged, alinan: %s", result.IncidentStatus)
	}

	if !strings.Contains(db.lastQuery, "runtime.mission_control_incidents") {
		t.Fatalf("mission_control_incidents query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.mission_control_actions") {
		t.Fatalf("mission_control_actions query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "updated_incident") {
		t.Fatalf("updated_incident cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestIncidentStateSQLStoreRequestIncidentStateAction_ResolveDryRunSuccess(t *testing.T) {
	db := &incidentStateQueryRowProviderMock{
		row: &incidentStateRowMock{
			values: []any{"act-incident-2", "requested", "resolved"},
		},
	}

	store := NewIncidentStateSQLStore(db)

	result, err := store.RequestIncidentStateAction(context.Background(), RequestIncidentStateActionCommand{
		TenantID:     "tenant-a",
		IncidentID:   "inc-2",
		ServiceID:    "svc-2",
		ActionType:   "resolve",
		RequestedBy:  "operator-b",
		ResponseNote: "problem giderildi",
		DryRun:       true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.IncidentStatus != "resolved" {
		t.Fatalf("beklenen incident_status resolved, alinan: %s", result.IncidentStatus)
	}
}

func TestIncidentStateSQLStoreRequestIncidentStateAction_NoDB(t *testing.T) {
	store := NewIncidentStateSQLStore(nil)

	_, err := store.RequestIncidentStateAction(context.Background(), RequestIncidentStateActionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestIncidentStateSQLStoreRequestIncidentStateAction_ScanError(t *testing.T) {
	db := &incidentStateQueryRowProviderMock{
		row: &incidentStateRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewIncidentStateSQLStore(db)

	_, err := store.RequestIncidentStateAction(context.Background(), RequestIncidentStateActionCommand{
		TenantID:     "tenant-a",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "acknowledge",
		RequestedBy:  "operator-a",
		ResponseNote: "ilk inceleme alindi",
		DryRun:       false,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
