package service

import "testing"

func testIncidentDecision() IncidentReadinessDecision {
	return IncidentReadinessDecision{
		EventType:          SecurityEventAuthRejected,
		Severity:           SecuritySeverityHigh,
		Category:           "auth",
		Escalation:         IncidentEscalationP2Urgent,
		ShouldAlert:        true,
		ShouldCreateTicket: true,
	}
}

func TestNewInMemorySecurityAlarmSink(t *testing.T) {
	sink := NewInMemorySecurityAlarmSink()
	if sink == nil {
		t.Fatal("expected sink")
	}
	if len(sink.Signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(sink.Signals))
	}
}

func TestSecurityAlarmSignal_Validate_Success(t *testing.T) {
	signal := SecurityAlarmSignal{
		EventType:          SecurityEventAuthRejected,
		Severity:           SecuritySeverityHigh,
		Category:           "auth",
		Escalation:         IncidentEscalationP2Urgent,
		ShouldAlert:        true,
		ShouldCreateTicket: true,
	}

	if err := signal.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestBuildSecurityAlarmSignal_Success(t *testing.T) {
	signal, err := BuildSecurityAlarmSignal(testIncidentDecision())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if signal.EventType != SecurityEventAuthRejected {
		t.Fatalf("expected %s, got %s", SecurityEventAuthRejected, signal.EventType)
	}
	if signal.Escalation != IncidentEscalationP2Urgent {
		t.Fatalf("expected %s, got %s", IncidentEscalationP2Urgent, signal.Escalation)
	}
	if !signal.ShouldAlert {
		t.Fatal("expected should alert")
	}
}

func TestBuildSecurityAlarmSignal_InvalidDecision(t *testing.T) {
	_, err := BuildSecurityAlarmSignal(IncidentReadinessDecision{})
	if err == nil {
		t.Fatal("expected invalid decision error")
	}
}

func TestEmitSecurityAlarmFromDecision_Success(t *testing.T) {
	sink := NewInMemorySecurityAlarmSink()

	err := EmitSecurityAlarmFromDecision(sink, testIncidentDecision())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(sink.Signals))
	}
	if sink.Signals[0].Category != "auth" {
		t.Fatalf("expected auth, got %s", sink.Signals[0].Category)
	}
}

func TestEmitSecurityAlarmFromDecision_NilSink(t *testing.T) {
	err := EmitSecurityAlarmFromDecision(nil, testIncidentDecision())
	if err == nil {
		t.Fatal("expected nil sink error")
	}
	if err != ErrSecurityAlarmSinkRequired {
		t.Fatalf("expected ErrSecurityAlarmSinkRequired, got %v", err)
	}
}
