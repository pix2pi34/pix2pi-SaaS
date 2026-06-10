package service

import (
	"testing"
	"time"
)

func TestSecurityAuditEvent_Validate_Success(t *testing.T) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventAuthRejected,
		Severity:   SecuritySeverityHigh,
		Source:     "auth_middleware",
		TenantID:   "tenant_42",
		Reason:     "invalid token",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}

	if err := event.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestSecurityAuditEvent_Validate_MissingTenant(t *testing.T) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventAuthRejected,
		Severity:   SecuritySeverityHigh,
		Source:     "auth_middleware",
		TenantID:   "",
		Reason:     "invalid token",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}

	err := event.Validate()
	if err == nil {
		t.Fatal("expected missing tenant error")
	}
	if err != ErrSecurityAuditTenantRequired {
		t.Fatalf("expected ErrSecurityAuditTenantRequired, got %v", err)
	}
}

func TestSecurityAuditEvent_Validate_MissingReason(t *testing.T) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventAuthRejected,
		Severity:   SecuritySeverityHigh,
		Source:     "auth_middleware",
		TenantID:   "tenant_42",
		Reason:     "",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}

	err := event.Validate()
	if err == nil {
		t.Fatal("expected missing reason error")
	}
	if err != ErrSecurityAuditReasonRequired {
		t.Fatalf("expected ErrSecurityAuditReasonRequired, got %v", err)
	}
}

func TestNewAuthRejectedAuditEvent_Success(t *testing.T) {
	event, err := NewAuthRejectedAuditEvent(
		"tenant_42",
		"auth_middleware",
		"expired token",
		"req_123",
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if event.EventType != SecurityEventAuthRejected {
		t.Fatalf("expected %s, got %s", SecurityEventAuthRejected, event.EventType)
	}
	if event.Severity != SecuritySeverityHigh {
		t.Fatalf("expected %s, got %s", SecuritySeverityHigh, event.Severity)
	}
}

func TestNewWebhookRejectedAuditEvent_Success(t *testing.T) {
	event, err := NewWebhookRejectedAuditEvent(
		"tenant_42",
		"iyzico_webhook",
		"invalid signature",
		"req_123",
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if event.EventType != SecurityEventWebhookRejected {
		t.Fatalf("expected %s, got %s", SecurityEventWebhookRejected, event.EventType)
	}
	if event.Severity != SecuritySeverityHigh {
		t.Fatalf("expected %s, got %s", SecuritySeverityHigh, event.Severity)
	}
}

func TestNewPolicyRejectedAuditEvent_Success(t *testing.T) {
	event, err := NewPolicyRejectedAuditEvent(
		"tenant_42",
		"request_guard",
		"injection risk detected",
		"req_123",
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if event.EventType != SecurityEventPolicyRejected {
		t.Fatalf("expected %s, got %s", SecurityEventPolicyRejected, event.EventType)
	}
	if event.Severity != SecuritySeverityMedium {
		t.Fatalf("expected %s, got %s", SecuritySeverityMedium, event.Severity)
	}
}

func TestNewPolicyRejectedAuditEvent_Invalid(t *testing.T) {
	_, err := NewPolicyRejectedAuditEvent(
		"",
		"request_guard",
		"injection risk detected",
		"req_123",
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected invalid event error")
	}
}
