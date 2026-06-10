package monitor

import (
	"testing"
	"time"
)

func testObservabilityEarlyWarningSignal() EarlyWarningSignal {
	return EarlyWarningSignal{
		SignalType:  SignalTypeDatabasePressure,
		Source:      "postgres-primary",
		Severity:    EarlyWarningSeverityHigh,
		MetricKey:   DatabasePressureMetricConnectionUsagePct,
		MetricValue: 92,
		Message:     "postgres-primary: database connection usage pressure detected",
		ObservedAt:  time.Now(),
	}
}

func TestObservabilityAlarmRecord_Validate_Success(t *testing.T) {
	record := ObservabilityAlarmRecord{
		Kind:       ObservabilityAlarmKindEarlyWarning,
		SignalType: SignalTypeDatabasePressure,
		Source:     "postgres-primary",
		Severity:   EarlyWarningSeverityHigh,
		MetricKey:  DatabasePressureMetricConnectionUsagePct,
		Message:    "db pressure detected",
		ObservedAt: time.Now(),
	}

	if err := record.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestObservabilityAlarmRecord_Validate_MissingKind(t *testing.T) {
	record := ObservabilityAlarmRecord{
		Kind:       "",
		SignalType: SignalTypeDatabasePressure,
		Source:     "postgres-primary",
		Severity:   EarlyWarningSeverityHigh,
		MetricKey:  DatabasePressureMetricConnectionUsagePct,
		Message:    "db pressure detected",
		ObservedAt: time.Now(),
	}

	err := record.Validate()
	if err == nil {
		t.Fatal("expected missing kind error")
	}
	if err != ErrObservabilityAlarmKindRequired {
		t.Fatalf("expected ErrObservabilityAlarmKindRequired, got %v", err)
	}
}

func TestBuildObservabilityAlarmFromEarlyWarning_Success(t *testing.T) {
	record, err := BuildObservabilityAlarmFromEarlyWarning(
		testObservabilityEarlyWarningSignal(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if record.Kind != ObservabilityAlarmKindEarlyWarning {
		t.Fatalf("expected %s, got %s", ObservabilityAlarmKindEarlyWarning, record.Kind)
	}
	if record.SignalType != SignalTypeDatabasePressure {
		t.Fatalf("expected %s, got %s", SignalTypeDatabasePressure, record.SignalType)
	}
	if record.Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, record.Severity)
	}
}

func TestNewInMemoryObservabilityAlarmSink(t *testing.T) {
	sink := NewInMemoryObservabilityAlarmSink()
	if sink == nil {
		t.Fatal("expected sink")
	}
	if len(sink.Records) != 0 {
		t.Fatalf("expected 0 records, got %d", len(sink.Records))
	}
}

func TestEmitObservabilityAlarmFromEarlyWarning_Success(t *testing.T) {
	sink := NewInMemoryObservabilityAlarmSink()

	err := EmitObservabilityAlarmFromEarlyWarning(
		sink,
		testObservabilityEarlyWarningSignal(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(sink.Records) != 1 {
		t.Fatalf("expected 1 record, got %d", len(sink.Records))
	}
	if sink.Records[0].MetricKey != DatabasePressureMetricConnectionUsagePct {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricConnectionUsagePct, sink.Records[0].MetricKey)
	}
}

func TestEmitObservabilityAlarmFromEarlyWarning_NilSink(t *testing.T) {
	err := EmitObservabilityAlarmFromEarlyWarning(
		nil,
		testObservabilityEarlyWarningSignal(),
	)
	if err == nil {
		t.Fatal("expected nil sink error")
	}
	if err != ErrObservabilityAlarmSinkRequired {
		t.Fatalf("expected ErrObservabilityAlarmSinkRequired, got %v", err)
	}
}
