package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type rowsMock struct {
	rows [][]any
	idx  int
	err  error
}

func (r *rowsMock) Next() bool {
	return r.idx < len(r.rows)
}

func (r *rowsMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	row := r.rows[r.idx]
	r.idx++

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = row[i].(string)
		case *int:
			*d = row[i].(int)
		case *time.Time:
			*d = row[i].(time.Time)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

func (r *rowsMock) Err() error {
	return nil
}

func (r *rowsMock) Close() error {
	return nil
}

type queryRowsProviderMock struct {
	lastQuery string
	lastArgs  []any
	rows      RowsScanner
	err       error
}

func (m *queryRowsProviderMock) QueryRowContext(_ context.Context, _ string, _ ...any) RowScanner {
	return &sqlRowMock{err: errors.New("query row not used in this test")}
}

func (m *queryRowsProviderMock) QueryContext(_ context.Context, query string, args ...any) (RowsScanner, error) {
	m.lastQuery = query
	m.lastArgs = args
	return m.rows, m.err
}

func TestSQLStoreListVisibleServiceInstances_Success(t *testing.T) {
	db := &queryRowsProviderMock{
		rows: &rowsMock{
			rows: [][]any{
				{
					"svc-1",
					"ins-1",
					"tenant-a",
					"identity-api",
					"Identity API",
					"api",
					"tenant",
					"identity-api-01",
					"healthy",
					"10.10.10.11",
					9001,
					"1.0.0",
					time.Date(2026, 4, 24, 16, 30, 0, 0, time.UTC),
				},
				{
					"svc-2",
					"ins-2",
					"",
					"gateway-public",
					"Gateway Public",
					"gateway",
					"global",
					"gateway-public-01",
					"healthy",
					"10.10.10.12",
					9010,
					"1.0.0",
					time.Date(2026, 4, 24, 16, 31, 0, 0, time.UTC),
				},
			},
		},
	}

	store := NewSQLStore(db)

	items, err := store.ListVisibleServiceInstances(context.Background(), ListVisibleServicesCommand{
		TenantID:         "tenant-a",
		IncludeGlobal:    true,
		ServiceKeyPrefix: "id",
		InstanceStatus:   "healthy",
		Limit:            50,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if len(items) != 2 {
		t.Fatalf("beklenen 2 item, alinan: %d", len(items))
	}

	if items[0].ServiceKey != "identity-api" {
		t.Fatalf("beklenen ilk service_key identity-api, alinan: %s", items[0].ServiceKey)
	}

	if !strings.Contains(db.lastQuery, "runtime.service_registry_services") {
		t.Fatalf("service_registry_services query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.service_registry_instances") {
		t.Fatalf("service_registry_instances query icinde olmaliydi")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestSQLStoreListVisibleServiceInstances_NoRowsProvider(t *testing.T) {
	store := NewSQLStore(&queryRowProviderMock{})

	_, err := store.ListVisibleServiceInstances(context.Background(), ListVisibleServicesCommand{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		InstanceStatus: "healthy",
		Limit:          10,
	})
	if err == nil {
		t.Fatalf("beklenen rows provider hatasi")
	}
}

func TestSQLStoreListVisibleServiceInstances_QueryError(t *testing.T) {
	db := &queryRowsProviderMock{
		err: errors.New("query failed"),
	}

	store := NewSQLStore(db)

	_, err := store.ListVisibleServiceInstances(context.Background(), ListVisibleServicesCommand{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		InstanceStatus: "healthy",
		Limit:          10,
	})
	if err == nil {
		t.Fatalf("beklenen query hatasi")
	}
}

func TestSQLStoreListVisibleServiceInstances_ScanError(t *testing.T) {
	db := &queryRowsProviderMock{
		rows: &rowsMock{
			err: errors.New("scan failed"),
			rows: [][]any{
				{
					"svc-1",
					"ins-1",
					"tenant-a",
					"identity-api",
					"Identity API",
					"api",
					"tenant",
					"identity-api-01",
					"healthy",
					"10.10.10.11",
					9001,
					"1.0.0",
					time.Date(2026, 4, 24, 16, 30, 0, 0, time.UTC),
				},
			},
		},
	}

	store := NewSQLStore(db)

	_, err := store.ListVisibleServiceInstances(context.Background(), ListVisibleServicesCommand{
		TenantID:       "tenant-a",
		IncludeGlobal:  true,
		InstanceStatus: "healthy",
		Limit:          10,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
