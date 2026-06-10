package realtime

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type websocketConnectionRowMock struct {
	values []any
	err    error
}

func (r *websocketConnectionRowMock) Scan(dest ...any) error {
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

type websocketConnectionQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *websocketConnectionQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestOpenWebSocketConnectionSQLStoreOpenConnection_Success(t *testing.T) {
	db := &websocketConnectionQueryRowProviderMock{
		row: &websocketConnectionRowMock{
			values: []any{
				"conn-001",
				"tenant.notifications",
				"client-001",
				"user-001",
				"websocket",
				"local-node",
				"connected",
				true,
				"",
			},
		},
	}

	store := NewOpenWebSocketConnectionSQLStore(db)

	result, err := store.OpenConnection(context.Background(), OpenWebSocketConnectionCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ConnectionID != "conn-001" {
		t.Fatalf("beklenen connection_id conn-001, alinan: %s", result.ConnectionID)
	}

	if result.ChannelName != "tenant.notifications" {
		t.Fatalf("beklenen channel_name tenant.notifications, alinan: %s", result.ChannelName)
	}

	if result.ClientID != "client-001" {
		t.Fatalf("beklenen client_id client-001, alinan: %s", result.ClientID)
	}

	if result.UserRef != "user-001" {
		t.Fatalf("beklenen user_ref user-001, alinan: %s", result.UserRef)
	}

	if result.Protocol != "websocket" {
		t.Fatalf("beklenen protocol websocket, alinan: %s", result.Protocol)
	}

	if result.ServerNode != "local-node" {
		t.Fatalf("beklenen server_node local-node, alinan: %s", result.ServerNode)
	}

	if result.Status != "connected" {
		t.Fatalf("beklenen status connected, alinan: %s", result.Status)
	}

	if !result.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if result.RejectionReason != "" {
		t.Fatalf("connected durumda rejection_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.realtime_connections") {
		t.Fatalf("realtime_connections query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "ON CONFLICT (connection_id)") {
		t.Fatalf("connection_id conflict handling query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "last_seen_at") {
		t.Fatalf("last_seen_at query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "'connected'") {
		t.Fatalf("connected status query icinde olmaliydi")
	}

	if len(db.lastArgs) != 10 {
		t.Fatalf("beklenen 10 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestOpenWebSocketConnectionSQLStoreOpenConnection_NoDB(t *testing.T) {
	store := NewOpenWebSocketConnectionSQLStore(nil)

	_, err := store.OpenConnection(context.Background(), OpenWebSocketConnectionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestOpenWebSocketConnectionSQLStoreOpenConnection_ScanError(t *testing.T) {
	db := &websocketConnectionQueryRowProviderMock{
		row: &websocketConnectionRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewOpenWebSocketConnectionSQLStore(db)

	_, err := store.OpenConnection(context.Background(), OpenWebSocketConnectionCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Protocol:     "websocket",
		RemoteAddr:   "127.0.0.1:9010",
		Origin:       "https://panel.pix2pi.com.tr",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
