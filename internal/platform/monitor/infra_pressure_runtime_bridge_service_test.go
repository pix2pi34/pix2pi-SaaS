package monitor

import (
	"testing"
	"time"
)

func testRuntimeInfraPressureInput() RuntimeInfraPressureInput {
	return RuntimeInfraPressureInput{
		Source:         "node-primary",
		CPUUsagePct:    35,
		MemoryUsagePct: 40,
		DiskUsagePct:   55,
		IOWaitPct:      2,
		ObservedAt:     time.Now(),
	}
}

func TestRuntimeInfraPressureInput_Validate_Success(t *testing.T) {
	input := testRuntimeInfraPressureInput()

	if err := input.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeInfraPressureInput_Validate_MissingSource(t *testing.T) {
	input := testRuntimeInfraPressureInput()
	input.Source = ""

	err := input.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrInfraRuntimeSourceRequired {
		t.Fatalf("expected ErrInfraRuntimeSourceRequired, got %v", err)
	}
}

func TestRuntimeInfraPressureInput_Validate_NegativeCPU(t *testing.T) {
	input := testRuntimeInfraPressureInput()
	input.CPUUsagePct = -1

	err := input.Validate()
	if err == nil {
		t.Fatal("expected negative cpu error")
	}
	if err != ErrInfraRuntimeNegativeCPUUsage {
		t.Fatalf("expected ErrInfraRuntimeNegativeCPUUsage, got %v", err)
	}
}

func TestRuntimeInfraPressureInput_Validate_NegativeMemory(t *testing.T) {
	input := testRuntimeInfraPressureInput()
	input.MemoryUsagePct = -1

	err := input.Validate()
	if err == nil {
		t.Fatal("expected negative memory error")
	}
	if err != ErrInfraRuntimeNegativeMemoryUsage {
		t.Fatalf("expected ErrInfraRuntimeNegativeMemoryUsage, got %v", err)
	}
}

func TestBuildRuntimeInfraPressureSnapshot_Success(t *testing.T) {
	input := testRuntimeInfraPressureInput()

	snapshot, err := BuildRuntimeInfraPressureSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.Source != "node-primary" {
		t.Fatalf("expected node-primary, got %s", snapshot.Source)
	}
	if snapshot.CPUUsagePct != 35 {
		t.Fatalf("expected 35, got %v", snapshot.CPUUsagePct)
	}
	if snapshot.MemoryUsagePct != 40 {
		t.Fatalf("expected 40, got %v", snapshot.MemoryUsagePct)
	}
}

func TestEvaluateRuntimeInfraPressure_NoSignal(t *testing.T) {
	signals, err := EvaluateRuntimeInfraPressure(
		testRuntimeInfraPressureInput(),
		DefaultInfraPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateRuntimeInfraPressure_CPUHigh(t *testing.T) {
	input := testRuntimeInfraPressureInput()
	input.CPUUsagePct = 92

	signals, err := EvaluateRuntimeInfraPressure(
		input,
		DefaultInfraPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != InfraPressureMetricCPUUsagePct {
		t.Fatalf("expected %s, got %s", InfraPressureMetricCPUUsagePct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateRuntimeInfraPressure_MultipleSignals(t *testing.T) {
	input := testRuntimeInfraPressureInput()
	input.CPUUsagePct = 98
	input.MemoryUsagePct = 91
	input.DiskUsagePct = 99
	input.IOWaitPct = 25

	signals, err := EvaluateRuntimeInfraPressure(
		input,
		DefaultInfraPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 4 {
		t.Fatalf("expected 4 signals, got %d", len(signals))
	}
}
