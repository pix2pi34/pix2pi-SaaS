package monitor

import (
	"testing"
	"time"
)

func TestEarlyWarningSignal_Validate_Success(t *testing.T) {
	signal := EarlyWarningSignal{
		SignalType:  SignalTypeServiceHealth,
		Source:      "identity-api",
		Severity:    EarlyWarningSeverityMedium,
		MetricKey:   "error_ratio",
		MetricValue: 2.5,
		Message:     "service error ratio rising",
		ObservedAt:  time.Now(),
	}

	if err := signal.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestEarlyWarningSignal_Validate_MissingType(t *testing.T) {
	signal := EarlyWarningSignal{
		SignalType:  "",
		Source:      "identity-api",
		Severity:    EarlyWarningSeverityMedium,
		MetricKey:   "error_ratio",
		MetricValue: 2.5,
		Message:     "service error ratio rising",
		ObservedAt:  time.Now(),
	}

	err := signal.Validate()
	if err == nil {
		t.Fatal("expected missing signal type error")
	}
	if err != ErrEarlyWarningSignalTypeRequired {
		t.Fatalf("expected ErrEarlyWarningSignalTypeRequired, got %v", err)
	}
}

func TestEarlyWarningSignal_Validate_MissingSource(t *testing.T) {
	signal := EarlyWarningSignal{
		SignalType:  SignalTypeServiceHealth,
		Source:      "",
		Severity:    EarlyWarningSeverityMedium,
		MetricKey:   "error_ratio",
		MetricValue: 2.5,
		Message:     "service error ratio rising",
		ObservedAt:  time.Now(),
	}

	err := signal.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrEarlyWarningSourceRequired {
		t.Fatalf("expected ErrEarlyWarningSourceRequired, got %v", err)
	}
}

func TestEarlyWarningSignal_Validate_InvalidSeverity(t *testing.T) {
	signal := EarlyWarningSignal{
		SignalType:  SignalTypeServiceHealth,
		Source:      "identity-api",
		Severity:    "weird",
		MetricKey:   "error_ratio",
		MetricValue: 2.5,
		Message:     "service error ratio rising",
		ObservedAt:  time.Now(),
	}

	err := signal.Validate()
	if err == nil {
		t.Fatal("expected invalid severity error")
	}
	if err != ErrEarlyWarningSeverityRequired {
		t.Fatalf("expected ErrEarlyWarningSeverityRequired, got %v", err)
	}
}

func TestEarlyWarningSignal_Validate_MissingMetricKey(t *testing.T) {
	signal := EarlyWarningSignal{
		SignalType:  SignalTypeServiceHealth,
		Source:      "identity-api",
		Severity:    EarlyWarningSeverityMedium,
		MetricKey:   "",
		MetricValue: 2.5,
		Message:     "service error ratio rising",
		ObservedAt:  time.Now(),
	}

	err := signal.Validate()
	if err == nil {
		t.Fatal("expected missing metric key error")
	}
	if err != ErrEarlyWarningMetricKeyRequired {
		t.Fatalf("expected ErrEarlyWarningMetricKeyRequired, got %v", err)
	}
}

func TestEarlyWarningSignal_Validate_MissingObservedAt(t *testing.T) {
	signal := EarlyWarningSignal{
		SignalType:  SignalTypeServiceHealth,
		Source:      "identity-api",
		Severity:    EarlyWarningSeverityMedium,
		MetricKey:   "error_ratio",
		MetricValue: 2.5,
		Message:     "service error ratio rising",
	}

	err := signal.Validate()
	if err == nil {
		t.Fatal("expected missing observed at error")
	}
	if err != ErrEarlyWarningObservedAtRequired {
		t.Fatalf("expected ErrEarlyWarningObservedAtRequired, got %v", err)
	}
}

func TestNewEarlyWarningSignal_Success(t *testing.T) {
	signal, err := NewEarlyWarningSignal(
		SignalTypeDatabasePressure,
		"postgres-primary",
		EarlyWarningSeverityHigh,
		"connection_usage_pct",
		87.5,
		"db connection pressure rising",
		time.Now(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if signal.SignalType != SignalTypeDatabasePressure {
		t.Fatalf("expected %s, got %s", SignalTypeDatabasePressure, signal.SignalType)
	}
	if signal.Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signal.Severity)
	}
}
