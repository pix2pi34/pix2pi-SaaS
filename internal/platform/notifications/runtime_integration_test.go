package notifications

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

type notificationRuntimeRecord struct {
	NotificationID string
	TenantID       string
	Channel        string
	NotificationKey string
	RecipientRef   string
	Subject        string
	MessageBody    string
	TemplateRef    string
	Priority       string
	Status         string
	DedupKey       string
	ScheduledAt    *time.Time
	RequestedBy    string
	Metadata       map[string]any

	AttemptNo      int
	WorkerID       string
	LeaseExpiresAt *time.Time
	DeliveryRef    string
	ProviderCode   string
	ErrorCode      string
	CompletionNote string

	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type notificationsRuntimeIntegrationStore struct {
	mu            sync.Mutex
	nowFn         func() time.Time
	seq           int
	notifications map[string]*notificationRuntimeRecord
}

func newNotificationsRuntimeIntegrationStore() *notificationsRuntimeIntegrationStore {
	return &notificationsRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		notifications: make(map[string]*notificationRuntimeRecord),
	}
}

func (s *notificationsRuntimeIntegrationStore) CreateNotification(_ context.Context, cmd CreateNotificationCommand) (CreateNotificationResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	tenantID := strings.TrimSpace(cmd.TenantID)
	dedupKey := strings.TrimSpace(cmd.DedupKey)

	if dedupKey != "" {
		for _, item := range s.notifications {
			if item.TenantID == tenantID && item.DedupKey == dedupKey {
				return CreateNotificationResult{
					NotificationID: item.NotificationID,
					Status:         item.Status,
					DedupMatched:   true,
					ScheduledAt:    cloneTimePtr(item.ScheduledAt),
				}, nil
			}
		}
	}

	s.seq++
	notificationID := fmt.Sprintf("notif-%03d", s.seq)

	status := "queued"
	if cmd.ScheduledAt != nil {
		status = "scheduled"
	}

	rec := &notificationRuntimeRecord{
		NotificationID:  notificationID,
		TenantID:        tenantID,
		Channel:         strings.TrimSpace(cmd.Channel),
		NotificationKey: strings.TrimSpace(cmd.NotificationKey),
		RecipientRef:    strings.TrimSpace(cmd.RecipientRef),
		Subject:         strings.TrimSpace(cmd.Subject),
		MessageBody:     strings.TrimSpace(cmd.MessageBody),
		TemplateRef:     strings.TrimSpace(cmd.TemplateRef),
		Priority:        strings.TrimSpace(cmd.Priority),
		Status:          status,
		DedupKey:        dedupKey,
		ScheduledAt:     cloneTimePtr(cmd.ScheduledAt),
		RequestedBy:     strings.TrimSpace(cmd.RequestedBy),
		Metadata:        cloneMap(cmd.Metadata),
		AttemptNo:       0,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
	s.notifications[notificationID] = rec

	return CreateNotificationResult{
		NotificationID: rec.NotificationID,
		Status:         rec.Status,
		DedupMatched:   false,
		ScheduledAt:    cloneTimePtr(rec.ScheduledAt),
	}, nil
}

func (s *notificationsRuntimeIntegrationStore) ClaimNotificationForDelivery(_ context.Context, cmd ClaimNotificationDeliveryCommand) (ClaimNotificationDeliveryResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	tenantID := strings.TrimSpace(cmd.TenantID)
	channel := strings.TrimSpace(cmd.Channel)

	candidates := make([]*notificationRuntimeRecord, 0)
	for _, item := range s.notifications {
		if item.TenantID != tenantID {
			continue
		}
		if item.Channel != channel {
			continue
		}
		if item.Status != "queued" && item.Status != "scheduled" {
			continue
		}
		if item.ScheduledAt != nil && item.ScheduledAt.After(now) {
			continue
		}
		candidates = append(candidates, item)
	}

	sort.Slice(candidates, func(i, j int) bool {
		pi := notificationPriorityRank(candidates[i].Priority)
		pj := notificationPriorityRank(candidates[j].Priority)
		if pi == pj {
			if candidates[i].CreatedAt.Equal(candidates[j].CreatedAt) {
				return candidates[i].NotificationID < candidates[j].NotificationID
			}
			return candidates[i].CreatedAt.Before(candidates[j].CreatedAt)
		}
		return pi < pj
	})

	if len(candidates) == 0 {
		return ClaimNotificationDeliveryResult{
			Claimed: false,
		}, nil
	}

	item := candidates[0]
	item.Status = "sending"
	item.WorkerID = strings.TrimSpace(cmd.WorkerID)
	item.AttemptNo++
	lease := now.Add(time.Duration(cmd.LeaseSeconds) * time.Second)
	item.LeaseExpiresAt = &lease
	item.UpdatedAt = now

	return ClaimNotificationDeliveryResult{
		Claimed:         true,
		NotificationID:  item.NotificationID,
		Channel:         item.Channel,
		NotificationKey: item.NotificationKey,
		RecipientRef:    item.RecipientRef,
		Subject:         item.Subject,
		MessageBody:     item.MessageBody,
		TemplateRef:     item.TemplateRef,
		Priority:        item.Priority,
		Status:          item.Status,
		AttemptNo:       item.AttemptNo,
		LeaseExpiresAt:  cloneTimePtr(item.LeaseExpiresAt),
	}, nil
}

func (s *notificationsRuntimeIntegrationStore) UpdateNotificationDelivery(_ context.Context, cmd UpdateNotificationDeliveryCommand) (UpdateNotificationDeliveryResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item, ok := s.notifications[strings.TrimSpace(cmd.NotificationID)]
	if !ok {
		return UpdateNotificationDeliveryResult{}, fmt.Errorf("notification not found: %s", cmd.NotificationID)
	}

	if item.TenantID != strings.TrimSpace(cmd.TenantID) {
		return UpdateNotificationDeliveryResult{}, fmt.Errorf("tenant mismatch")
	}

	if item.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return UpdateNotificationDeliveryResult{}, fmt.Errorf("worker mismatch")
	}

	if item.AttemptNo != cmd.AttemptNo {
		return UpdateNotificationDeliveryResult{}, fmt.Errorf("attempt mismatch")
	}

	now := s.nowFn().UTC()
	item.Status = strings.TrimSpace(cmd.Status)
	item.DeliveryRef = strings.TrimSpace(cmd.DeliveryRef)
	item.ProviderCode = strings.TrimSpace(cmd.ProviderCode)
	item.ErrorCode = strings.TrimSpace(cmd.ErrorCode)
	item.UpdatedAt = now

	if item.Status == "sending" && cmd.LeaseExtendSeconds > 0 {
		lease := now.Add(time.Duration(cmd.LeaseExtendSeconds) * time.Second)
		item.LeaseExpiresAt = &lease
	} else if item.Status == "sent" || item.Status == "failed" || item.Status == "cancelled" {
		item.LeaseExpiresAt = nil
	}

	return UpdateNotificationDeliveryResult{
		NotificationID: item.NotificationID,
		Status:         item.Status,
		AttemptNo:      item.AttemptNo,
		DeliveryRef:    item.DeliveryRef,
		ProviderCode:   item.ProviderCode,
		ErrorCode:      item.ErrorCode,
		LeaseExpiresAt: cloneTimePtr(item.LeaseExpiresAt),
	}, nil
}

