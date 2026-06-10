package monitor

import (
	"testing"
	"time"
)

func testMatrixSignal(
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

func TestScaleLevelUpMatrixResult_Validate_Success(t *testing.T) {
	result := ScaleLevelUpMatrixResult{
		RequiresLevelUp:    true,
		HighestSeverity:    EarlyWarningSeverityCritical,
		RecommendedActions: []string{ScaleActionClusterTransition},
		Decisions: []ScaleLevelUpDecision{
			{
				SignalType:        SignalTypeInfraPressure,
				Severity:          EarlyWarningSeverityCritical,
				MetricKey:         InfraPressureMetricCPUUsagePct,
				RecommendedAction: ScaleActionClusterTransition,
				RequiresLevelUp:   true,
				Reason:            "infra pressure requires cluster transition decision",
			},
		},
	}

	if err := result.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestBuildScaleLevelUpMatrix_EmptySignals(t *testing.T) {
	_, err := BuildScaleLevelUpMatrix(nil)
	if err == nil {
		t.Fatal("expected empty signals error")
	}
	if err != ErrScaleLevelUpMatrixSignalsRequired {
		t.Fatalf("expected ErrScaleLevelUpMatrixSignalsRequired, got %v", err)
	}
}

func TestBuildScaleLevelUpMatrix_ObserveOnly(t *testing.T) {
	result, err := BuildScaleLevelUpMatrix([]EarlyWarningSignal{
		testMatrixSignal(
			SignalTypeDatabasePressure,
			EarlyWarningSeverityMedium,
			DatabasePressureMetricConnectionUsagePct,
		),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.RequiresLevelUp {
		t.Fatal("did not expect level up")
	}
	if result.HighestSeverity != EarlyWarningSeverityMedium {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityMedium, result.HighestSeverity)
	}
	if len(result.RecommendedActions) != 1 {
		t.Fatalf("expected 1 action, got %d", len(result.RecommendedActions))
	}
	if result.RecommendedActions[0] != ScaleActionObserveOnly {
		t.Fatalf("expected %s, got %s", ScaleActionObserveOnly, result.RecommendedActions[0])
	}
}

func TestBuildScaleLevelUpMatrix_MultipleSignals(t *testing.T) {
	result, err := BuildScaleLevelUpMatrix([]EarlyWarningSignal{
		testMatrixSignal(
			SignalTypeDatabasePressure,
			EarlyWarningSeverityHigh,
			DatabasePressureMetricConnectionUsagePct,
		),
		testMatrixSignal(
			SignalTypeEventBacklog,
			EarlyWarningSeverityHigh,
			EventBacklogMetricDepth,
		),
		testMatrixSignal(
			SignalTypeInfraPressure,
			EarlyWarningSeverityCritical,
			InfraPressureMetricCPUUsagePct,
		),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.RequiresLevelUp {
		t.Fatal("expected requires level up")
	}
	if result.HighestSeverity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, result.HighestSeverity)
	}
	if len(result.Decisions) != 3 {
		t.Fatalf("expected 3 decisions, got %d", len(result.Decisions))
	}
	if len(result.RecommendedActions) != 3 {
		t.Fatalf("expected 3 actions, got %d", len(result.RecommendedActions))
	}
}

func TestBuildScaleLevelUpMatrix_DeduplicatesActions(t *testing.T) {
	result, err := BuildScaleLevelUpMatrix([]EarlyWarningSignal{
		testMatrixSignal(
			SignalTypeServiceHealth,
			EarlyWarningSeverityHigh,
			ServiceHealthMetricLatencyMs,
		),
		testMatrixSignal(
			SignalTypeServiceHealth,
			EarlyWarningSeverityCritical,
			ServiceHealthMetricErrorRatioPct,
		),
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(result.RecommendedActions) != 1 {
		t.Fatalf("expected 1 action, got %d", len(result.RecommendedActions))
	}
	if result.RecommendedActions[0] != ScaleActionServiceScale {
		t.Fatalf("expected %s, got %s", ScaleActionServiceScale, result.RecommendedActions[0])
	}
}

func TestBuildScaleLevelUpMatrix_UnsupportedSignal(t *testing.T) {
	_, err := BuildScaleLevelUpMatrix([]EarlyWarningSignal{
		testMatrixSignal(
			"unknown.signal",
			EarlyWarningSeverityHigh,
			"unknown_metric",
		),
	})
	if err == nil {
		t.Fatal("expected unsupported signal error")
	}
	if err != ErrScaleDecisionUnsupportedSignalType {
		t.Fatalf("expected ErrScaleDecisionUnsupportedSignalType, got %v", err)
	}
}
