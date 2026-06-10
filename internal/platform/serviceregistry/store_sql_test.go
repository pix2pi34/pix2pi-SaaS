package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type sqlRowMock struct {
	values []any
	err    error
}

func (r *sqlRowMock) Scan(dest ...any) error {
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

type queryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *queryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestSQLStoreUpsertServiceInstance_Success(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			values: []any{"svc-1", "ins-1", "identity-api", "identity-api-01"},
		},
	}

	store := NewSQLStore(db)

	result, err := store.UpsertServiceInstance(context.Background(), UpsertServiceInstanceCommand{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		OwnerTeam:                "identity",
		ServiceMetadata:          map[string]any{"region": "eu"},
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Version:                  "1.0.0",
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
		InstanceMetadata:         map[string]any{"zone": "az-1"},
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ServiceID != "svc-1" || result.InstanceID != "ins-1" {
		t.Fatalf("beklenmeyen sonuc: %+v", result)
	}

	if !strings.Contains(db.lastQuery, "runtime.service_registry_services") {
		t.Fatalf("service upsert query bekleniyordu")
	}

	if !strings.Contains(db.lastQuery, "runtime.service_registry_instances") {
		t.Fatalf("instance upsert query bekleniyordu")
	}

	if len(db.lastArgs) != 19 {
		t.Fatalf("beklenen 19 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestSQLStoreUpsertServiceInstance_NoDB(t *testing.T) {
	store := NewSQLStore(nil)

	_, err := store.UpsertServiceInstance(context.Background(), UpsertServiceInstanceCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestSQLStoreUpsertServiceInstance_ScanError(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewSQLStore(db)

	_, err := store.UpsertServiceInstance(context.Background(), UpsertServiceInstanceCommand{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}

func TestSQLStoreRecordHeartbeat_Success(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			values: []any{30, false},
		},
	}

	store := NewSQLStore(db)

	result, err := store.RecordHeartbeat(context.Background(), RecordHeartbeatCommand{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           23,
		HeartbeatIntervalSeconds: 30,
		Metadata:                 map[string]any{"cpu": "low"},
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.NextHeartbeatInSeconds != 30 {
		t.Fatalf("beklenen next heartbeat 30, alinan: %d", result.NextHeartbeatInSeconds)
	}

	if result.HealthPullRequested {
		t.Fatalf("healthy durumda health pull false olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.service_registry_heartbeats") {
		t.Fatalf("heartbeat insert query bekleniyordu")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestSQLStoreRecordHeartbeat_ScanError(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			err: errors.New("heartbeat scan failed"),
		},
	}

	store := NewSQLStore(db)

	_, err := store.RecordHeartbeat(context.Background(), RecordHeartbeatCommand{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           25,
		HeartbeatIntervalSeconds: 30,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