func (s *notificationsRuntimeIntegrationStore) CompleteNotificationDelivery(_ context.Context, cmd CompleteNotificationDeliveryCommand) (CompleteNotificationDeliveryResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item, ok := s.notifications[strings.TrimSpace(cmd.NotificationID)]
	if !ok {
		return CompleteNotificationDeliveryResult{}, fmt.Errorf("notification not found: %s", cmd.NotificationID)
	}

	if item.TenantID != strings.TrimSpace(cmd.TenantID) {
		return CompleteNotificationDeliveryResult{}, fmt.Errorf("tenant mismatch")
	}

	if item.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return CompleteNotificationDeliveryResult{}, fmt.Errorf("worker mismatch")
	}

	if item.AttemptNo != cmd.AttemptNo {
		return CompleteNotificationDeliveryResult{}, fmt.Errorf("attempt mismatch")
	}

	now := s.nowFn().UTC()
	item.Status = strings.TrimSpace(cmd.Status)
	item.DeliveryRef = strings.TrimSpace(cmd.DeliveryRef)
	item.ProviderCode = strings.TrimSpace(cmd.ProviderCode)
	item.ErrorCode = strings.TrimSpace(cmd.ErrorCode)
	item.CompletionNote = strings.TrimSpace(cmd.CompletionNote)
	item.LeaseExpiresAt = nil
	item.UpdatedAt = now

	return CompleteNotificationDeliveryResult{
		NotificationID: item.NotificationID,
		Status:         item.Status,
		AttemptNo:      item.AttemptNo,
		DeliveryRef:    item.DeliveryRef,
		ProviderCode:   item.ProviderCode,
		ErrorCode:      item.ErrorCode,
		CompletionNote: item.CompletionNote,
		LeaseReleased:  true,
	}, nil
}

