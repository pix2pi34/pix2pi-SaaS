package monitor

import (
	"testing"
	"time"
)

func testRuntimeDatabasePressureInput() RuntimeDatabasePressureInput {
	return RuntimeDatabasePressureInput{
		Source:            "postgres-primary",
		MaxConnections:    100,
		ActiveConnections: 45,
		SlowQueryRatioPct: 1,
		WriteLatencyMs:    30,
		ObservedAt:        time.Now(),
	}
}

func TestRuntimeDatabasePressureInput_Validate_Success(t *testing.T) {
	input := testRuntimeDatabasePressureInput()

	if err := input.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeDatabasePressureInput_Validate_MissingSource(t *testing.T) {
	input := testRuntimeDatabasePressureInput()
	input.Source = ""

	err := input.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrDatabaseRuntimeSourceRequired {
		t.Fatalf("expected ErrDatabaseRuntimeSourceRequired, got %v", err)
	}
}

func TestRuntimeDatabasePressureInput_Validate_InvalidMaxConnections(t *testing.T) {
	input := testRuntimeDatabasePressureInput()
	input.MaxConnections = 0

	err := input.Validate()
	if err == nil {
		t.Fatal("expected invalid max connections error")
	}
	if err != ErrDatabaseRuntimeMaxConnectionsInvalid {
		t.Fatalf("expected ErrDatabaseRuntimeMaxConnectionsInvalid, got %v", err)
	}
}

func TestRuntimeDatabasePressureInput_Validate_InvalidActiveConnections(t *testing.T) {
	input := testRuntimeDatabasePressureInput()
	input.ActiveConnections = 101

	err := input.Validate()
	if err == nil {
		t.Fatal("expected invalid active connections error")
	}
	if err != ErrDatabaseRuntimeActiveConnectionsInvalid {
		t.Fatalf("expected ErrDatabaseRuntimeActiveConnectionsInvalid, got %v", err)
	}
}

func TestBuildRuntimeDatabasePressureSnapshot_Success(t *testing.T) {
	input := testRuntimeDatabasePressureInput()

	snapshot, err := BuildRuntimeDatabasePressureSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.Source != "postgres-primary" {
		t.Fatalf("expected postgres-primary, got %s", snapshot.Source)
	}
	if snapshot.ConnectionUsagePct != 45 {
		t.Fatalf("expected 45, got %v", snapshot.ConnectionUsagePct)
	}
}

func TestEvaluateRuntimeDatabasePressure_NoSignal(t *testing.T) {
	signals, err := EvaluateRuntimeDatabasePressure(
		testRuntimeDatabasePressureInput(),
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateRuntimeDatabasePressure_ConnectionHigh(t *testing.T) {
	input := testRuntimeDatabasePressureInput()
	input.ActiveConnections = 93

	signals, err := EvaluateRuntimeDatabasePressure(
		input,
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != DatabasePressureMetricConnectionUsagePct {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricConnectionUsagePct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateRuntimeDatabasePressure_MultipleSignals(t *testing.T) {
	input := testRuntimeDatabasePressureInput()
	input.ActiveConnections = 98
	input.SlowQueryRatioPct = 12
	input.WriteLatencyMs = 1200

	signals, err := EvaluateRuntimeDatabasePressure(
		input,
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
