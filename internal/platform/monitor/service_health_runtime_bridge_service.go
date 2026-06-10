package monitor

import (
	"strings"
	"time"
)

type RuntimeServiceHealthInput struct {
	ServiceName         string
	HealthCheckPassed   bool
	ResponseTimeMs      float64
	ErrorRatioPct       float64
	ConsecutiveFailures int
	ObservedAt          time.Time
}

func (i RuntimeServiceHealthInput) Validate() error {
	if strings.TrimSpace(i.ServiceName) == "" {
		return ErrServiceHealthNameRequired
	}
	if i.ObservedAt.IsZero() {
		return ErrServiceHealthObservedAtRequired
	}
	if i.ResponseTimeMs < 0 {
		return ErrServiceHealthNegativeLatency
	}
	if i.ErrorRatioPct < 0 {
		return ErrServiceHealthNegativeErrorRatio
	}
	if i.ConsecutiveFailures < 0 {
		return ErrServiceHealthNegativeUnhealthyStreak
	}

	return nil
}

func BuildRuntimeServiceHealthSnapshot(
	input RuntimeServiceHealthInput,
) (ServiceHealthSnapshot, error) {
	if err := input.Validate(); err != nil {
		return ServiceHealthSnapshot{}, err
	}

	unhealthyStreak := input.ConsecutiveFailures

	if !input.HealthCheckPassed && unhealthyStreak == 0 {
		unhealthyStreak = 1
	}

	snapshot := ServiceHealthSnapshot{
		ServiceName:     strings.TrimSpace(input.ServiceName),
		ResponseTimeMs:  input.ResponseTimeMs,
		ErrorRatioPct:   input.ErrorRatioPct,
		UnhealthyStreak: unhealthyStreak,
		ObservedAt:      input.ObservedAt,
	}

	if err := snapshot.Validate(); err != nil {
		return ServiceHealthSnapshot{}, err
	}

	return snapshot, nil
}

func EvaluateRuntimeServiceHealth(
	input RuntimeServiceHealthInput,
	profile ServiceHealthThresholdProfile,
) ([]EarlyWarningSignal, error) {
	snapshot, err := BuildRuntimeServiceHealthSnapshot(input)
	if err != nil {
		return nil, err
	}

	return EvaluateServiceHealthEarlyWarnings(snapshot, profile)
}
