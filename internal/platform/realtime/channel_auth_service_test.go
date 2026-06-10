package realtime

import (
	"context"
	"errors"
	"testing"
	"time"
)

type realtimeChannelAuthStoreMock struct {
	lastCmd AuthorizeRealtimeChannelCommand
	result  AuthorizeRealtimeChannelResult
	err     error
	called  bool
}

func (m *realtimeChannelAuthStoreMock) AuthorizeChannel(_ context.Context, cmd AuthorizeRealtimeChannelCommand) (AuthorizeRealtimeChannelResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestAuthorizeRealtimeChannelRequestValidate_Success(t *testing.T) {
	req := AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestAuthorizeRealtimeChannelRequestValidate_MissingTenantID(t *testing.T) {
	req := AuthorizeRealtimeChannelRequest{
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestAuthorizeRealtimeChannelRequestValidate_InvalidOperation(t *testing.T) {
	req := AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "delete",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestAuthorizeRealtimeChannelRequestValidate_InvalidChannelName(t *testing.T) {
	req := AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestAuthorizeRealtimeChannelUsecaseAuthorize_Success(t *testing.T) {
	store := &realtimeChannelAuthStoreMock{
		result: AuthorizeRealtimeChannelResult{
			TenantID:      "tenant-a",
			ConnectionID:  "conn-001",
			ChannelName:   "tenant.notifications",
			ClientID:      "client-001",
			UserRef:       "user-001",
			Operation:     "subscribe",
			ChannelScope:  "tenant",
			AuthStatus:    "granted",
			AccessGranted: true,
		},
	}

	usecase := NewAuthorizeRealtimeChannelUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 12, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.TenantID != "tenant-a" {
		t.Fatalf("beklenen tenant_id tenant-a, alinan: %s", store.lastCmd.TenantID)
	}

	if !resp.AccessGranted {
		t.Fatalf("beklenen access_granted true")
	}

	if resp.AuthStatus != "granted" {
		t.Fatalf("beklenen auth_status granted, alinan: %s", resp.AuthStatus)
	}

	if resp.ChannelScope != "tenant" {
		t.Fatalf("beklenen channel_scope tenant, alinan: %s", resp.ChannelScope)
	}

	if !resp.AuthorizedAt.Equal(time.Date(2026, 4, 26, 12, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen authorized_at sabit zaman")
	}
}

func TestAuthorizeRealtimeChannelUsecaseAuthorize_FallbackDeniedPlatformChannel(t *testing.T) {
	store := &realtimeChannelAuthStoreMock{
		result: AuthorizeRealtimeChannelResult{},
	}

	usecase := NewAuthorizeRealtimeChannelUsecase(store)

	resp, err := usecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
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

	if resp.AccessGranted {
		t.Fatalf("beklenen access_granted false")
	}

	if resp.AuthStatus != "denied" {
		t.Fatalf("beklenen auth_status denied, alinan: %s", resp.AuthStatus)
	}

	if resp.ChannelScope != "platform" {
		t.Fatalf("beklenen channel_scope platform, alinan: %s", resp.ChannelScope)
	}

	if resp.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestAuthorizeRealtimeChannelUsecaseAuthorize_ValidationError(t *testing.T) {
	store := &realtimeChannelAuthStoreMock{}
	usecase := NewAuthorizeRealtimeChannelUsecase(store)

	_, err := usecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "delete",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestAuthorizeRealtimeChannelUsecaseAuthorize_StoreError(t *testing.T) {
	store := &realtimeChannelAuthStoreMock{
		err: errors.New("authorize realtime channel failed"),
	}

	usecase := NewAuthorizeRealtimeChannelUsecase(store)

	_, err := usecase.Authorize(context.Background(), AuthorizeRealtimeChannelRequest{
		TenantID:     "tenant-a",
		ConnectionID: "conn-001",
		ChannelName:  "tenant.notifications",
		ClientID:     "client-001",
		UserRef:      "user-001",
		Operation:    "subscribe",
		RequestedBy:  "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestAuthorizeRealtimeChannelResponseValidate_InvalidAuthorizedAt(t *testing.T) {
	resp := AuthorizeRealtimeChannelResponse{
		TenantID:      "tenant-a",
		ConnectionID:  "conn-001",
		ChannelName:   "tenant.notifications",
		ClientID:      "client-001",
		UserRef:       "user-001",
		Operation:     "subscribe",
		ChannelScope:  "tenant",
		AuthStatus:    "granted",
		AccessGranted: true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
