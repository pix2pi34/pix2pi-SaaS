package opsconsole

import "testing"

func newNotificationWebhookMonitorRuntimeForTest(t *testing.T) *NotificationWebhookMonitorConsoleRuntime {
	t.Helper()

	runtime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())

	_, _, err := runtime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:       "tenant_7",
		DeliveryID:     "email_delivery_1",
		NotificationID: "notification_1",
		Channel:        NotificationMonitorChannelEmail,
		Provider:       "SIMULATION",
		Destination:    "user@example.com",
		State:          NotificationMonitorStateDelivered,
		Attempt:        1,
		CorrelationID:  "corr-email-1",
		Metadata:       map[string]string{"source": "email_runtime"},
	})
	if err != nil {
		t.Fatalf("upsert email delivery failed: %v", err)
	}

	_, _, err = runtime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:       "tenant_7",
		DeliveryID:     "webhook_delivery_1",
		NotificationID: "notification_2",
		Channel:        NotificationMonitorChannelWebhook,
		Provider:       "HTTP",
		Destination:    "https://example.com/webhook",
		EventType:      "order.created",
		State:          NotificationMonitorStateRetryScheduled,
		Attempt:        2,
		RetryAt:        "2026-05-07T08:00:00Z",
		LastError:      "timeout",
		SignatureTrace: "sha256=trace",
		CorrelationID:  "corr-webhook-1",
		Metadata:       map[string]string{"source": "webhook_runtime"},
	})
	if err != nil {
		t.Fatalf("upsert webhook delivery failed: %v", err)
	}

	_, _, err = runtime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:       "tenant_7",
		DeliveryID:     "webhook_dlq_1",
		NotificationID: "notification_3",
		Channel:        NotificationMonitorChannelWebhook,
		Provider:       "HTTP",
		Destination:    "https://example.com/webhook",
		EventType:      "order.failed",
		State:          NotificationMonitorStateDLQ,
		Attempt:        5,
		DLQID:          "dlq_1",
		LastError:      "max retry exhausted",
	})
	if err != nil {
		t.Fatalf("upsert webhook dlq delivery failed: %v", err)
	}

	return runtime
}

func TestNotificationWebhookMonitorConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newNotificationWebhookMonitorRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		IncludeFailed:  true,
		CorrelationID:  "corr-snapshot-1",
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected snapshot allowed, got reason=%s", decision.Reason)
	}
	if !snapshot.OK {
		t.Fatal("expected snapshot OK")
	}
	if snapshot.DeliveryCount != 3 {
		t.Fatalf("expected delivery count 3, got %d", snapshot.DeliveryCount)
	}
	if snapshot.EmailCount != 1 {
		t.Fatalf("expected email count 1, got %d", snapshot.EmailCount)
	}
	if snapshot.WebhookCount != 2 {
		t.Fatalf("expected webhook count 2, got %d", snapshot.WebhookCount)
	}
	if snapshot.DeliveredCount != 1 {
		t.Fatalf("expected delivered count 1, got %d", snapshot.DeliveredCount)
	}
	if snapshot.RetryScheduledCount != 1 {
		t.Fatalf("expected retry scheduled count 1, got %d", snapshot.RetryScheduledCount)
	}
	if snapshot.DLQCount != 1 {
		t.Fatalf("expected dlq count 1, got %d", snapshot.DLQCount)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeChannelFilter(t *testing.T) {
	runtime := newNotificationWebhookMonitorRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:      "tenant_7",
		ChannelFilter: NotificationMonitorChannelWebhook,
		IncludeFailed: true,
	})
	if err != nil {
		t.Fatalf("build filtered snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected filtered snapshot allowed, got reason=%s", decision.Reason)
	}
	if snapshot.DeliveryCount != 2 {
		t.Fatalf("expected webhook delivery count 2, got %d", snapshot.DeliveryCount)
	}
	if snapshot.WebhookCount != 2 {
		t.Fatalf("expected webhook count 2, got %d", snapshot.WebhookCount)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeStateFilter(t *testing.T) {
	runtime := newNotificationWebhookMonitorRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:      "tenant_7",
		StateFilter:   NotificationMonitorStateRetryScheduled,
		IncludeFailed: true,
	})
	if err != nil {
		t.Fatalf("build state filtered snapshot failed: %v", err)
	}
	if snapshot.DeliveryCount != 1 {
		t.Fatalf("expected retry scheduled delivery count 1, got %d", snapshot.DeliveryCount)
	}
	if snapshot.Deliveries[0].State != NotificationMonitorStateRetryScheduled {
		t.Fatalf("expected retry scheduled state, got %s", snapshot.Deliveries[0].State)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeWebhookOnly(t *testing.T) {
	runtime := newNotificationWebhookMonitorRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:           "tenant_7",
		IncludeWebhookOnly: true,
		IncludeFailed:      true,
	})
	if err != nil {
		t.Fatalf("build webhook only snapshot failed: %v", err)
	}
	if snapshot.DeliveryCount != 2 {
		t.Fatalf("expected webhook-only count 2, got %d", snapshot.DeliveryCount)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeHidesFailedWhenDisabled(t *testing.T) {
	runtime := newNotificationWebhookMonitorRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:      "tenant_7",
		IncludeFailed: false,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.DeliveryCount != 2 {
		t.Fatalf("expected dlq hidden and delivery count 2, got %d", snapshot.DeliveryCount)
	}
	if snapshot.DLQCount != 0 {
		t.Fatalf("expected dlq count 0 when hidden, got %d", snapshot.DLQCount)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{})
	if err != ErrNotificationMonitorMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != NotificationMonitorReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newNotificationWebhookMonitorRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrNotificationMonitorCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != NotificationMonitorReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeRejectsInvalidChannel(t *testing.T) {
	runtime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())

	_, decision, err := runtime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:    "tenant_7",
		DeliveryID:  "delivery_1",
		Channel:     "FAX",
		Destination: "x",
		State:       NotificationMonitorStateQueued,
	})
	if err != ErrNotificationMonitorInvalidChannel {
		t.Fatalf("expected invalid channel error, got %v", err)
	}
	if decision.Reason != NotificationMonitorReasonInvalidChannel {
		t.Fatalf("expected invalid channel reason, got %s", decision.Reason)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeRejectsInvalidState(t *testing.T) {
	runtime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())

	_, decision, err := runtime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:    "tenant_7",
		DeliveryID:  "delivery_1",
		Channel:     NotificationMonitorChannelEmail,
		Destination: "user@example.com",
		State:       "UNKNOWN",
	})
	if err != ErrNotificationMonitorInvalidState {
		t.Fatalf("expected invalid state error, got %v", err)
	}
	if decision.Reason != NotificationMonitorReasonInvalidState {
		t.Fatalf("expected invalid state reason, got %s", decision.Reason)
	}
}

func TestNotificationWebhookMonitorConsoleRuntimeRejectsMissingDestination(t *testing.T) {
	runtime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())

	_, decision, err := runtime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:   "tenant_7",
		DeliveryID: "delivery_1",
		Channel:    NotificationMonitorChannelEmail,
		State:      NotificationMonitorStateQueued,
	})
	if err != ErrNotificationMonitorMissingDestination {
		t.Fatalf("expected missing destination error, got %v", err)
	}
	if decision.Reason != NotificationMonitorReasonMissingDestination {
		t.Fatalf("expected missing destination reason, got %s", decision.Reason)
	}
}
