package monitor

import (
	"testing"
	"time"
)

func testHealthyReportingPressureSnapshot() ReportingPressureSnapshot {
	return ReportingPressureSnapshot{
		Source:            "readmodel-subscriber",
		ProjectionLagSec:  1,
		RebuildQueueDepth: 0,
		QueryLoadPct:      20,
		ObservedAt:        time.Now(),
	}
}

func TestReportingPressureSnapshot_Validate_Success(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()

	if err := snapshot.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestReportingPressureSnapshot_Validate_MissingSource(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()
	snapshot.Source = ""

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrReportingPressureSourceRequired {
		t.Fatalf("expected ErrReportingPressureSourceRequired, got %v", err)
	}
}

func TestReportingPressureSnapshot_Validate_NegativeProjectionLag(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()
	snapshot.ProjectionLagSec = -1

	err := snapshot.Validate()
	if err == nil {
		t.Fatal("expected negative projection lag error")
	}
	if err != ErrReportingPressureNegativeProjectionLag {
		t.Fatalf("expected ErrReportingPressureNegativeProjectionLag, got %v", err)
	}
}

func TestDefaultReportingPressureThresholdProfile(t *testing.T) {
	profile := DefaultReportingPressureThresholdProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if profile.ProjectionLagPolicy.MetricKey != ReportingPressureMetricProjectionLagSec {
		t.Fatalf("expected %s, got %s", ReportingPressureMetricProjectionLagSec, profile.ProjectionLagPolicy.MetricKey)
	}
	if profile.RebuildQueuePolicy.MetricKey != ReportingPressureMetricRebuildQueueDepth {
		t.Fatalf("expected %s, got %s", ReportingPressureMetricRebuildQueueDepth, profile.RebuildQueuePolicy.MetricKey)
	}
	if profile.QueryLoadPolicy.MetricKey != ReportingPressureMetricQueryLoadPct {
		t.Fatalf("expected %s, got %s", ReportingPressureMetricQueryLoadPct, profile.QueryLoadPolicy.MetricKey)
	}
}

func TestEvaluateReportingPressureEarlyWarnings_NoSignal(t *testing.T) {
	signals, err := EvaluateReportingPressureEarlyWarnings(
		testHealthyReportingPressureSnapshot(),
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateReportingPressureEarlyWarnings_ProjectionLagHigh(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()
	snapshot.ProjectionLagSec = 80

	signals, err := EvaluateReportingPressureEarlyWarnings(
		snapshot,
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != ReportingPressureMetricProjectionLagSec {
		t.Fatalf("expected %s, got %s", ReportingPressureMetricProjectionLagSec, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateReportingPressureEarlyWarnings_RebuildQueueCritical(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()
	snapshot.RebuildQueueDepth = 120

	signals, err := EvaluateReportingPressureEarlyWarnings(
		snapshot,
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != ReportingPressureMetricRebuildQueueDepth {
		t.Fatalf("expected %s, got %s", ReportingPressureMetricRebuildQueueDepth, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, signals[0].Severity)
	}
}

func TestEvaluateReportingPressureEarlyWarnings_QueryLoadHigh(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()
	snapshot.QueryLoadPct = 85

	signals, err := EvaluateReportingPressureEarlyWarnings(
		snapshot,
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != ReportingPressureMetricQueryLoadPct {
		t.Fatalf("expected %s, got %s", ReportingPressureMetricQueryLoadPct, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateReportingPressureEarlyWarnings_MultipleSignals(t *testing.T) {
	snapshot := testHealthyReportingPressureSnapshot()
	snapshot.ProjectionLagSec = 220
	snapshot.RebuildQueueDepth = 30
	snapshot.QueryLoadPct = 97

	signals, err := EvaluateReportingPressureEarlyWarnings(
		snapshot,
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
