package monitor

import (
	"testing"
	"time"
)

func testHealthyServiceSnapshot() ServiceHealthSnapshot {
	return ServiceHealthSnapshot{
		ServiceName:     "identity-api",
		ResponseTimeMs:  80,
		ErrorRatioPct:   0.5,
		UnhealthyStreak: 0,
		ObservedAt:      time.Now(),
	}
}

func TestServiceHealthSnapshot_Validate_Success(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()

	if err := snapshot.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestServiceHealthSnapshot_Validate_MissingName(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()
	snapshot.ServiceName = ""

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected missing service name error")
	}
	if err != ErrServiceHealthNameRequired {
		t.Fatalf("expected ErrServiceHealthNameRequired, got %v", err)
	}
}

func TestServiceHealthSnapshot_Validate_NegativeLatency(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()
	snapshot.ResponseTimeMs = -1

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected negative latency error")
	}
	if err != ErrServiceHealthNegativeLatency {
		t.Fatalf("expected ErrServiceHealthNegativeLatency, got %v", err)
	}
}

func TestDefaultServiceHealthThresholdProfile(t *testing.T) {
	profile := DefaultServiceHealthThresholdProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if profile.LatencyPolicy.MetricKey != ServiceHealthMetricLatencyMs {
		t.Fatalf("expected %s, got %s", ServiceHealthMetricLatencyMs, profile.LatencyPolicy.MetricKey)
	}
	if profile.ErrorRatioPolicy.MetricKey != ServiceHealthMetricErrorRatioPct {
		t.Fatalf("expected %s, got %s", ServiceHealthMetricErrorRatioPct, profile.ErrorRatioPolicy.MetricKey)
	}
	if profile.UnhealthyStreakPolicy.MetricKey != ServiceHealthMetricUnhealthyStreak {
		t.Fatalf("expected %s, got %s", ServiceHealthMetricUnhealthyStreak, profile.UnhealthyStreakPolicy.MetricKey)
	}
}

func TestEvaluateServiceHealthEarlyWarnings_NoSignal(t *testing.T) {
	signals, err := EvaluateServiceHealthEarlyWarnings(
		testHealthyServiceSnapshot(),
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateServiceHealthEarlyWarnings_LatencyHigh(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()
	snapshot.ResponseTimeMs = 900

	signals, err := EvaluateServiceHealthEarlyWarnings(
		snapshot,
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != ServiceHealthMetricLatencyMs {
		t.Fatalf("expected %s, got %s", ServiceHealthMetricLatencyMs, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateServiceHealthEarlyWarnings_ErrorRatioCritical(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()
	snapshot.ErrorRatioPct = 20

	signals, err := EvaluateServiceHealthEarlyWarnings(
		snapshot,
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != ServiceHealthMetricErrorRatioPct {
		t.Fatalf("expected %s, got %s", ServiceHealthMetricErrorRatioPct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, signals[0].Severity)
	}
}

func TestEvaluateServiceHealthEarlyWarnings_UnhealthyStreakHigh(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()
	snapshot.UnhealthyStreak = 3

	signals, err := EvaluateServiceHealthEarlyWarnings(
		snapshot,
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
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateServiceHealthEarlyWarnings_MultipleSignals(t *testing.T) {
	snapshot := testHealthyServiceSnapshot()
	snapshot.ResponseTimeMs = 1600
	snapshot.ErrorRatioPct = 9
	snapshot.UnhealthyStreak = 5

	signals, err := EvaluateServiceHealthEarlyWarnings(
		snapshot,
		DefaultServiceHealthThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