func (s *notificationsRuntimeIntegrationStore) RecoverNotification(_ context.Context, cmd RecoverNotificationCommand) (RecoverNotificationResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item, ok := s.notifications[strings.TrimSpace(cmd.NotificationID)]
	if !ok {
		return RecoverNotificationResult{}, fmt.Errorf("notification not found: %s", cmd.NotificationID)
	}

	if item.TenantID != strings.TrimSpace(cmd.TenantID) {
		return RecoverNotificationResult{}, fmt.Errorf("tenant mismatch")
	}

	item.WorkerID = ""
	item.LeaseExpiresAt = nil
	item.UpdatedAt = s.nowFn().UTC()

	switch strings.TrimSpace(cmd.ActionType) {
	case "retry":
		item.Status = "queued"
	case "requeue":
		item.Status = "queued"
		if strings.TrimSpace(cmd.TargetChannel) != "" {
			item.Channel = strings.TrimSpace(cmd.TargetChannel)
		}
	case "dead_letter":
		item.Status = "dead_letter"
	default:
		return RecoverNotificationResult{}, fmt.Errorf("unsupported action: %s", cmd.ActionType)
	}

	if cmd.ResetAttempts {
		item.AttemptNo = 0
	}

	return RecoverNotificationResult{
		NotificationID: item.NotificationID,
		Status:         item.Status,
		Channel:        item.Channel,
		AttemptNo:      item.AttemptNo,
		LeaseReleased:  true,
	}, nil
}

func (s *notificationsRuntimeIntegrationStore) snapshotNotification(notificationID string) (notificationRuntimeRecord, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item, ok := s.notifications[notificationID]
	if !ok {
		return notificationRuntimeRecord{}, false
	}

	out := *item
	out.ScheduledAt = cloneTimePtr(item.ScheduledAt)
	out.LeaseExpiresAt = cloneTimePtr(item.LeaseExpiresAt)
	out.Metadata = cloneMap(item.Metadata)
	return out, true
}

func notificationPriorityRank(priority string) int {
	switch strings.TrimSpace(priority) {
	case "critical":
		return 1
	case "high":
		return 2
	case "normal":
		return 3
	case "low":
		return 4
	default:
		return 5
	}
}

func TestNotificationsRuntimeIntegration_CreateClaimUpdateCompleteFlow(t *testing.T) {
	store := newNotificationsRuntimeIntegrationStore()

	createUsecase := NewCreateNotificationUsecase(store)
	claimUsecase := NewClaimNotificationDeliveryUsecase(store)
	updateUsecase := NewUpdateNotificationDeliveryUsecase(store)
	completeUsecase := NewCompleteNotificationDeliveryUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 0, 0, 0, time.UTC)
	}
	createUsecase.nowFn = store.nowFn

	createResp, err := createUsecase.Create(context.Background(), CreateNotificationRequest{
		TenantID:        "tenant-a",
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		Subject:         "Hos geldiniz",
		MessageBody:     "Merhaba",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("create hatasi: %v", err)
	}

	if createResp.Status != "queued" {
		t.Fatalf("beklenen create status queued, alinan: %s", createResp.Status)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 1, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

	claimResp, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("claim hatasi: %v", err)
	}

	if !claimResp.Claimed {
		t.Fatalf("notification claim edilmeliydi")
	}

	if claimResp.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", claimResp.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 2, 0, 0, time.UTC)
	}
	updateUsecase.nowFn = store.nowFn

	updateResp, err := updateUsecase.Update(context.Background(), UpdateNotificationDeliveryRequest{
		TenantID:           "tenant-a",
		NotificationID:     claimResp.NotificationID,
		WorkerID:           "worker-01",
		Status:             "sending",
		AttemptNo:          1,
		DeliveryRef:        "provider-msg-1",
		ProviderCode:       "smtp-250",
		LeaseExtendSeconds: 120,
	})
	if err != nil {
		t.Fatalf("update hatasi: %v", err)
	}

	if updateResp.Status != "sending" {
		t.Fatalf("beklenen update status sending, alinan: %s", updateResp.Status)
	}

	if updateResp.LeaseExpiresAt == nil {
		t.Fatalf("beklenen lease_expires_at dolu olmaliydi")
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 3, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	completeResp, err := completeUsecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
		TenantID:       "tenant-a",
		NotificationID: claimResp.NotificationID,
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
		CompletionNote: "teslim edildi",
	})
	if err != nil {
		t.Fatalf("complete hatasi: %v", err)
	}

	if completeResp.Status != "sent" {
		t.Fatalf("beklenen complete status sent, alinan: %s", completeResp.Status)
	}

	item, ok := store.snapshotNotification(claimResp.NotificationID)
	if !ok {
		t.Fatalf("notification snapshot bulunamadi")
	}

	if item.Status != "sent" {
		t.Fatalf("beklenen final status sent, alinan: %s", item.Status)
	}

	if item.DeliveryRef != "provider-msg-1" {
		t.Fatalf("beklenen delivery_ref provider-msg-1, alinan: %s", item.DeliveryRef)
	}
}

