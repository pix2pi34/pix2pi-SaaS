package opsruntime

import (
	"strings"
	"testing"
)

func webhookRetryRequestForTest() WebhookRetryRequest {
	return WebhookRetryRequest{
		TenantID:      "tenant_7",
		DeliveryID:    "webhook_delivery_1",
		WebhookID:     "webhook_1",
		EventType:     "order.created",
		URL:           "https://example.com/webhook",
		PayloadHash:   "payload_hash_1",
		Attempt:       1,
		LastError:     "timeout",
		RequestedBy:   "system",
		CorrelationID: "corr-retry-1",
		Metadata:      map[string]string{"source": "webhook_delivery"},
	}
}

func TestWebhookRetryDLQRuntimeSchedulesRetry(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	record, decision, err := runtime.ScheduleRetry(webhookRetryRequestForTest())
	if err != nil {
		t.Fatalf("schedule retry failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected retry allowed, got reason=%s", decision.Reason)
	}
	if record.RetryID == "" {
		t.Fatal("expected retry id")
	}
	if record.State != WebhookRetryStateScheduled {
		t.Fatalf("expected RETRY_SCHEDULED, got %s", record.State)
	}
	if record.BackoffSeconds != 5 {
		t.Fatalf("expected first backoff 5, got %d", record.BackoffSeconds)
	}
	if record.NextAttemptAt == "" {
		t.Fatal("expected next attempt timestamp")
	}
	if record.Metadata["source"] != "webhook_delivery" {
		t.Fatalf("expected metadata source webhook_delivery, got %s", record.Metadata["source"])
	}
}

func TestWebhookRetryDLQRuntimeCalculatesBackoff(t *testing.T) {
	if got := CalculateWebhookRetryBackoffSeconds(1, 5, 300); got != 5 {
		t.Fatalf("expected attempt 1 backoff 5, got %d", got)
	}
	if got := CalculateWebhookRetryBackoffSeconds(2, 5, 300); got != 10 {
		t.Fatalf("expected attempt 2 backoff 10, got %d", got)
	}
	if got := CalculateWebhookRetryBackoffSeconds(3, 5, 300); got != 20 {
		t.Fatalf("expected attempt 3 backoff 20, got %d", got)
	}
	if got := CalculateWebhookRetryBackoffSeconds(10, 5, 60); got != 60 {
		t.Fatalf("expected capped backoff 60, got %d", got)
	}
}

func TestWebhookRetryDLQRuntimeMarksRetryCompleted(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	retry, _, err := runtime.ScheduleRetry(webhookRetryRequestForTest())
	if err != nil {
		t.Fatalf("schedule retry failed: %v", err)
	}

	updated, decision, err := runtime.MarkRetryCompleted("tenant_7", retry.RetryID)
	if err != nil {
		t.Fatalf("mark retry completed failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected mark completed allowed, got reason=%s", decision.Reason)
	}
	if updated.State != WebhookRetryStateCompleted {
		t.Fatalf("expected RETRY_COMPLETED, got %s", updated.State)
	}
}

func TestWebhookRetryDLQRuntimeMovesToDLQ(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.Attempt = 5
	req.LastError = "max retry exhausted"

	record, decision, err := runtime.MoveToDLQ(req)
	if err != nil {
		t.Fatalf("move to dlq failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected dlq allowed, got reason=%s", decision.Reason)
	}
	if record.DLQID == "" {
		t.Fatal("expected dlq id")
	}
	if record.State != WebhookRetryStateDLQ {
		t.Fatalf("expected DLQ, got %s", record.State)
	}
	if record.FinalAttempt != 5 {
		t.Fatalf("expected final attempt 5, got %d", record.FinalAttempt)
	}
}

func TestWebhookRetryDLQRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.TenantID = ""

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsMissingDeliveryID(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.DeliveryID = ""

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryMissingDeliveryID {
		t.Fatalf("expected missing delivery id error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonMissingDeliveryID {
		t.Fatalf("expected missing delivery id reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsMissingEventType(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.EventType = ""

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryMissingEventType {
		t.Fatalf("expected missing event type error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonMissingEventType {
		t.Fatalf("expected missing event type reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsMissingPayloadHash(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.PayloadHash = ""

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryMissingPayloadHash {
		t.Fatalf("expected missing payload hash error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonMissingPayloadHash {
		t.Fatalf("expected missing payload hash reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsMissingError(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.LastError = ""

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryMissingError {
		t.Fatalf("expected missing error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonMissingError {
		t.Fatalf("expected missing error reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsInvalidAttempt(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.Attempt = 0

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryInvalidAttempt {
		t.Fatalf("expected invalid attempt error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonInvalidAttempt {
		t.Fatalf("expected invalid attempt reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsMaxAttemptsExceeded(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.Attempt = 6

	_, decision, err := runtime.ScheduleRetry(req)
	if err != ErrWebhookRetryMaxAttemptsExceeded {
		t.Fatalf("expected max attempts exceeded, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonMaxAttemptsExceeded {
		t.Fatalf("expected max attempts reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeRejectsDuplicateRetry(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	first, _, err := runtime.ScheduleRetry(webhookRetryRequestForTest())
	if err != nil {
		t.Fatalf("first retry schedule failed: %v", err)
	}

	_, decision, err := runtime.ScheduleRetry(webhookRetryRequestForTest())
	if err != ErrWebhookRetryDuplicateRetry {
		t.Fatalf("expected duplicate retry error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonDuplicateRetry {
		t.Fatalf("expected duplicate retry reason, got %s", decision.Reason)
	}
	if decision.RetryID != first.RetryID {
		t.Fatalf("expected duplicate retry id %s, got %s", first.RetryID, decision.RetryID)
	}
}

func TestWebhookRetryDLQRuntimeTenantSafeAccess(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	retry, _, err := runtime.ScheduleRetry(webhookRetryRequestForTest())
	if err != nil {
		t.Fatalf("schedule retry failed: %v", err)
	}

	got, err := runtime.GetRetry("tenant_7", retry.RetryID)
	if err != nil {
		t.Fatalf("get retry failed: %v", err)
	}
	if got.RetryID != retry.RetryID {
		t.Fatalf("expected retry id %s, got %s", retry.RetryID, got.RetryID)
	}

	_, err = runtime.GetRetry("tenant_8", retry.RetryID)
	if err != ErrWebhookRetryCrossTenant {
		t.Fatalf("expected cross tenant retry error, got %v", err)
	}

	tenantRetries, err := runtime.ListTenantRetries("tenant_7")
	if err != nil {
		t.Fatalf("list tenant retries failed: %v", err)
	}
	if len(tenantRetries) != 1 {
		t.Fatalf("expected tenant retry count 1, got %d", len(tenantRetries))
	}

	deliveryRetries, err := runtime.ListDeliveryRetries("tenant_7", "webhook_delivery_1")
	if err != nil {
		t.Fatalf("list delivery retries failed: %v", err)
	}
	if len(deliveryRetries) != 1 {
		t.Fatalf("expected delivery retry count 1, got %d", len(deliveryRetries))
	}

	tenant8Retries, err := runtime.ListTenantRetries("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 retries failed: %v", err)
	}
	if len(tenant8Retries) != 0 {
		t.Fatalf("expected tenant_8 retry count 0, got %d", len(tenant8Retries))
	}
}

func TestWebhookRetryDLQRuntimeTenantSafeDLQAccess(t *testing.T) {
	runtime := NewWebhookRetryDLQRuntime(DefaultWebhookRetryDLQRuntimeConfig())

	req := webhookRetryRequestForTest()
	req.Attempt = 5
	req.LastError = "final failure"

	dlq, _, err := runtime.MoveToDLQ(req)
	if err != nil {
		t.Fatalf("move to dlq failed: %v", err)
	}

	got, err := runtime.GetDLQ("tenant_7", dlq.DLQID)
	if err != nil {
		t.Fatalf("get dlq failed: %v", err)
	}
	if got.DLQID != dlq.DLQID {
		t.Fatalf("expected dlq id %s, got %s", dlq.DLQID, got.DLQID)
	}

	_, err = runtime.GetDLQ("tenant_8", dlq.DLQID)
	if err != ErrWebhookRetryCrossTenant {
		t.Fatalf("expected cross tenant dlq error, got %v", err)
	}

	dlqRecords, err := runtime.ListTenantDLQ("tenant_7")
	if err != nil {
		t.Fatalf("list dlq failed: %v", err)
	}
	if len(dlqRecords) != 1 {
		t.Fatalf("expected dlq count 1, got %d", len(dlqRecords))
	}
}

func TestWebhookRetryDLQRuntimeRejectsDLQWhenDisabled(t *testing.T) {
	config := DefaultWebhookRetryDLQRuntimeConfig()
	config.EnableDLQ = false
	runtime := NewWebhookRetryDLQRuntime(config)

	req := webhookRetryRequestForTest()
	req.Attempt = 5

	_, decision, err := runtime.MoveToDLQ(req)
	if err != ErrWebhookRetryDLQDisabled {
		t.Fatalf("expected dlq disabled error, got %v", err)
	}
	if decision.Reason != WebhookRetryReasonDLQDisabled {
		t.Fatalf("expected dlq disabled reason, got %s", decision.Reason)
	}
}

func TestWebhookRetryDLQRuntimeIDGenerators(t *testing.T) {
	retryID := NewWebhookRetryID()
	dlqID := NewWebhookDLQID()

	if !strings.HasPrefix(retryID, "webhook_retry_") {
		t.Fatalf("unexpected retry id %s", retryID)
	}
	if !strings.HasPrefix(dlqID, "webhook_dlq_") {
		t.Fatalf("unexpected dlq id %s", dlqID)
	}
}
