package paymentadapter

import (
	"errors"
	"testing"
	"time"
)

func TestPaymentWebhookIntakeConstructorRequiresDependencies(t *testing.T) {
	service, _ := testPaymentService(t, []string{"AUTHORIZE", "WEBHOOK_VERIFY"}, ModeSandbox, false)

	if _, err := NewPaymentWebhookIntakeRuntime(nil, "pix2pi_simulation", "secret"); err == nil {
		t.Fatal("missing payment service must fail")
	}
	if _, err := NewPaymentWebhookIntakeRuntime(service, "", "secret"); err == nil {
		t.Fatal("missing provider code must fail")
	}
	if _, err := NewPaymentWebhookIntakeRuntime(service, "pix2pi_simulation", ""); err == nil {
		t.Fatal("missing signing secret must fail")
	}
}

func TestPaymentWebhookIntakeVerifyAndRecordAddsAuditEvent(t *testing.T) {
	runtime, service := testWebhookRuntime(t)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	payload := []byte(`{"event":"payment.authorized","attempt_id":"attempt_service_001"}`)
	now := time.Unix(1893456000, 0).UTC()
	runtime.now = func() time.Time { return now }

	result, err := runtime.VerifyAndRecord(PaymentWebhookIntakeRequest{
		TenantID:        "tenant_7",
		AttemptID:       authorized.Attempt.AttemptID,
		ProviderCode:    "pix2pi_simulation",
		CorrelationID:   "corr_webhook_001",
		RequestID:       "req_webhook_001",
		SignatureHeader: BuildPaymentWebhookSignatureHeader("whsec_test", now, payload),
		RawPayload:      payload,
		ReceivedAt:      now,
	})
	if err != nil {
		t.Fatalf("expected webhook verify success, got %v", err)
	}
	if !result.Verified {
		t.Fatal("expected verified webhook result")
	}
	if result.SignatureVersion != "v1" {
		t.Fatalf("expected v1 signature, got %s", result.SignatureVersion)
	}
	if result.Attempt.Status != AttemptStatusAuthorized {
		t.Fatalf("webhook verify must not change status, got %s", result.Attempt.Status)
	}
	if len(result.Attempt.Events) != 3 {
		t.Fatalf("expected creation + authorize + webhook audit events, got %d", len(result.Attempt.Events))
	}
}

func TestPaymentWebhookIntakeRejectsInvalidSignature(t *testing.T) {
	runtime, service := testWebhookRuntime(t)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	payload := []byte(`{"event":"payment.authorized"}`)
	now := time.Unix(1893456000, 0).UTC()
	runtime.now = func() time.Time { return now }

	_, err = runtime.VerifyAndRecord(PaymentWebhookIntakeRequest{
		TenantID:        "tenant_7",
		AttemptID:       authorized.Attempt.AttemptID,
		ProviderCode:    "pix2pi_simulation",
		CorrelationID:   "corr_webhook_invalid_sig",
		RequestID:       "req_webhook_invalid_sig",
		SignatureHeader: "t=1893456000,v1=bad_signature",
		RawPayload:      payload,
	})
	if err == nil {
		t.Fatal("invalid signature must fail")
	}
	if !errors.Is(err, ErrPaymentWebhookInvalidSignature) {
		t.Fatalf("expected invalid signature error, got %v", err)
	}
}

func TestPaymentWebhookIntakeRejectsStaleTimestamp(t *testing.T) {
	runtime, service := testWebhookRuntime(t)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	payload := []byte(`{"event":"payment.authorized"}`)
	now := time.Unix(1893456000, 0).UTC()
	oldTimestamp := now.Add(-10 * time.Minute)
	runtime.now = func() time.Time { return now }

	_, err = runtime.VerifyAndRecord(PaymentWebhookIntakeRequest{
		TenantID:        "tenant_7",
		AttemptID:       authorized.Attempt.AttemptID,
		ProviderCode:    "pix2pi_simulation",
		CorrelationID:   "corr_webhook_stale",
		RequestID:       "req_webhook_stale",
		SignatureHeader: BuildPaymentWebhookSignatureHeader("whsec_test", oldTimestamp, payload),
		RawPayload:      payload,
	})
	if err == nil {
		t.Fatal("stale webhook timestamp must fail")
	}
	if !errors.Is(err, ErrPaymentWebhookTimestampSkew) {
		t.Fatalf("expected timestamp skew error, got %v", err)
	}
}

