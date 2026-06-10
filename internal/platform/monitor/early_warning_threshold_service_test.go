package monitor

import "testing"

func TestEarlyWarningThresholdPolicy_Validate_HigherIsWorse_Success(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      100,
		MediumThreshold:   200,
		HighThreshold:     500,
		CriticalThreshold: 1000,
	}

	if err := policy.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestEarlyWarningThresholdPolicy_Validate_LowerIsWorse_Success(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "free_disk_pct",
		Direction:         ThresholdDirectionLowerIsWorse,
		LowThreshold:      30,
		MediumThreshold:   20,
		HighThreshold:     10,
		CriticalThreshold: 5,
	}

	if err := policy.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestEarlyWarningThresholdPolicy_Validate_InvalidDirection(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         "weird",
		LowThreshold:      100,
		MediumThreshold:   200,
		HighThreshold:     500,
		CriticalThreshold: 1000,
	}

	err := policy.Validate()
	if err == nil {
		t.Fatal("expected invalid direction error")
	}
	if err != ErrEarlyWarningThresholdDirectionRequired {
		t.Fatalf("expected ErrEarlyWarningThresholdDirectionRequired, got %v", err)
	}
}

func TestEarlyWarningThresholdPolicy_Validate_InvalidOrder_HigherIsWorse(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      100,
		MediumThreshold:   500,
		HighThreshold:     200,
		CriticalThreshold: 1000,
	}

	err := policy.Validate()
	if err == nil {
		t.Fatal("expected invalid order error")
	}
	if err != ErrEarlyWarningThresholdOrderInvalid {
		t.Fatalf("expected ErrEarlyWarningThresholdOrderInvalid, got %v", err)
	}
}

func TestEvaluateEarlyWarningThreshold_HigherIsWorse_Critical(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      100,
		MediumThreshold:   200,
		HighThreshold:     500,
		CriticalThreshold: 1000,
	}

	severity, matched, err := EvaluateEarlyWarningThreshold(policy, 1200)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !matched {
		t.Fatal("expected matched threshold")
	}
	if severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, severity)
	}
}

func TestEvaluateEarlyWarningThreshold_HigherIsWorse_High(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      100,
		MediumThreshold:   200,
		HighThreshold:     500,
		CriticalThreshold: 1000,
	}

	severity, matched, err := EvaluateEarlyWarningThreshold(policy, 650)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !matched {
		t.Fatal("expected matched threshold")
	}
	if severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, severity)
	}
}

func TestEvaluateEarlyWarningThreshold_HigherIsWorse_NoMatch(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      100,
		MediumThreshold:   200,
		HighThreshold:     500,
		CriticalThreshold: 1000,
	}

	severity, matched, err := EvaluateEarlyWarningThreshold(policy, 50)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if matched {
		t.Fatal("did not expect matched threshold")
	}
	if severity != "" {
		t.Fatalf("expected empty severity, got %s", severity)
	}
}

func TestEvaluateEarlyWarningThreshold_LowerIsWorse_Critical(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "free_disk_pct",
		Direction:         ThresholdDirectionLowerIsWorse,
		LowThreshold:      30,
		MediumThreshold:   20,
		HighThreshold:     10,
		CriticalThreshold: 5,
	}

	severity, matched, err := EvaluateEarlyWarningThreshold(policy, 4)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !matched {
		t.Fatal("expected matched threshold")
	}
	if severity != EarlyWarningSeverityCritical {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityCritical, severity)
	}
}

func TestEvaluateEarlyWarningThreshold_LowerIsWorse_NoMatch(t *testing.T) {
	policy := EarlyWarningThresholdPolicy{
		MetricKey:         "free_disk_pct",
		Direction:         ThresholdDirectionLowerIsWorse,
		LowThreshold:      30,
		MediumThreshold:   20,
		HighThreshold:     10,
		CriticalThreshold: 5,
	}

	severity, matched, err := EvaluateEarlyWarningThreshold(policy, 80)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if matched {
		t.Fatal("did not expect matched threshold")
	}
	if severity != "" {
		t.Fatalf("expected empty severity, got %s", severity)
	}
}

func TestDefaultServiceLatencyThresholdPolicy(t *testing.T) {
	policy := DefaultServiceLatencyThresholdPolicy()

	if policy.MetricKey != "service_latency_ms" {
		t.Fatalf("expected service_latency_ms, got %s", policy.MetricKey)
	}
	if policy.Direction != ThresholdDirectionHigherIsWorse {
		t.Fatalf("expected %s, got %s", ThresholdDirectionHigherIsWorse, policy.Direction)
	}
}
