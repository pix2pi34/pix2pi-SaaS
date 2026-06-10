package monitor

import (
	"testing"
	"time"
)

func testEarlyWarningSignal(
	signalType string,
	severity string,
	metricKey string,
) EarlyWarningSignal {
	return EarlyWarningSignal{
		SignalType:  signalType,
		Source:      "test-source",
		Severity:    severity,
		MetricKey:   metricKey,
		MetricValue: 1,
		Message:     "test signal",
		ObservedAt:  time.Now(),
	}
}

func TestScaleLevelUpDecision_Validate_Success(t *testing.T) {
	decision := ScaleLevelUpDecision{
		SignalType:        SignalTypeDatabasePressure,
		Severity:          EarlyWarningSeverityHigh,
		MetricKey:         DatabasePressureMetricConnectionUsagePct,
		RecommendedAction: ScaleActionDatabaseSplit,
		RequiresLevelUp:   true,
		Reason:            "database pressure requires db split decision",
	}

	if err := decision.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestBuildScaleLevelUpDecision_ServiceHealthHigh(t *testing.T) {
	decision, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			SignalTypeServiceHealth,
			EarlyWarningSeverityHigh,
			ServiceHealthMetricLatencyMs,
		),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.RequiresLevelUp {
		t.Fatal("expected requires level up")
	}
	if decision.RecommendedAction != ScaleActionServiceScale {
		t.Fatalf("expected %s, got %s", ScaleActionServiceScale, decision.RecommendedAction)
	}
}

func TestBuildScaleLevelUpDecision_DatabaseCritical(t *testing.T) {
	decision, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			SignalTypeDatabasePressure,
			EarlyWarningSeverityCritical,
			DatabasePressureMetricConnectionUsagePct,
		),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.RequiresLevelUp {
		t.Fatal("expected requires level up")
	}
	if decision.RecommendedAction != ScaleActionDatabaseSplit {
		t.Fatalf("expected %s, got %s", ScaleActionDatabaseSplit, decision.RecommendedAction)
	}
}

func TestBuildScaleLevelUpDecision_EventBacklogHigh(t *testing.T) {
	decision, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			SignalTypeEventBacklog,
			EarlyWarningSeverityHigh,
			EventBacklogMetricDepth,
		),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.RecommendedAction != ScaleActionEventBusUpgrade {
		t.Fatalf("expected %s, got %s", ScaleActionEventBusUpgrade, decision.RecommendedAction)
	}
}

func TestBuildScaleLevelUpDecision_ReportingHigh(t *testing.T) {
	decision, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			SignalTypeReportingLag,
			EarlyWarningSeverityHigh,
			ReportingPressureMetricProjectionLagSec,
		),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.RecommendedAction != ScaleActionReportingScale {
		t.Fatalf("expected %s, got %s", ScaleActionReportingScale, decision.RecommendedAction)
	}
}

func TestBuildScaleLevelUpDecision_InfraCritical(t *testing.T) {
	decision, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			SignalTypeInfraPressure,
			EarlyWarningSeverityCritical,
			InfraPressureMetricCPUUsagePct,
		),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.RecommendedAction != ScaleActionClusterTransition {
		t.Fatalf("expected %s, got %s", ScaleActionClusterTransition, decision.RecommendedAction)
	}
}

func TestBuildScaleLevelUpDecision_MediumObserveOnly(t *testing.T) {
	decision, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			SignalTypeDatabasePressure,
			EarlyWarningSeverityMedium,
			DatabasePressureMetricConnectionUsagePct,
		),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.RequiresLevelUp {
		t.Fatal("did not expect level up")
	}
	if decision.RecommendedAction != ScaleActionObserveOnly {
		t.Fatalf("expected %s, got %s", ScaleActionObserveOnly, decision.RecommendedAction)
	}
}

func TestBuildScaleLevelUpDecision_UnsupportedSignalType(t *testing.T) {
	_, err := BuildScaleLevelUpDecision(
		testEarlyWarningSignal(
			"unknown.signal",
			EarlyWarningSeverityHigh,
			"unknown_metric",
		),
	)
	if err == nil {
		t.Fatal("expected unsupported signal type error")
	}
	if err != ErrScaleDecisionUnsupportedSignalType {
		t.Fatalf("expected ErrScaleDecisionUnsupportedSignalType, got %v", err)
	}
}
