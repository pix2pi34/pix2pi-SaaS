package realtime

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type sseConnectionRowMock struct {
	values []any
	err    error
}

func (r *sseConnectionRowMock) Scan(dest ...any) error {
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

type sseConnectionQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *sseConnectionQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestOpenSSEConnectionSQLStoreOpenStream_Success(t *testing.T) {
	db := &sseConnectionQueryRowProviderMock{
		row: &sseConnectionRowMock{
			values: []any{
				"sse-conn-001",
				"tenant.events",
				"client-001",
				"user-001",
				"sse",
				"event-000",
				"local-node",
				"streaming",
				true,
				"",
			},
		},
	}

	store := NewOpenSSEConnectionSQLStore(db)

	result, err := store.OpenStream(context.Background(), OpenSSEConnectionCommand{
		TenantID:     "tenant-a",
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		LastEventID:  "event-000",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ConnectionID != "sse-conn-001" {
		t.Fatalf("beklenen connection_id sse-conn-001, alinan: %s", result.ConnectionID)
	}

	if result.ChannelName != "tenant.events" {
		t.Fatalf("beklenen channel_name tenant.events, alinan: %s", result.ChannelName)
	}

	if result.ClientID != "client-001" {
		t.Fatalf("beklenen client_id client-001, alinan: %s", result.ClientID)
	}

	if result.UserRef != "user-001" {
		t.Fatalf("beklenen user_ref user-001, alinan: %s", result.UserRef)
	}

	if result.Protocol != "sse" {
		t.Fatalf("beklenen protocol sse, alinan: %s", result.Protocol)
	}

	if result.LastEventID != "event-000" {
		t.Fatalf("beklenen last_event_id event-000, alinan: %s", result.LastEventID)
	}

	if result.ServerNode != "local-node" {
		t.Fatalf("beklenen server_node local-node, alinan: %s", result.ServerNode)
	}

	if result.Status != "streaming" {
		t.Fatalf("beklenen status streaming, alinan: %s", result.Status)
	}

	if !result.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if result.RejectionReason != "" {
		t.Fatalf("streaming durumda rejection_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.realtime_connections") {
		t.Fatalf("realtime_connections query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "last_event_id") {
		t.Fatalf("last_event_id query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "ON CONFLICT (connection_id)") {
		t.Fatalf("connection_id conflict handling query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "'streaming'") {
		t.Fatalf("streaming status query icinde olmaliydi")
	}

	if len(db.lastArgs) != 11 {
		t.Fatalf("beklenen 11 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestOpenSSEConnectionSQLStoreOpenStream_WithoutLastEventIDSuccess(t *testing.T) {
	db := &sseConnectionQueryRowProviderMock{
		row: &sseConnectionRowMock{
			values: []any{
				"sse-conn-002",
				"tenant.events",
				"client-002",
				"user-002",
				"sse",
				"",
				"local-node",
				"streaming",
				true,
				"",
			},
		},
	}

	store := NewOpenSSEConnectionSQLStore(db)

	result, err := store.OpenStream(context.Background(), OpenSSEConnectionCommand{
		TenantID:     "tenant-a",
		ConnectionID: "sse-conn-002",
		ChannelName:  "tenant.events",
		ClientID:     "client-002",
		UserRef:      "user-002",
		Protocol:     "sse",
		RemoteAddr:   "127.0.0.1:9010",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.LastEventID != "" {
		t.Fatalf("beklenen last_event_id bos, alinan: %s", result.LastEventID)
	}
}

func TestOpenSSEConnectionSQLStoreOpenStream_NoDB(t *testing.T) {
	store := NewOpenSSEConnectionSQLStore(nil)

	_, err := store.OpenStream(context.Background(), OpenSSEConnectionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestOpenSSEConnectionSQLStoreOpenStream_ScanError(t *testing.T) {
	db := &sseConnectionQueryRowProviderMock{
		row: &sseConnectionRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewOpenSSEConnectionSQLStore(db)

	_, err := store.OpenStream(context.Background(), OpenSSEConnectionCommand{
		TenantID:     "tenant-a",
		ConnectionID: "sse-conn-001",
		ChannelName:  "tenant.events",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "sse",
		LastEventID:  "event-000",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
