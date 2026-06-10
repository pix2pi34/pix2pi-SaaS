package monitor

import (
	"testing"
	"time"

	securityservice "github.com/divrigili/pix2pi-SaaS/internal/platform/security/service"
)

func testSecurityAlarmSignal() securityservice.SecurityAlarmSignal {
	return securityservice.SecurityAlarmSignal{
		EventType:          securityservice.SecurityEventAuthRejected,
		Severity:           securityservice.SecuritySeverityHigh,
		Category:           "auth",
		Escalation:         securityservice.IncidentEscalationP2Urgent,
		ShouldAlert:        true,
		ShouldCreateTicket: true,
	}
}

func TestBuildObservabilityAlarmFromSecuritySignal_Success(t *testing.T) {
	record, err := BuildObservabilityAlarmFromSecuritySignal(
		testSecurityAlarmSignal(),
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if record.Kind != ObservabilityAlarmKindSecurityAlarm {
		t.Fatalf("expected %s, got %s", ObservabilityAlarmKindSecurityAlarm, record.Kind)
	}
	if record.SignalType != securityservice.SecurityEventAuthRejected {
		t.Fatalf("expected %s, got %s", securityservice.SecurityEventAuthRejected, record.SignalType)
	}
	if record.Source != "security.auth" {
		t.Fatalf("expected security.auth, got %s", record.Source)
	}
	if record.MetricKey != securityservice.IncidentEscalationP2Urgent {
		t.Fatalf("expected %s, got %s", securityservice.IncidentEscalationP2Urgent, record.MetricKey)
	}
}

func TestBuildObservabilityAlarmFromSecuritySignal_MissingObservedAt(t *testing.T) {
	_, err := BuildObservabilityAlarmFromSecuritySignal(
		testSecurityAlarmSignal(),
		time.Time{},
	)
	if err == nil {
		t.Fatal("expected missing observed at error")
	}
	if err != ErrObservabilityAlarmObservedAtRequired {
		t.Fatalf("expected ErrObservabilityAlarmObservedAtRequired, got %v", err)
	}
}

func TestEmitObservabilityAlarmFromSecuritySignal_Success(t *testing.T) {
	sink := NewInMemoryObservabilityAlarmSink()

	err := EmitObservabilityAlarmFromSecuritySignal(
		sink,
		testSecurityAlarmSignal(),
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Records) != 1 {
		t.Fatalf("expected 1 record, got %d", len(sink.Records))
	}
	if sink.Records[0].Kind != ObservabilityAlarmKindSecurityAlarm {
		t.Fatalf("expected %s, got %s", ObservabilityAlarmKindSecurityAlarm, sink.Records[0].Kind)
	}
}

func TestEmitOpsAndSecurityObservabilityAlarms_Success(t *testing.T) {
	sink := NewInMemoryObservabilityAlarmSink()

	opsSignals := []EarlyWarningSignal{
		{
			SignalType:  SignalTypeDatabasePressure,
			Source:      "postgres-primary",
			Severity:    EarlyWarningSeverityHigh,
			MetricKey:   DatabasePressureMetricConnectionUsagePct,
			MetricValue: 92,
			Message:     "postgres-primary: database connection usage pressure detected",
			ObservedAt:  time.Now(),
		},
	}

	securitySignals := []securityservice.SecurityAlarmSignal{
		testSecurityAlarmSignal(),
	}

	err := EmitOpsAndSecurityObservabilityAlarms(
		sink,
		opsSignals,
		securitySignals,
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Records) != 2 {
		t.Fatalf("expected 2 records, got %d", len(sink.Records))
	}
	if sink.Records[0].Kind != ObservabilityAlarmKindEarlyWarning {
		t.Fatalf("expected %s, got %s", ObservabilityAlarmKindEarlyWarning, sink.Records[0].Kind)
	}
	if sink.Records[1].Kind != ObservabilityAlarmKindSecurityAlarm {
		t.Fatalf("expected %s, got %s", ObservabilityAlarmKindSecurityAlarm, sink.Records[1].Kind)
	}
}

func TestEmitOpsAndSecurityObservabilityAlarms_NoSignals(t *testing.T) {
	sink := NewInMemoryObservabilityAlarmSink()

	err := EmitOpsAndSecurityObservabilityAlarms(
		sink,
		nil,
		nil,
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected no signals error")
	}
	if err != ErrObservabilityBridgeSignalsRequired {
		t.Fatalf("expected ErrObservabilityBridgeSignalsRequired, got %v", err)
	}
}

func TestEmitOpsAndSecurityObservabilityAlarms_NilSink(t *testing.T) {
	err := EmitOpsAndSecurityObservabilityAlarms(
		nil,
		[]EarlyWarningSignal{
			testObservabilityEarlyWarningSignal(),
		},
		nil,
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected nil sink error")
	}
	if err != ErrObservabilityAlarmSinkRequired {
		t.Fatalf("expected ErrObservabilityAlarmSinkRequired, got %v", err)
	}
}
