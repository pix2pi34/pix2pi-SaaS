package monitor

import (
	"testing"
	"time"
)

func testHealthyInfraPressureSnapshot() InfraPressureSnapshot {
	return InfraPressureSnapshot{
		Source:         "node-primary",
		CPUUsagePct:    35,
		MemoryUsagePct: 40,
		DiskUsagePct:   55,
		IOWaitPct:      2,
		ObservedAt:     time.Now(),
	}
}

func TestInfraPressureSnapshot_Validate_Success(t *testing.T) {
	snapshot := testHealthyInfraPressureSnapshot()

	if err := snapshot.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestInfraPressureSnapshot_Validate_MissingSource(t *testing.T) {
	snapshot := testHealthyInfraPressureSnapshot()
	snapshot.Source = ""

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrInfraPressureSourceRequired {
		t.Fatalf("expected ErrInfraPressureSourceRequired, got %v", err)
	}
}

func TestInfraPressureSnapshot_Validate_NegativeCPU(t *testing.T) {
	snapshot := testHealthyInfraPressureSnapshot()
	snapshot.CPUUsagePct = -1

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected negative cpu error")
	}
	if err != ErrInfraPressureNegativeCPUUsage {
		t.Fatalf("expected ErrInfraPressureNegativeCPUUsage, got %v", err)
	}
}

func TestDefaultInfraPressureThresholdProfile(t *testing.T) {
	profile := DefaultInfraPressureThresholdProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if profile.CPUUsagePolicy.MetricKey != InfraPressureMetricCPUUsagePct {
		t.Fatalf("expected %s, got %s", InfraPressureMetricCPUUsagePct, profile.CPUUsagePolicy.MetricKey)
	}
	if profile.MemoryUsagePolicy.MetricKey != InfraPressureMetricMemoryUsagePct {
		t.Fatalf("expected %s, got %s", InfraPressureMetricMemoryUsagePct, profile.MemoryUsagePolicy.MetricKey)
	}
	if profile.DiskUsagePolicy.MetricKey != InfraPressureMetricDiskUsagePct {
		t.Fatalf("expected %s, got %s", InfraPressureMetricDiskUsagePct, profile.DiskUsagePolicy.MetricKey)
	}
	if profile.IOWaitPolicy.MetricKey != InfraPressureMetricIOWaitPct {
		t.Fatalf("expected %s, got %s", InfraPressureMetricIOWaitPct, profile.IOWaitPolicy.MetricKey)
	}
}

func TestEvaluateInfraPressureEarlyWarnings_NoSignal(t *testing.T) {
	signals, err := EvaluateInfraPressureEarlyWarnings(
		testHealthyInfraPressureSnapshot(),
		DefaultInfraPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateInfraPressureEarlyWarnings_CPUHigh(t *testing.T) {
	snapshot := testHealthyInfraPressureSnapshot()
	snapshot.CPUUsagePct = 92

	signals, err := EvaluateInfraPressureEarlyWarnings(
		snapshot,
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

func TestEvaluateInfraPressureEarlyWarnings_MemoryCritical(t *testing.T) {
	snapshot := testHealthyInfraPressureSnapshot()
	snapshot.MemoryUsagePct = 98

	signals, err := EvaluateInfraPressureEarlyWarnings(
		snapshot,
		DefaultInfraPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != InfraPressureMetricMemoryUsagePct {
		t.Fatalf("expected %s, got %s", InfraPressureMetricMemoryUsagePct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, signals[0].Severity)
	}
}

func TestEvaluateInfraPressureEarlyWarnings_MultipleSignals(t *testing.T) {
	snapshot := testHealthyInfraPressureSnapshot()
	snapshot.CPUUsagePct = 98
	snapshot.MemoryUsagePct = 91
	snapshot.DiskUsagePct = 99
	snapshot.IOWaitPct = 25

	signals, err := EvaluateInfraPressureEarlyWarnings(
		snapshot,
		DefaultInfraPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 4 {
		t.Fatalf("expected 4 signals, got %d", len(signals))
	}
}
