package monitor

import (
	"testing"
	"time"
)

func testRuntimeReportingPressureInput() RuntimeReportingPressureInput {
	return RuntimeReportingPressureInput{
		Source:            "readmodel-subscriber",
		ProjectionLagSec:  1,
		RebuildQueueDepth: 0,
		QueryLoadPct:      20,
		ObservedAt:        time.Now(),
	}
}

func TestRuntimeReportingPressureInput_Validate_Success(t *testing.T) {
	input := testRuntimeReportingPressureInput()

	if err := input.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeReportingPressureInput_Validate_MissingSource(t *testing.T) {
	input := testRuntimeReportingPressureInput()
	input.Source = ""

	err := input.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrReportingRuntimeSourceRequired {
		t.Fatalf("expected ErrReportingRuntimeSourceRequired, got %v", err)
	}
}

func TestRuntimeReportingPressureInput_Validate_NegativeProjectionLag(t *testing.T) {
	input := testRuntimeReportingPressureInput()
	input.ProjectionLagSec = -1

	err := input.Validate()
	if err == nil {
		t.Fatal("expected negative projection lag error")
	}
	if err != ErrReportingRuntimeNegativeProjectionLag {
		t.Fatalf("expected ErrReportingRuntimeNegativeProjectionLag, got %v", err)
	}
}

func TestRuntimeReportingPressureInput_Validate_NegativeRebuildQueue(t *testing.T) {
	input := testRuntimeReportingPressureInput()
	input.RebuildQueueDepth = -1

	err := input.Validate()
	if err == nil {
		t.Fatal("expected negative rebuild queue error")
	}
	if err != ErrReportingRuntimeNegativeRebuildQueue {
		t.Fatalf("expected ErrReportingRuntimeNegativeRebuildQueue, got %v", err)
	}
}

func TestBuildRuntimeReportingPressureSnapshot_Success(t *testing.T) {
	input := testRuntimeReportingPressureInput()

	snapshot, err := BuildRuntimeReportingPressureSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.Source != "readmodel-subscriber" {
		t.Fatalf("expected readmodel-subscriber, got %s", snapshot.Source)
	}
	if snapshot.ProjectionLagSec != 1 {
		t.Fatalf("expected 1, got %v", snapshot.ProjectionLagSec)
	}
	if snapshot.QueryLoadPct != 20 {
		t.Fatalf("expected 20, got %v", snapshot.QueryLoadPct)
	}
}

func TestEvaluateRuntimeReportingPressure_NoSignal(t *testing.T) {
	signals, err := EvaluateRuntimeReportingPressure(
		testRuntimeReportingPressureInput(),
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateRuntimeReportingPressure_ProjectionLagHigh(t *testing.T) {
	input := testRuntimeReportingPressureInput()
	input.ProjectionLagSec = 80

	signals, err := EvaluateRuntimeReportingPressure(
		input,
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

func TestEvaluateRuntimeReportingPressure_MultipleSignals(t *testing.T) {
	input := testRuntimeReportingPressureInput()
	input.ProjectionLagSec = 220
	input.RebuildQueueDepth = 30
	input.QueryLoadPct = 97

	signals, err := EvaluateRuntimeReportingPressure(
		input,
		DefaultReportingPressureThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
