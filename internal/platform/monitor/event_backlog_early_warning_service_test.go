package monitor

import (
	"testing"
	"time"
)

func testHealthyEventBacklogSnapshot() EventBacklogSnapshot {
	return EventBacklogSnapshot{
		Source:        "nats-jetstream",
		BacklogDepth:  20,
		RetryRatioPct: 0.5,
		DLQDepth:      0,
		ObservedAt:    time.Now(),
	}
}

func TestEventBacklogSnapshot_Validate_Success(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()

	if err := snapshot.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestEventBacklogSnapshot_Validate_MissingSource(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()
	snapshot.Source = ""

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrEventBacklogSourceRequired {
		t.Fatalf("expected ErrEventBacklogSourceRequired, got %v", err)
	}
}

func TestEventBacklogSnapshot_Validate_NegativeDepth(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()
	snapshot.BacklogDepth = -1

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected negative depth error")
	}
	if err != ErrEventBacklogNegativeDepth {
		t.Fatalf("expected ErrEventBacklogNegativeDepth, got %v", err)
	}
}

func TestDefaultEventBacklogThresholdProfile(t *testing.T) {
	profile := DefaultEventBacklogThresholdProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if profile.BacklogDepthPolicy.MetricKey != EventBacklogMetricDepth {
		t.Fatalf("expected %s, got %s", EventBacklogMetricDepth, profile.BacklogDepthPolicy.MetricKey)
	}
	if profile.RetryRatioPolicy.MetricKey != EventBacklogMetricRetryRatioPct {
		t.Fatalf("expected %s, got %s", EventBacklogMetricRetryRatioPct, profile.RetryRatioPolicy.MetricKey)
	}
	if profile.DLQDepthPolicy.MetricKey != EventBacklogMetricDLQDepth {
		t.Fatalf("expected %s, got %s", EventBacklogMetricDLQDepth, profile.DLQDepthPolicy.MetricKey)
	}
}

func TestEvaluateEventBacklogEarlyWarnings_NoSignal(t *testing.T) {
	signals, err := EvaluateEventBacklogEarlyWarnings(
		testHealthyEventBacklogSnapshot(),
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateEventBacklogEarlyWarnings_BacklogHigh(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()
	snapshot.BacklogDepth = 2500

	signals, err := EvaluateEventBacklogEarlyWarnings(
		snapshot,
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != EventBacklogMetricDepth {
		t.Fatalf("expected %s, got %s", EventBacklogMetricDepth, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateEventBacklogEarlyWarnings_RetryCritical(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()
	snapshot.RetryRatioPct = 30

	signals, err := EvaluateEventBacklogEarlyWarnings(
		snapshot,
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != EventBacklogMetricRetryRatioPct {
		t.Fatalf("expected %s, got %s", EventBacklogMetricRetryRatioPct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, signals[0].Severity)
	}
}

func TestEvaluateEventBacklogEarlyWarnings_DLQHigh(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()
	snapshot.DLQDepth = 80

	signals, err := EvaluateEventBacklogEarlyWarnings(
		snapshot,
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != EventBacklogMetricDLQDepth {
		t.Fatalf("expected %s, got %s", EventBacklogMetricDLQDepth, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateEventBacklogEarlyWarnings_MultipleSignals(t *testing.T) {
	snapshot := testHealthyEventBacklogSnapshot()
	snapshot.BacklogDepth = 12000
	snapshot.RetryRatioPct = 12
	snapshot.DLQDepth = 250

	signals, err := EvaluateEventBacklogEarlyWarnings(
		snapshot,
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
