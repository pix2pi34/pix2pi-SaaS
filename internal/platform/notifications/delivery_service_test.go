package notifications

import (
	"context"
	"errors"
	"testing"
	"time"
)

type claimNotificationDeliveryStoreMock struct {
	lastCmd ClaimNotificationDeliveryCommand
	result  ClaimNotificationDeliveryResult
	err     error
	called  bool
}

func (m *claimNotificationDeliveryStoreMock) ClaimNotificationForDelivery(_ context.Context, cmd ClaimNotificationDeliveryCommand) (ClaimNotificationDeliveryResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestClaimNotificationDeliveryRequestValidate_Success(t *testing.T) {
	req := ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestClaimNotificationDeliveryRequestValidate_InvalidChannel(t *testing.T) {
	req := ClaimNotificationDeliveryRequest{
		Channel:      "fax",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimNotificationDeliveryRequestValidate_InvalidWorkerID(t *testing.T) {
	req := ClaimNotificationDeliveryRequest{
		Channel:      "email",
		WorkerID:     "worker 01",
		LeaseSeconds: 60,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimNotificationDeliveryRequestValidate_InvalidLeaseSeconds(t *testing.T) {
	req := ClaimNotificationDeliveryRequest{
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimNotificationDeliveryUsecaseClaim_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 20, 31, 0, 0, time.UTC)

	store := &claimNotificationDeliveryStoreMock{
		result: ClaimNotificationDeliveryResult{
			Claimed:         true,
			NotificationID:  "notif-id-1",
			Channel:         "email",
			NotificationKey: "notif-001",
			RecipientRef:    "user_1@example.com",
			Subject:         "Hos geldiniz",
			MessageBody:     "Merhaba",
			TemplateRef:     "",
			Priority:        "high",
			Status:          "sending",
			AttemptNo:       1,
			LeaseExpiresAt:  &leaseExpiresAt,
		},
	}

	usecase := NewClaimNotificationDeliveryUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Channel != "email" {
		t.Fatalf("beklenen channel email, alinan: %s", store.lastCmd.Channel)
	}

	if !resp.Claimed {
		t.Fatalf("beklenen claimed true")
	}

	if resp.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen notification_id notif-id-1, alinan: %s", resp.NotificationID)
	}

	if resp.Status != "sending" {
		t.Fatalf("beklenen status sending, alinan: %s", resp.Status)
	}

	if resp.LeaseExpiresAt == nil || !resp.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !resp.ClaimedAt.Equal(time.Date(2026, 4, 25, 20, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen claimed_at sabit zaman")
	}
}

func TestClaimNotificationDeliveryUsecaseClaim_NoNotificationFound(t *testing.T) {
	store := &claimNotificationDeliveryStoreMock{
		result: ClaimNotificationDeliveryResult{
			Claimed: false,
		},
	}

	usecase := NewClaimNotificationDeliveryUsecase(store)

	resp, err := usecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		Channel:      "sms",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Claimed {
		t.Fatalf("beklenen claimed false")
	}

	if resp.NotificationID != "" {
		t.Fatalf("beklenen bos notification_id")
	}
}

func TestClaimNotificationDeliveryUsecaseClaim_ValidationError(t *testing.T) {
	store := &claimNotificationDeliveryStoreMock{}
	usecase := NewClaimNotificationDeliveryUsecase(store)

	_, err := usecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		Channel:      "fax",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestClaimNotificationDeliveryUsecaseClaim_StoreError(t *testing.T) {
	store := &claimNotificationDeliveryStoreMock{
		err: errors.New("claim notification failed"),
	}
	usecase := NewClaimNotificationDeliveryUsecase(store)

	_, err := usecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestClaimNotificationDeliveryResponseValidate_InvalidClaimedAt(t *testing.T) {
	resp := ClaimNotificationDeliveryResponse{
		Claimed: false,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
