package realtime

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type realtimeChannelAuthRowMock struct {
	values []any
	err    error
}

func (r *realtimeChannelAuthRowMock) Scan(dest ...any) error {
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

type realtimeChannelAuthQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *realtimeChannelAuthQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestAuthorizeRealtimeChannelSQLStoreAuthorizeChannel_Success(t *testing.T) {
	db := &realtimeChannelAuthQueryRowProviderMock{
		row: &realtimeChannelAuthRowMock{
			values: []any{
				"tenant-a",
				"conn-001",
				"tenant.notifications",
				"client-001",
				"user-001",
				"subscribe",
				"tenant",
				"granted",
				true,
				"",
			},
		},
	}

	store := NewAuthorizeRealtimeChannelSQLStore(db)

	result, err := store.AuthorizeChannel(context.Background(), AuthorizeRealtimeChannelCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
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

	if result.Operation != "subscribe" {
		t.Fatalf("beklenen operation subscribe, alinan: %s", result.Operation)
	}

	if result.ChannelScope != "tenant" {
		t.Fatalf("beklenen channel_scope tenant, alinan: %s", result.ChannelScope)
	}

	if result.AuthStatus != "granted" {
		t.Fatalf("beklenen auth_status granted, alinan: %s", result.AuthStatus)
	}

	if !result.AccessGranted {
		t.Fatalf("beklenen access_granted true")
	}

	if result.DenialReason != "" {
		t.Fatalf("granted durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.realtime_channel_permissions") {
		t.Fatalf("realtime_channel_permissions query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "channel_name = $3") {
		t.Fatalf("channel_name filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "operation = $6") {
		t.Fatalf("operation filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "tenant_id") {
		t.Fatalf("tenant_id izolasyonu query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestAuthorizeRealtimeChannelSQLStoreAuthorizeChannel_DeniedPlatformSuccess(t *testing.T) {
	db := &realtimeChannelAuthQueryRowProviderMock{
		row: &realtimeChannelAuthRowMock{
			values: []any{
				"tenant-a",
				"conn-002",
				"platform.ops",
				"client-002",
				"user-002",
				"subscribe",
				"platform",
				"denied",
				false,
				"platform kanali tenant runtime icin kapali",
			},
		},
	}

	store := NewAuthorizeRealtimeChannelSQLStore(db)

	result, err := store.AuthorizeChannel(context.Background(), AuthorizeRealtimeChannelCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-002",
		ChannelName:  "platform.ops",
		ClientID:     "client-002",
		UserRef:      "user-002",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.AccessGranted {
		t.Fatalf("beklenen access_granted false")
	}

	if result.AuthStatus != "denied" {
		t.Fatalf("beklenen auth_status denied, alinan: %s", result.AuthStatus)
	}

	if result.ChannelScope != "platform" {
		t.Fatalf("beklenen channel_scope platform, alinan: %s", result.ChannelScope)
	}

	if result.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestAuthorizeRealtimeChannelSQLStoreAuthorizeChannel_NoDB(t *testing.T) {
	store := NewAuthorizeRealtimeChannelSQLStore(nil)

	_, err := store.AuthorizeChannel(context.Background(), AuthorizeRealtimeChannelCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestAuthorizeRealtimeChannelSQLStoreAuthorizeChannel_ScanError(t *testing.T) {
	db := &realtimeChannelAuthQueryRowProviderMock{
		row: &realtimeChannelAuthRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewAuthorizeRealtimeChannelSQLStore(db)

	_, err := store.AuthorizeChannel(context.Background(), AuthorizeRealtimeChannelCommand{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
