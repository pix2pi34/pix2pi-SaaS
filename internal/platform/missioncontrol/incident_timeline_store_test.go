package missioncontrol

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type timelineRowsMock struct {
	rows [][]any
	idx  int
	err  error
}

func (r *timelineRowsMock) Next() bool {
	return r.idx < len(r.rows)
}

func (r *timelineRowsMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	row := r.rows[r.idx]
	r.idx++

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = row[i].(string)
		case *time.Time:
			*d = row[i].(time.Time)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

func (r *timelineRowsMock) Err() error {
	return nil
}

func (r *timelineRowsMock) Close() error {
	return nil
}

type timelineQueryRowsProviderMock struct {
	lastQuery string
	lastArgs  []any
	rows      RowsScanner
	err       error
}

func (m *timelineQueryRowsProviderMock) QueryContext(_ context.Context, query string, args ...any) (RowsScanner, error) {
	m.lastQuery = query
	m.lastArgs = args
	return m.rows, m.err
}

func TestTimelineSQLStoreListIncidentTimeline_Success(t *testing.T) {
	db := &timelineQueryRowsProviderMock{
		rows: &timelineRowsMock{
			rows: [][]any{
				{
					"evt-2",
					"inc-1",
					"svc-1",
					"state_change",
					"",
					"",
					"acknowledged",
					"",
					"incident acknowledge edildi",
					time.Date(2026, 4, 25, 0, 20, 0, 0, time.UTC),
				},
				{
					"evt-1",
					"inc-1",
					"svc-1",
					"action",
					"restart",
					"requested",
					"",
					"operator-a",
					"restart istendi",
					time.Date(2026, 4, 25, 0, 10, 0, 0, time.UTC),
				},
			},
		},
	}

	store := NewTimelineSQLStore(db)

	items, err := store.ListIncidentTimeline(context.Background(), ListIncidentTimelineCommand{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: true,
		IncludeNotes:        false,
		Limit:               50,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if len(items) != 2 {
		t.Fatalf("beklenen 2 item, alinan: %d", len(items))
	}

	if items[0].EventID != "evt-2" {
		t.Fatalf("beklenen ilk event evt-2, alinan: %s", items[0].EventID)
	}

	if !strings.Contains(db.lastQuery, "runtime.mission_control_actions") {
		t.Fatalf("mission_control_actions query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.mission_control_incidents") {
		t.Fatalf("mission_control_incidents query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "combined") {
		t.Fatalf("combined cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestTimelineSQLStoreListIncidentTimeline_NoDB(t *testing.T) {
	store := NewTimelineSQLStore(nil)

	_, err := store.ListIncidentTimeline(context.Background(), ListIncidentTimelineCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestTimelineSQLStoreListIncidentTimeline_QueryError(t *testing.T) {
	db := &timelineQueryRowsProviderMock{
		err: errors.New("query failed"),
	}

	store := NewTimelineSQLStore(db)

	_, err := store.ListIncidentTimeline(context.Background(), ListIncidentTimelineCommand{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: true,
		IncludeNotes:        false,
		Limit:               10,
	})
	if err == nil {
		t.Fatalf("beklenen query hatasi")
	}
}

func TestTimelineSQLStoreListIncidentTimeline_ScanError(t *testing.T) {
	db := &timelineQueryRowsProviderMock{
		rows: &timelineRowsMock{
			err: errors.New("scan failed"),
			rows: [][]any{
				{
					"evt-1",
					"inc-1",
					"svc-1",
					"action",
					"restart",
					"requested",
					"",
					"operator-a",
					"restart istendi",
					time.Date(2026, 4, 25, 0, 10, 0, 0, time.UTC),
				},
			},
		},
	}

	store := NewTimelineSQLStore(db)

	_, err := store.ListIncidentTimeline(context.Background(), ListIncidentTimelineCommand{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: false,
		IncludeNotes:        false,
		Limit:               10,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
