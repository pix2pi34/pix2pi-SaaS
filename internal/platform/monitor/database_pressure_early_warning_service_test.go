package monitor

import (
	"testing"
	"time"
)

func testHealthyDatabasePressureSnapshot() DatabasePressureSnapshot {
	return DatabasePressureSnapshot{
		Source:             "postgres-primary",
		ConnectionUsagePct: 45,
		SlowQueryRatioPct:  1,
		WriteLatencyMs:     30,
		ObservedAt:         time.Now(),
	}
}

func TestDatabasePressureSnapshot_Validate_Success(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()

	if err := snapshot.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestDatabasePressureSnapshot_Validate_MissingSource(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()
	snapshot.Source = ""

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrDatabasePressureSourceRequired {
		t.Fatalf("expected ErrDatabasePressureSourceRequired, got %v", err)
	}
}

func TestDatabasePressureSnapshot_Validate_NegativeConnectionUsage(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()
	snapshot.ConnectionUsagePct = -1

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected negative connection usage error")
	}
	if err != ErrDatabasePressureNegativeConnUsage {
		t.Fatalf("expected ErrDatabasePressureNegativeConnUsage, got %v", err)
	}
}

func TestDefaultDatabasePressureThresholdProfile(t *testing.T) {
	profile := DefaultDatabasePressureThresholdProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if profile.ConnectionUsagePolicy.MetricKey != DatabasePressureMetricConnectionUsagePct {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricConnectionUsagePct, profile.ConnectionUsagePolicy.MetricKey)
	}
	if profile.SlowQueryRatioPolicy.MetricKey != DatabasePressureMetricSlowQueryRatioPct {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricSlowQueryRatioPct, profile.SlowQueryRatioPolicy.MetricKey)
	}
	if profile.WriteLatencyPolicy.MetricKey != DatabasePressureMetricWriteLatencyMs {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricWriteLatencyMs, profile.WriteLatencyPolicy.MetricKey)
	}
}

func TestEvaluateDatabasePressureEarlyWarnings_NoSignal(t *testing.T) {
	signals, err := EvaluateDatabasePressureEarlyWarnings(
		testHealthyDatabasePressureSnapshot(),
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateDatabasePressureEarlyWarnings_ConnectionHigh(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()
	snapshot.ConnectionUsagePct = 93

	signals, err := EvaluateDatabasePressureEarlyWarnings(
		snapshot,
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

func TestEvaluateDatabasePressureEarlyWarnings_SlowQueryCritical(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()
	snapshot.SlowQueryRatioPct = 25

	signals, err := EvaluateDatabasePressureEarlyWarnings(
		snapshot,
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != DatabasePressureMetricSlowQueryRatioPct {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricSlowQueryRatioPct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, signals[0].Severity)
	}
}

func TestEvaluateDatabasePressureEarlyWarnings_WriteLatencyHigh(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()
	snapshot.WriteLatencyMs = 500

	signals, err := EvaluateDatabasePressureEarlyWarnings(
		snapshot,
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != DatabasePressureMetricWriteLatencyMs {
		t.Fatalf("expected %s, got %s", DatabasePressureMetricWriteLatencyMs, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateDatabasePressureEarlyWarnings_MultipleSignals(t *testing.T) {
	snapshot := testHealthyDatabasePressureSnapshot()
	snapshot.ConnectionUsagePct = 98
	snapshot.SlowQueryRatioPct = 12
	snapshot.WriteLatencyMs = 1200

	signals, err := EvaluateDatabasePressureEarlyWarnings(
		snapshot,
		DefaultDatabasePressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