func TestNotificationsRuntimeIntegration_ScheduledAndTenantIsolationFlow(t *testing.T) {
	store := newNotificationsRuntimeIntegrationStore()

	createUsecase := NewCreateNotificationUsecase(store)
	claimUsecase := NewClaimNotificationDeliveryUsecase(store)

	now := time.Date(2026, 4, 25, 21, 0, 0, 0, time.UTC)
	store.nowFn = func() time.Time { return now }
	createUsecase.nowFn = store.nowFn
	claimUsecase.nowFn = store.nowFn

	scheduledAt := time.Date(2026, 4, 25, 22, 0, 0, 0, time.UTC)

	_, err := createUsecase.Create(context.Background(), CreateNotificationRequest{
		TenantID:        "tenant-a",
		Channel:         "sms",
		NotificationKey: "notif-a",
		RecipientRef:    "905551112233",
		MessageBody:     "A tenant scheduled",
		Priority:        "normal",
		ScheduledAt:     &scheduledAt,
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("tenant-a scheduled create hatasi: %v", err)
	}

	_, err = createUsecase.Create(context.Background(), CreateNotificationRequest{
		TenantID:        "tenant-b",
		Channel:         "sms",
		NotificationKey: "notif-b",
		RecipientRef:    "905551119999",
		MessageBody:     "B tenant immediate",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("tenant-b create hatasi: %v", err)
	}

	tenantAClaimBeforeDue, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "sms",
		WorkerID:     "worker-a",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-a early claim hatasi: %v", err)
	}

	if tenantAClaimBeforeDue.Claimed {
		t.Fatalf("tenant-a scheduled notification due olmadan claim edilmemeliydi")
	}

	tenantBClaim, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-b",
		Channel:      "sms",
		WorkerID:     "worker-b",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-b claim hatasi: %v", err)
	}

	if !tenantBClaim.Claimed {
		t.Fatalf("tenant-b notification claim edilmeliydi")
	}

	now = time.Date(2026, 4, 25, 22, 1, 0, 0, time.UTC)
	store.nowFn = func() time.Time { return now }
	claimUsecase.nowFn = store.nowFn

	tenantAClaimAfterDue, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "sms",
		WorkerID:     "worker-a",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-a due sonrasi claim hatasi: %v", err)
	}

	if !tenantAClaimAfterDue.Claimed {
		t.Fatalf("tenant-a scheduled notification due sonrasi claim edilmeliydi")
	}
}

