package webhooks

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

type webhookRuntimeRecord struct {
	WebhookID      string
	TenantID       string
	SubscriptionID string
	EventID        string
	EventType      string
	TargetURL      string
	SecretRef      string
	Signature      string
	SignedPayload  string
	Payload        map[string]any
	RequestedBy    string
	Status         string
	AttemptNo      int
	DeliveryRef    string
	NextAttemptAt  *time.Time
	LeaseExpiresAt *time.Time
	WorkerID       string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type webhookRuntimeIntegrationStore struct {
	mu        sync.Mutex
	nowFn     func() time.Time
	deliveries map[string]*webhookRuntimeRecord
}

func newWebhookRuntimeIntegrationStore() *webhookRuntimeIntegrationStore {
	return &webhookRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		deliveries: make(map[string]*webhookRuntimeRecord),
	}
}

func webhookRuntimeKey(tenantID, deliveryRef string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(deliveryRef)
}

func (s *webhookRuntimeIntegrationStore) DeliverWebhook(_ context.Context, cmd DeliverWebhookCommand) (DeliverWebhookResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	deliveryRef := strings.TrimSpace(cmd.EventID) + "-delivery-1"

	rec := &webhookRuntimeRecord{
		WebhookID:      strings.TrimSpace(cmd.WebhookID),
		TenantID:       strings.TrimSpace(cmd.TenantID),
		SubscriptionID: strings.TrimSpace(cmd.SubscriptionID),
		EventID:        strings.TrimSpace(cmd.EventID),
		EventType:      strings.TrimSpace(cmd.EventType),
		TargetURL:      strings.TrimSpace(cmd.TargetURL),
		SecretRef:      strings.TrimSpace(cmd.SecretRef),
		Signature:      strings.TrimSpace(cmd.Signature),
		SignedPayload:  strings.TrimSpace(cmd.SignedPayload),
		Payload:        cloneMap(cmd.Payload),
		RequestedBy:    strings.TrimSpace(cmd.RequestedBy),
		Status:         "sending",
		AttemptNo:      1,
		DeliveryRef:    deliveryRef,
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	s.deliveries[webhookRuntimeKey(rec.TenantID, rec.DeliveryRef)] = rec

	return DeliverWebhookResult{
		WebhookID:      rec.WebhookID,
		SubscriptionID: rec.SubscriptionID,
		EventID:        rec.EventID,
		EventType:      rec.EventType,
		TargetURL:      rec.TargetURL,
		Signature:      rec.Signature,
		Status:         rec.Status,
		AttemptNo:      rec.AttemptNo,
		DeliveryRef:    rec.DeliveryRef,
	}, nil
}

func (s *webhookRuntimeIntegrationStore) ApplyRecovery(_ context.Context, cmd ApplyWebhookRecoveryCommand) (ApplyWebhookRecoveryResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := webhookRuntimeKey(cmd.TenantID, cmd.DeliveryRef)
	rec, ok := s.deliveries[key]
	if !ok {
		return ApplyWebhookRecoveryResult{}, fmt.Errorf("webhook delivery not found: %s", cmd.DeliveryRef)
	}

	now := s.nowFn().UTC()

	switch strings.TrimSpace(cmd.ActionType) {
	case "retry":
		rec.Status = "pending"
		if cmd.ResetAttempts {
			rec.AttemptNo = 0
		}
		rec.NextAttemptAt = nil
	case "requeue":
		rec.Status = "pending"
		rec.NextAttemptAt = cloneWebhookTimePtr(cmd.NextAttemptAt)
	case "dead_letter":
		rec.Status = "dead_letter"
	default:
		return ApplyWebhookRecoveryResult{}, fmt.Errorf("unsupported webhook recovery action: %s", cmd.ActionType)
	}

	rec.LeaseExpiresAt = nil
	rec.WorkerID = ""
	rec.UpdatedAt = now

	return ApplyWebhookRecoveryResult{
		WebhookID:      rec.WebhookID,
		DeliveryRef:    rec.DeliveryRef,
		ActionType:     strings.TrimSpace(cmd.ActionType),
		Status:         rec.Status,
		AttemptNo:      rec.AttemptNo,
		NextAttemptAt:  cloneWebhookTimePtr(rec.NextAttemptAt),
		LeaseReleased:  true,
	}, nil
}

func (s *webhookRuntimeIntegrationStore) snapshotDelivery(tenantID, deliveryRef string) (webhookRuntimeRecord, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.deliveries[webhookRuntimeKey(tenantID, deliveryRef)]
	if !ok {
		return webhookRuntimeRecord{}, false
	}

	out := *rec
	out.Payload = cloneMap(rec.Payload)
	out.NextAttemptAt = cloneWebhookTimePtr(rec.NextAttemptAt)
	out.LeaseExpiresAt = cloneWebhookTimePtr(rec.LeaseExpiresAt)
	return out, true
}

func TestWebhookRuntimeIntegration_DeliverRetryRequeueDeadLetterFlow(t *testing.T) {
	store := newWebhookRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 9, 0, 0, 0, time.UTC)
	}

	deliverUsecase := NewDeliverWebhookUsecase(store)
	recoveryUsecase := NewApplyWebhookRecoveryUsecase(store)

	deliverUsecase.nowFn = store.nowFn
	recoveryUsecase.nowFn = store.nowFn

	deliverResp, err := deliverUsecase.Deliver(context.Background(), DeliverWebhookRequest{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("deliver hatasi: %v", err)
	}

	if deliverResp.Status != "sending" {
		t.Fatalf("beklenen status sending, alinan: %s", deliverResp.Status)
	}

	if deliverResp.Signature == "" {
		t.Fatalf("signature bos olmamaliydi")
	}

	retryResp, err := recoveryUsecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		TenantID:      "tenant-a",
		WebhookID:     "webhook-001",
		DeliveryRef:   deliverResp.DeliveryRef,
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("retry hatasi: %v", err)
	}

	if retryResp.Status != "pending" {
		t.Fatalf("beklenen retry status pending, alinan: %s", retryResp.Status)
	}

	if retryResp.AttemptNo != 0 {
		t.Fatalf("beklenen retry attempt_no 0, alinan: %d", retryResp.AttemptNo)
	}

	nextAttemptAt := time.Date(2026, 4, 26, 9, 5, 0, 0, time.UTC)

	requeueResp, err := recoveryUsecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		TenantID:      "tenant-a",
		WebhookID:     "webhook-001",
		DeliveryRef:   deliverResp.DeliveryRef,
		ActionType:    "requeue",
		RequestedBy:   "worker-01",
		Reason:        "backoff sonrasi tekrar kuyruk",
		NextAttemptAt: &nextAttemptAt,
	})
	if err != nil {
		t.Fatalf("requeue hatasi: %v", err)
	}

	if requeueResp.Status != "pending" {
		t.Fatalf("beklenen requeue status pending, alinan: %s", requeueResp.Status)
	}

	if requeueResp.NextAttemptAt == nil || !requeueResp.NextAttemptAt.Equal(nextAttemptAt) {
		t.Fatalf("beklenen next_attempt_at korunmaliydi")
	}

	deadLetterResp, err := recoveryUsecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		TenantID:    "tenant-a",
		WebhookID:   "webhook-001",
		DeliveryRef: deliverResp.DeliveryRef,
		ActionType:  "dead_letter",
		RequestedBy: "worker-01",
		Reason:      "kalici hata",
	})
	if err != nil {
		t.Fatalf("dead_letter hatasi: %v", err)
	}

	if deadLetterResp.Status != "dead_letter" {
		t.Fatalf("beklenen dead_letter status, alinan: %s", deadLetterResp.Status)
	}

	snapshot, ok := store.snapshotDelivery("tenant-a", deliverResp.DeliveryRef)
	if !ok {
		t.Fatalf("delivery snapshot bulunamadi")
	}

	if snapshot.Status != "dead_letter" {
		t.Fatalf("beklenen final status dead_letter, alinan: %s", snapshot.Status)
	}

	if snapshot.Signature == "" || snapshot.SignedPayload == "" {
		t.Fatalf("signature ve signed_payload korunmaliydi")
	}
}

