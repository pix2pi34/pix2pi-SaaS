package service

import (
	"testing"
	"time"
)

func testSecurityAuditEvent(severity string, eventType string) SecurityAuditEvent {
	return SecurityAuditEvent{
		EventType:  eventType,
		Severity:   severity,
		Source:     "security_service",
		TenantID:   "tenant_42",
		Reason:     "test reason",
		RequestID:  "req_123",
		OccurredAt: time.Now(),
	}
}

func TestIncidentReadinessDecision_Validate_Success(t *testing.T) {
	decision := IncidentReadinessDecision{
		EventType:          SecurityEventAuthRejected,
		Severity:           SecuritySeverityHigh,
		ShouldAlert:        true,
		ShouldCreateTicket: true,
		Escalation:         IncidentEscalationP2Urgent,
		Category:           "auth",
	}

	if err := decision.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestIncidentReadinessDecision_Validate_MissingEscalation(t *testing.T) {
	decision := IncidentReadinessDecision{
		EventType: SecurityEventAuthRejected,
		Severity:  SecuritySeverityHigh,
	}

	err := decision.Validate()
	if err == nil {
		t.Fatal("expected missing escalation error")
	}
	if err != ErrIncidentEscalationUndefined {
		t.Fatalf("expected ErrIncidentEscalationUndefined, got %v", err)
	}
}

func TestBuildIncidentReadinessDecision_HighSeverity(t *testing.T) {
	decision, err := BuildIncidentReadinessDecision(
		testSecurityAuditEvent(SecuritySeverityHigh, SecurityEventAuthRejected),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.ShouldAlert {
		t.Fatal("expected alert for high severity")
	}
	if !decision.ShouldCreateTicket {
		t.Fatal("expected ticket for high severity")
	}
	if decision.Escalation != IncidentEscalationP2Urgent {
		t.Fatalf("expected %s, got %s", IncidentEscalationP2Urgent, decision.Escalation)
	}
	if decision.Category != "auth" {
		t.Fatalf("expected auth, got %s", decision.Category)
	}
}

func TestBuildIncidentReadinessDecision_CriticalSeverity(t *testing.T) {
	decision, err := BuildIncidentReadinessDecision(
		testSecurityAuditEvent(SecuritySeverityCritical, SecurityEventWebhookRejected),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.ShouldAlert {
		t.Fatal("expected alert for critical severity")
	}
	if !decision.ShouldCreateTicket {
		t.Fatal("expected ticket for critical severity")
	}
	if decision.Escalation != IncidentEscalationP1Immediate {
		t.Fatalf("expected %s, got %s", IncidentEscalationP1Immediate, decision.Escalation)
	}
	if decision.Category != "webhook" {
		t.Fatalf("expected webhook, got %s", decision.Category)
	}
}

func TestBuildIncidentReadinessDecision_MediumSeverity(t *testing.T) {
	decision, err := BuildIncidentReadinessDecision(
		testSecurityAuditEvent(SecuritySeverityMedium, SecurityEventPolicyRejected),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.ShouldAlert {
		t.Fatal("did not expect alert for medium severity")
	}
	if !decision.ShouldCreateTicket {
		t.Fatal("expected ticket for medium severity")
	}
	if decision.Escalation != IncidentEscalationP3Review {
		t.Fatalf("expected %s, got %s", IncidentEscalationP3Review, decision.Escalation)
	}
	if decision.Category != "policy" {
		t.Fatalf("expected policy, got %s", decision.Category)
	}
}

func TestBuildIncidentReadinessDecision_LowSeverity(t *testing.T) {
	decision, err := BuildIncidentReadinessDecision(
		testSecurityAuditEvent(SecuritySeverityLow, SecurityEventPolicyRejected),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.ShouldAlert {
		t.Fatal("did not expect alert for low severity")
	}
	if decision.ShouldCreateTicket {
		t.Fatal("did not expect ticket for low severity")
	}
	if decision.Escalation != IncidentEscalationP4Observe {
		t.Fatalf("expected %s, got %s", IncidentEscalationP4Observe, decision.Escalation)
	}
}

func TestBuildIncidentReadinessDecision_InvalidEvent(t *testing.T) {
	_, err := BuildIncidentReadinessDecision(SecurityAuditEvent{})
	if err == nil {
		t.Fatal("expected invalid event error")
	}
}

func TestBuildIncidentReadinessDecision_UnknownSeverity(t *testing.T) {
	event := testSecurityAuditEvent("unknown", SecurityEventAuthRejected)

	_, err := BuildIncidentReadinessDecision(event)
	if err == nil {
		t.Fatal("expected unknown severity error")
	}
	if err != ErrSecurityAuditSeverityRequired {
		t.Fatalf("expected ErrSecurityAuditSeverityRequired, got %v", err)
	}
}