func TestPaymentWebhookIntakeRejectsProviderMismatch(t *testing.T) {
	runtime, service := testWebhookRuntime(t)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	payload := []byte(`{"event":"payment.authorized"}`)
	now := time.Unix(1893456000, 0).UTC()
	runtime.now = func() time.Time { return now }

	_, err = runtime.VerifyAndRecord(PaymentWebhookIntakeRequest{
		TenantID:        "tenant_7",
		AttemptID:       authorized.Attempt.AttemptID,
		ProviderCode:    "another_provider",
		CorrelationID:   "corr_webhook_provider_mismatch",
		RequestID:       "req_webhook_provider_mismatch",
		SignatureHeader: BuildPaymentWebhookSignatureHeader("whsec_test", now, payload),
		RawPayload:      payload,
	})
	if err == nil {
		t.Fatal("provider mismatch must fail")
	}
	if !errors.Is(err, ErrPaymentWebhookProviderMismatch) {
		t.Fatalf("expected provider mismatch error, got %v", err)
	}
}

func TestPaymentWebhookIntakeRejectsMissingRawPayload(t *testing.T) {
	runtime, service := testWebhookRuntime(t)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	now := time.Unix(1893456000, 0).UTC()
	runtime.now = func() time.Time { return now }

	_, err = runtime.VerifyAndRecord(PaymentWebhookIntakeRequest{
		TenantID:        "tenant_7",
		AttemptID:       authorized.Attempt.AttemptID,
		ProviderCode:    "pix2pi_simulation",
		CorrelationID:   "corr_webhook_missing_payload",
		RequestID:       "req_webhook_missing_payload",
		SignatureHeader: BuildPaymentWebhookSignatureHeader("whsec_test", now, []byte(`{}`)),
		RawPayload:      nil,
	})
	if err == nil {
		t.Fatal("missing raw payload must fail")
	}
	if !errors.Is(err, ErrPaymentWebhookInvalidRequest) {
		t.Fatalf("expected invalid request error, got %v", err)
	}
}

func TestPaymentWebhookSignatureHeaderParser(t *testing.T) {
	payload := []byte(`{"event":"payment.authorized"}`)
	timestamp := time.Unix(1893456000, 0).UTC()

	header := BuildPaymentWebhookSignatureHeader("whsec_test", timestamp, payload)
	parts, err := parsePaymentWebhookSignatureHeader(header)
	if err != nil {
		t.Fatalf("expected signature header parse success, got %v", err)
	}
	if parts.Version != "v1" {
		t.Fatalf("expected v1, got %s", parts.Version)
	}
	if !parts.Timestamp.Equal(timestamp) {
		t.Fatalf("expected timestamp %v, got %v", timestamp, parts.Timestamp)
	}
	if parts.Signature == "" {
		t.Fatal("signature must not be empty")
	}
}

func testWebhookRuntime(t *testing.T) (*PaymentWebhookIntakeRuntime, *PaymentService) {
	t.Helper()

	service, _ := testPaymentService(t, []string{"AUTHORIZE", "WEBHOOK_VERIFY"}, ModeSandbox, false)
	runtime, err := NewPaymentWebhookIntakeRuntime(service, "pix2pi_simulation", "whsec_test")
	if err != nil {
		t.Fatalf("expected webhook runtime, got %v", err)
	}

	return runtime, service
}