func TestWebhookRuntimeIntegration_TenantIsolationFlow(t *testing.T) {
	store := newWebhookRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 10, 0, 0, 0, time.UTC)
	}

	deliverUsecase := NewDeliverWebhookUsecase(store)
	recoveryUsecase := NewApplyWebhookRecoveryUsecase(store)

	deliverUsecase.nowFn = store.nowFn
	recoveryUsecase.nowFn = store.nowFn

	tenantAResp, err := deliverUsecase.Deliver(context.Background(), DeliverWebhookRequest{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-a",
		SubscriptionID: "sub-a",
		EventID:        "event-a",
		EventType:      "invoice.created",
		TargetURL:      "https://tenant-a.example.com/webhook",
		SecretRef:      "secret-a",
		Payload:        map[string]any{"invoice_id": "inv-a"},
		RequestedBy:    "worker-a",
	})
	if err != nil {
		t.Fatalf("tenant-a deliver hatasi: %v", err)
	}

	tenantBResp, err := deliverUsecase.Deliver(context.Background(), DeliverWebhookRequest{
		TenantID:       "tenant-b",
		WebhookID:      "webhook-b",
		SubscriptionID: "sub-b",
		EventID:        "event-b",
		EventType:      "invoice.created",
		TargetURL:      "https://tenant-b.example.com/webhook",
		SecretRef:      "secret-b",
		Payload:        map[string]any{"invoice_id": "inv-b"},
		RequestedBy:    "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b deliver hatasi: %v", err)
	}

	_, err = recoveryUsecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		TenantID:      "tenant-b",
		WebhookID:     "webhook-b",
		DeliveryRef:   tenantBResp.DeliveryRef,
		ActionType:    "retry",
		RequestedBy:   "worker-b",
		Reason:        "tenant-b retry",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("tenant-b retry hatasi: %v", err)
	}

	tenantASnapshot, ok := store.snapshotDelivery("tenant-a", tenantAResp.DeliveryRef)
	if !ok {
		t.Fatalf("tenant-a snapshot bulunamadi")
	}

	tenantBSnapshot, ok := store.snapshotDelivery("tenant-b", tenantBResp.DeliveryRef)
	if !ok {
		t.Fatalf("tenant-b snapshot bulunamadi")
	}

	if tenantASnapshot.Status != "sending" {
		t.Fatalf("tenant-a status etkilenmemeliydi, alinan: %s", tenantASnapshot.Status)
	}

	if tenantBSnapshot.Status != "pending" {
		t.Fatalf("tenant-b status pending olmaliydi, alinan: %s", tenantBSnapshot.Status)
	}

	if tenantASnapshot.Signature == tenantBSnapshot.Signature {
		t.Fatalf("tenant bazli farkli secret ile signature farkli olmaliydi")
	}
}

