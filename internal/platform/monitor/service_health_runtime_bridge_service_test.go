package monitor

import (
	"testing"
	"time"
)

func testRuntimeServiceHealthInput() RuntimeServiceHealthInput {
	return RuntimeServiceHealthInput{
		ServiceName:         "identity-api",
		HealthCheckPassed:   true,
		ResponseTimeMs:      80,
		ErrorRatioPct:       0.5,
		ConsecutiveFailures: 0,
		ObservedAt:          time.Now(),
	}
}

func TestRuntimeServiceHealthInput_Validate_Success(t *testing.T) {
	input := testRuntimeServiceHealthInput()

	if err := input.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeServiceHealthInput_Validate_MissingName(t *testing.T) {
	input := testRuntimeServiceHealthInput()
	input.ServiceName = ""

	err := input.Validate()
	if err == nil {
		t.Fatal("expected missing service name error")
	}
	if err != ErrServiceHealthNameRequired {
		t.Fatalf("expected ErrServiceHealthNameRequired, got %v", err)
	}
}

func TestBuildRuntimeServiceHealthSnapshot_Success(t *testing.T) {
	input := testRuntimeServiceHealthInput()

	snapshot, err := BuildRuntimeServiceHealthSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.ServiceName != "identity-api" {
		t.Fatalf("expected identity-api, got %s", snapshot.ServiceName)
	}
	if snapshot.UnhealthyStreak != 0 {
		t.Fatalf("expected 0 unhealthy streak, got %d", snapshot.UnhealthyStreak)
	}
}

func TestBuildRuntimeServiceHealthSnapshot_FailClosedStreak(t *testing.T) {
	input := testRuntimeServiceHealthInput()
	input.HealthCheckPassed = false
	input.ConsecutiveFailures = 0

	snapshot, err := BuildRuntimeServiceHealthSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.UnhealthyStreak != 1 {
		t.Fatalf("expected fail-closed unhealthy streak 1, got %d", snapshot.UnhealthyStreak)
	}
}

func TestEvaluateRuntimeServiceHealth_NoSignal(t *testing.T) {
	signals, err := EvaluateRuntimeServiceHealth(
		testRuntimeServiceHealthInput(),
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateRuntimeServiceHealth_UnhealthyLowSignal(t *testing.T) {
	input := testRuntimeServiceHealthInput()
	input.HealthCheckPassed = false
	input.ConsecutiveFailures = 0

	signals, err := EvaluateRuntimeServiceHealth(
		input,
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != ServiceHealthMetricUnhealthyStreak {
		t.Fatalf("expected %s, got %s", ServiceHealthMetricUnhealthyStreak, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityLow {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityLow, signals[0].Severity)
	}
}

func TestEvaluateRuntimeServiceHealth_MultipleSignals(t *testing.T) {
	input := testRuntimeServiceHealthInput()
	input.HealthCheckPassed = false
	input.ResponseTimeMs = 1600
	input.ErrorRatioPct = 20
	input.ConsecutiveFailures = 5

	signals, err := EvaluateRuntimeServiceHealth(
		input,
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
