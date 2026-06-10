package monitor

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrServiceHealthNameRequired          = errors.New("monitor: service health service name required")
	ErrServiceHealthObservedAtRequired    = errors.New("monitor: service health observed at required")
	ErrServiceHealthNegativeLatency       = errors.New("monitor: service health latency cannot be negative")
	ErrServiceHealthNegativeErrorRatio    = errors.New("monitor: service health error ratio cannot be negative")
	ErrServiceHealthNegativeUnhealthyStreak = errors.New("monitor: service health unhealthy streak cannot be negative")
)

const (
	ServiceHealthMetricLatencyMs      = "service_latency_ms"
	ServiceHealthMetricErrorRatioPct  = "service_error_ratio_pct"
	ServiceHealthMetricUnhealthyStreak = "service_unhealthy_streak"
)

type ServiceHealthSnapshot struct {
	ServiceName      string
	ResponseTimeMs   float64
	ErrorRatioPct    float64
	UnhealthyStreak  int
	ObservedAt       time.Time
}

func (s ServiceHealthSnapshot) Validate() error {
	if strings.TrimSpace(s.ServiceName) == "" {
		return ErrServiceHealthNameRequired
	}
	if s.ObservedAt.IsZero() {
		return ErrServiceHealthObservedAtRequired
	}
	if s.ResponseTimeMs < 0 {
		return ErrServiceHealthNegativeLatency
	}
	if s.ErrorRatioPct < 0 {
		return ErrServiceHealthNegativeErrorRatio
	}
	if s.UnhealthyStreak < 0 {
		return ErrServiceHealthNegativeUnhealthyStreak
	}

	return nil
}

type ServiceHealthThresholdProfile struct {
	LatencyPolicy         EarlyWarningThresholdPolicy
	ErrorRatioPolicy      EarlyWarningThresholdPolicy
	UnhealthyStreakPolicy EarlyWarningThresholdPolicy
}

func (p ServiceHealthThresholdProfile) Validate() error {
	if err := p.LatencyPolicy.Validate(); err != nil {
		return err
	}
	if err := p.ErrorRatioPolicy.Validate(); err != nil {
		return err
	}
	if err := p.UnhealthyStreakPolicy.Validate(); err != nil {
		return err
	}

	return nil
}

func DefaultServiceErrorRatioThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         ServiceHealthMetricErrorRatioPct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      1,
		MediumThreshold:   3,
		HighThreshold:     7,
		CriticalThreshold: 15,
	}
}

func DefaultServiceUnhealthyStreakThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         ServiceHealthMetricUnhealthyStreak,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      1,
		MediumThreshold:   2,
		HighThreshold:     3,
		CriticalThreshold: 5,
	}
}

func DefaultServiceHealthThresholdProfile() ServiceHealthThresholdProfile {
	return ServiceHealthThresholdProfile{
		LatencyPolicy:         DefaultServiceLatencyThresholdPolicy(),
		ErrorRatioPolicy:      DefaultServiceErrorRatioThresholdPolicy(),
		UnhealthyStreakPolicy: DefaultServiceUnhealthyStreakThresholdPolicy(),
	}
}

func EvaluateServiceHealthEarlyWarnings(
	snapshot ServiceHealthSnapshot,
	profile ServiceHealthThresholdProfile,
) ([]EarlyWarningSignal, error) {
	if err := snapshot.Validate(); err != nil {
		return nil, err
	}
	if err := profile.Validate(); err != nil {
		return nil, err
	}

	signals := make([]EarlyWarningSignal, 0)

	latencySignal, ok, err := buildServiceHealthSignal(
		snapshot,
		profile.LatencyPolicy,
		snapshot.ResponseTimeMs,
		"service latency pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, latencySignal)
	}

	errorRatioSignal, ok, err := buildServiceHealthSignal(
		snapshot,
		profile.ErrorRatioPolicy,
		snapshot.ErrorRatioPct,
		"service error ratio pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, errorRatioSignal)
	}

	unhealthySignal, ok, err := buildServiceHealthSignal(
		snapshot,
		profile.UnhealthyStreakPolicy,
		float64(snapshot.UnhealthyStreak),
		"service unhealthy streak detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, unhealthySignal)
	}

	return signals, nil
}

func buildServiceHealthSignal(
	snapshot ServiceHealthSnapshot,
	policy EarlyWarningThresholdPolicy,
	value float64,
	message string,
) (EarlyWarningSignal, bool, error) {
	severity, matched, err := EvaluateEarlyWarningThreshold(policy, value)
	if err != nil {
		return EarlyWarningSignal{}, false, err
	}
	if !matched {
		return EarlyWarningSignal{}, false, nil
	}

	signal, err := NewEarlyWarningSignal(
		SignalTypeServiceHealth,
		snapshot.ServiceName,
		severity,
		policy.MetricKey,
		value,
		fmt.Sprintf("%s: %s", snapshot.ServiceName, message),
		snapshot.ObservedAt,
	)
	if err != nil {
		return EarlyWarningSignal{}, false, err
	}

	return signal, true, nil
}