func TestWebhookRuntimeIntegration_InvalidRecoveryDoesNotMutateFlow(t *testing.T) {
	store := newWebhookRuntimeIntegrationStore()

	deliverUsecase := NewDeliverWebhookUsecase(store)
	recoveryUsecase := NewApplyWebhookRecoveryUsecase(store)

	deliverResp, err := deliverUsecase.Deliver(context.Background(), DeliverWebhookRequest{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-009",
		SubscriptionID: "sub-009",
		EventID:        "event-009",
		EventType:      "invoice.cancelled",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-009",
		Payload:        map[string]any{"invoice_id": "inv-009"},
		RequestedBy:    "worker-09",
	})
	if err != nil {
		t.Fatalf("deliver hatasi: %v", err)
	}

	_, err = recoveryUsecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		TenantID:    "tenant-a",
		WebhookID:   "webhook-009",
		DeliveryRef: deliverResp.DeliveryRef,
		ActionType:  "resume",
		RequestedBy: "worker-09",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	snapshot, ok := store.snapshotDelivery("tenant-a", deliverResp.DeliveryRef)
	if !ok {
		t.Fatalf("snapshot bulunamadi")
	}

	if snapshot.Status != "sending" {
		t.Fatalf("invalid recovery delivery status bozmasin, alinan: %s", snapshot.Status)
	}
}