func TestNotificationsRuntimeIntegration_FailRetryRequeueDeadLetterFlow(t *testing.T) {
	store := newNotificationsRuntimeIntegrationStore()

	createUsecase := NewCreateNotificationUsecase(store)
	claimUsecase := NewClaimNotificationDeliveryUsecase(store)
	completeUsecase := NewCompleteNotificationDeliveryUsecase(store)
	recoverUsecase := NewRecoverNotificationUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 30, 0, 0, time.UTC)
	}
	createUsecase.nowFn = store.nowFn

	createResp, err := createUsecase.Create(context.Background(), CreateNotificationRequest{
		TenantID:        "tenant-a",
		Channel:         "email",
		NotificationKey: "notif-recovery",
		RecipientRef:    "user_2@example.com",
		MessageBody:     "Merhaba",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("create hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 31, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

	firstClaim, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("ilk claim hatasi: %v", err)
	}

	if !firstClaim.Claimed {
		t.Fatalf("ilk claim basarili olmaliydi")
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 32, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	_, err = completeUsecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
		TenantID:       "tenant-a",
		NotificationID: createResp.NotificationID,
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-421",
		ErrorCode:      "SMTP_TIMEOUT",
		CompletionNote: "ilk gonderim timeout",
	})
	if err != nil {
		t.Fatalf("ilk fail hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 33, 0, 0, time.UTC)
	}
	recoverUsecase.nowFn = store.nowFn

	retryResp, err := recoverUsecase.Recover(context.Background(), RecoverNotificationRequest{
		TenantID:      "tenant-a",
		NotificationID: createResp.NotificationID,
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("retry hatasi: %v", err)
	}

	if retryResp.Status != "queued" {
		t.Fatalf("beklenen retry sonrasi status queued, alinan: %s", retryResp.Status)
	}

	if retryResp.AttemptNo != 0 {
		t.Fatalf("beklenen retry sonrasi attempt_no 0, alinan: %d", retryResp.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 34, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

	secondClaim, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-02",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("ikinci claim hatasi: %v", err)
	}

	if !secondClaim.Claimed {
		t.Fatalf("ikinci claim basarili olmaliydi")
	}

	if secondClaim.AttemptNo != 1 {
		t.Fatalf("beklenen ikinci claim attempt_no 1, alinan: %d", secondClaim.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 35, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	_, err = completeUsecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
		TenantID:       "tenant-a",
		NotificationID: createResp.NotificationID,
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-2",
		ProviderCode:   "smtp-550",
		ErrorCode:      "SMTP_HARD_FAIL",
		CompletionNote: "kalici hata",
	})
	if err != nil {
		t.Fatalf("ikinci fail hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 36, 0, 0, time.UTC)
	}
	recoverUsecase.nowFn = store.nowFn

	requeueResp, err := recoverUsecase.Recover(context.Background(), RecoverNotificationRequest{
		TenantID:      "tenant-a",
		NotificationID: createResp.NotificationID,
		ActionType:    "requeue",
		RequestedBy:   "worker-02",
		TargetChannel: "sms",
		Reason:        "sms fallback kanali",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("requeue hatasi: %v", err)
	}

	if requeueResp.Channel != "sms" {
		t.Fatalf("beklenen requeue sonrasi channel sms, alinan: %s", requeueResp.Channel)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 37, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

	thirdClaim, err := claimUsecase.Claim(context.Background(), ClaimNotificationDeliveryRequest{
		TenantID:     "tenant-a",
		Channel:      "sms",
		WorkerID:     "worker-03",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("ucuncu claim hatasi: %v", err)
	}

	if !thirdClaim.Claimed {
		t.Fatalf("ucuncu claim basarili olmaliydi")
	}

	if thirdClaim.AttemptNo != 2 {
		t.Fatalf("beklenen ucuncu claim attempt_no 2, alinan: %d", thirdClaim.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 38, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	_, err = completeUsecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
		TenantID:       "tenant-a",
		NotificationID: createResp.NotificationID,
		WorkerID:       "worker-03",
		Status:         "failed",
		AttemptNo:      2,
		DeliveryRef:    "provider-msg-3",
		ProviderCode:   "sms-500",
		ErrorCode:      "SMS_HARD_FAIL",
		CompletionNote: "sms kanalinda da hata",
	})
	if err != nil {
		t.Fatalf("ucuncu fail hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 39, 0, 0, time.UTC)
	}
	recoverUsecase.nowFn = store.nowFn

	deadLetterResp, err := recoverUsecase.Recover(context.Background(), RecoverNotificationRequest{
		TenantID:      "tenant-a",
		NotificationID: createResp.NotificationID,
		ActionType:    "dead_letter",
		RequestedBy:   "worker-03",
		Reason:        "kalici hata",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("dead-letter hatasi: %v", err)
	}

	if deadLetterResp.Status != "dead_letter" {
		t.Fatalf("beklenen dead_letter status, alinan: %s", deadLetterResp.Status)
	}

	item, ok := store.snapshotNotification(createResp.NotificationID)
	if !ok {
		t.Fatalf("notification snapshot bulunamadi")
	}

	if item.Status != "dead_letter" {
		t.Fatalf("beklenen final status dead_letter, alinan: %s", item.Status)
	}

	if item.Channel != "sms" {
		t.Fatalf("beklenen final channel sms, alinan: %s", item.Channel)
	}
}
