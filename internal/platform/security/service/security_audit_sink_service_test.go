package service

import (
	"testing"
	"time"
)

func TestNewInMemorySecurityAuditSink(t *testing.T) {
	sink := NewInMemorySecurityAuditSink()
	if sink == nil {
		t.Fatal("expected sink")
	}
	if len(sink.Events) != 0 {
		t.Fatalf("expected 0 events, got %d", len(sink.Events))
	}
}

func TestEmitSecurityAuditEvent_Success(t *testing.T) {
	sink := NewInMemorySecurityAuditSink()

	event := SecurityAuditEvent{
		EventType:  SecurityEventAuthRejected,
		Severity:   SecuritySeverityHigh,
		Source:     "auth_middleware",
		TenantID:   "tenant_42",
		Reason:     "invalid token",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}

	err := EmitSecurityAuditEvent(sink, event)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(sink.Events))
	}
	if sink.Events[0].EventType != SecurityEventAuthRejected {
		t.Fatalf("expected %s, got %s", SecurityEventAuthRejected, sink.Events[0].EventType)
	}
}

func TestEmitSecurityAuditEvent_NilSink(t *testing.T) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventAuthRejected,
		Severity:   SecuritySeverityHigh,
		Source:     "auth_middleware",
		TenantID:   "tenant_42",
		Reason:     "invalid token",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}

	err := EmitSecurityAuditEvent(nil, event)
	if err == nil {
		t.Fatal("expected nil sink error")
	}
	if err != ErrSecurityAuditSinkRequired {
		t.Fatalf("expected ErrSecurityAuditSinkRequired, got %v", err)
	}
}

func TestEmitSecurityAuditEvent_InvalidEvent(t *testing.T) {
	sink := NewInMemorySecurityAuditSink()

	event := SecurityAuditEvent{
		EventType:  "",
		Severity:   SecuritySeverityHigh,
		Source:     "auth_middleware",
		TenantID:   "tenant_42",
		Reason:     "invalid token",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}

	err := EmitSecurityAuditEvent(sink, event)
	if err == nil {
		t.Fatal("expected invalid event error")
	}
	if err != ErrSecurityAuditEventTypeRequired {
		t.Fatalf("expected ErrSecurityAuditEventTypeRequired, got %v", err)
	}
}

func TestEmitAuthRejectedSecurityAudit_Success(t *testing.T) {
	sink := NewInMemorySecurityAuditSink()

	err := EmitAuthRejectedSecurityAudit(
		sink,
		"tenant_42",
		"auth_middleware",
		"expired token",
		"req_123",
		time.Now().Unix(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(sink.Events))
	}
	if sink.Events[0].EventType != SecurityEventAuthRejected {
		t.Fatalf("expected %s, got %s", SecurityEventAuthRejected, sink.Events[0].EventType)
	}
	if sink.Events[0].Severity != SecuritySeverityHigh {
		t.Fatalf("expected %s, got %s", SecuritySeverityHigh, sink.Events[0].Severity)
	}
}

func TestEmitWebhookRejectedSecurityAudit_Success(t *testing.T) {
	sink := NewInMemorySecurityAuditSink()

	err := EmitWebhookRejectedSecurityAudit(
		sink,
		"tenant_42",
		"iyzico_webhook",
		"invalid signature",
		"req_123",
		time.Now().Unix(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(sink.Events))
	}
	if sink.Events[0].EventType != SecurityEventWebhookRejected {
		t.Fatalf("expected %s, got %s", SecurityEventWebhookRejected, sink.Events[0].EventType)
	}
}

func TestEmitPolicyRejectedSecurityAudit_Success(t *testing.T) {
	sink := NewInMemorySecurityAuditSink()

	err := EmitPolicyRejectedSecurityAudit(
		sink,
		"tenant_42",
		"request_guard",
		"injection risk detected",
		"req_123",
		time.Now().Unix(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(sink.Events))
	}
	if sink.Events[0].EventType != SecurityEventPolicyRejected {
		t.Fatalf("expected %s, got %s", SecurityEventPolicyRejected, sink.Events[0].EventType)
	}
	if sink.Events[0].Severity != SecuritySeverityMedium {
		t.Fatalf("expected %s, got %s", SecuritySeverityMedium, sink.Events[0].Severity)
	}
}
