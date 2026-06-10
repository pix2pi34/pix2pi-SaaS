package realtime

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"testing"
	"time"
)

type realtimePresenceRowMock struct {
	values []any
	err    error
}

func (r *realtimePresenceRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		case *time.Time:
			*d = r.values[i].(time.Time)
		case *sql.NullTime:
			switch v := r.values[i].(type) {
			case sql.NullTime:
				*d = v
			case time.Time:
				*d = sql.NullTime{Time: v, Valid: true}
			case nil:
				*d = sql.NullTime{Valid: false}
			default:
				return errors.New("sql.NullTime tipi desteklenmiyor")
			}
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type realtimePresenceQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *realtimePresenceQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestApplyRealtimePresenceSQLStoreApplyPresence_HeartbeatSuccess(t *testing.T) {
	lastSeenAt := time.Date(2026, 4, 26, 12, 30, 0, 0, time.UTC)

	db := &realtimePresenceQueryRowProviderMock{
		row: &realtimePresenceRowMock{
			values: []any{
				"tenant-a",
				"conn-001",
				"tenant.notifications",
				"client-001",
				"user-001",
				"heartbeat",
				"online",
				false,
				"node-01",
				lastSeenAt,
				nil,
				true,
			},
		},
	}

	store := NewApplyRealtimePresenceSQLStore(db)

	result, err := store.ApplyPresence(context.Background(), ApplyRealtimePresenceCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.TenantID != "tenant-a" {
		t.Fatalf("beklenen tenant_id tenant-a, alinan: %s", result.TenantID)
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

	if result.ActionType != "heartbeat" {
		t.Fatalf("beklenen action_type heartbeat, alinan: %s", result.ActionType)
	}

	if result.PresenceStatus != "online" {
		t.Fatalf("beklenen presence_status online, alinan: %s", result.PresenceStatus)
	}

	if result.ConnectionClosed {
		t.Fatalf("heartbeat durumunda connection_closed false olmaliydi")
	}

	if result.ClosedAt != nil {
		t.Fatalf("heartbeat durumunda closed_at nil olmaliydi")
	}

	if !result.LastSeenAt.Equal(lastSeenAt) {
		t.Fatalf("beklenen last_seen_at korunmaliydi")
	}

	if !result.Applied {
		t.Fatalf("beklenen applied true")
	}

	if !strings.Contains(db.lastQuery, "runtime.realtime_connections") {
		t.Fatalf("realtime_connections query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "presence_status = CASE") {
		t.Fatalf("presence_status case query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "connection_closed = CASE") {
		t.Fatalf("connection_closed case query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "last_seen_at = now()") {
		t.Fatalf("last_seen_at update query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestApplyRealtimePresenceSQLStoreApplyPresence_DisconnectSuccess(t *testing.T) {
	lastSeenAt := time.Date(2026, 4, 26, 12, 40, 0, 0, time.UTC)
	closedAt := time.Date(2026, 4, 26, 12, 40, 0, 0, time.UTC)

	db := &realtimePresenceQueryRowProviderMock{
		row: &realtimePresenceRowMock{
			values: []any{
				"tenant-a",
				"conn-002",
				"tenant.notifications",
				"client-002",
				"user-002",
				"disconnect",
				"offline",
				true,
				"node-01",
				lastSeenAt,
				closedAt,
				true,
			},
		},
	}

	store := NewApplyRealtimePresenceSQLStore(db)

	result, err := store.ApplyPresence(context.Background(), ApplyRealtimePresenceCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-002",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-002",
		UserRef:      "user-002",
		ActionType:   "disconnect",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PresenceStatus != "offline" {
		t.Fatalf("beklenen presence_status offline, alinan: %s", result.PresenceStatus)
	}

	if !result.ConnectionClosed {
		t.Fatalf("disconnect durumunda connection_closed true olmaliydi")
	}

	if result.ClosedAt == nil || !result.ClosedAt.Equal(closedAt) {
		t.Fatalf("beklenen closed_at dolu olmaliydi")
	}
}

func TestApplyRealtimePresenceSQLStoreApplyPresence_ExpireSuccess(t *testing.T) {
	lastSeenAt := time.Date(2026, 4, 26, 12, 50, 0, 0, time.UTC)
	closedAt := time.Date(2026, 4, 26, 12, 50, 0, 0, time.UTC)

	db := &realtimePresenceQueryRowProviderMock{
		row: &realtimePresenceRowMock{
			values: []any{
				"tenant-a",
				"conn-003",
				"tenant.notifications",
				"client-003",
				"user-003",
				"expire",
				"expired",
				true,
				"node-01",
				lastSeenAt,
				closedAt,
				true,
			},
		},
	}

	store := NewApplyRealtimePresenceSQLStore(db)

	result, err := store.ApplyPresence(context.Background(), ApplyRealtimePresenceCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-003",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-003",
		UserRef:      "user-003",
		ActionType:   "expire",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.PresenceStatus != "expired" {
		t.Fatalf("beklenen presence_status expired, alinan: %s", result.PresenceStatus)
	}

	if !result.ConnectionClosed {
		t.Fatalf("expire durumunda connection_closed true olmaliydi")
	}
}

func TestApplyRealtimePresenceSQLStoreApplyPresence_NoDB(t *testing.T) {
	store := NewApplyRealtimePresenceSQLStore(nil)

	_, err := store.ApplyPresence(context.Background(), ApplyRealtimePresenceCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestApplyRealtimePresenceSQLStoreApplyPresence_ScanError(t *testing.T) {
	db := &realtimePresenceQueryRowProviderMock{
		row: &realtimePresenceRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewApplyRealtimePresenceSQLStore(db)

	_, err := store.ApplyPresence(context.Background(), ApplyRealtimePresenceCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		ActionType:   "heartbeat",
		ServerNode:   "node-01",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
