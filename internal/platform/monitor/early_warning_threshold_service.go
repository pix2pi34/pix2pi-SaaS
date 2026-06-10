package monitor

import (
	"errors"
	"strings"
)

var (
	ErrEarlyWarningThresholdMetricKeyRequired = errors.New("monitor: threshold metric key required")
	ErrEarlyWarningThresholdDirectionRequired = errors.New("monitor: threshold direction required")
	ErrEarlyWarningThresholdOrderInvalid      = errors.New("monitor: threshold order invalid")
)

const (
	ThresholdDirectionHigherIsWorse = "higher_is_worse"
	ThresholdDirectionLowerIsWorse  = "lower_is_worse"
)

type EarlyWarningThresholdPolicy struct {
	MetricKey         string
	Direction         string
	LowThreshold      float64
	MediumThreshold   float64
	HighThreshold     float64
	CriticalThreshold float64
}

func (p EarlyWarningThresholdPolicy) Validate() error {
	if strings.TrimSpace(p.MetricKey) == "" {
		return ErrEarlyWarningThresholdMetricKeyRequired
	}
	if strings.TrimSpace(p.Direction) == "" {
		return ErrEarlyWarningThresholdDirectionRequired
	}

	switch p.Direction {
	case ThresholdDirectionHigherIsWorse:
		if !(p.LowThreshold <= p.MediumThreshold &&
			p.MediumThreshold <= p.HighThreshold &&
			p.HighThreshold <= p.CriticalThreshold) {
			return ErrEarlyWarningThresholdOrderInvalid
		}

	case ThresholdDirectionLowerIsWorse:
		if !(p.CriticalThreshold <= p.HighThreshold &&
			p.HighThreshold <= p.MediumThreshold &&
			p.MediumThreshold <= p.LowThreshold) {
			return ErrEarlyWarningThresholdOrderInvalid
		}

	default:
		return ErrEarlyWarningThresholdDirectionRequired
	}

	return nil
}

func EvaluateEarlyWarningThreshold(
	policy EarlyWarningThresholdPolicy,
	value float64,
) (string, bool, error) {
	if err := policy.Validate(); err != nil {
		return "", false, err
	}

	switch policy.Direction {
	case ThresholdDirectionHigherIsWorse:
		switch {
		case value >= policy.CriticalThreshold:
			return EarlyWarningSeverityCritical, true, nil
		case value >= policy.HighThreshold:
			return EarlyWarningSeverityHigh, true, nil
		case value >= policy.MediumThreshold:
			return EarlyWarningSeverityMedium, true, nil
		case value >= policy.LowThreshold:
			return EarlyWarningSeverityLow, true, nil
		default:
			return "", false, nil
		}

	case ThresholdDirectionLowerIsWorse:
		switch {
		case value <= policy.CriticalThreshold:
			return EarlyWarningSeverityCritical, true, nil
		case value <= policy.HighThreshold:
			return EarlyWarningSeverityHigh, true, nil
		case value <= policy.MediumThreshold:
			return EarlyWarningSeverityMedium, true, nil
		case value <= policy.LowThreshold:
			return EarlyWarningSeverityLow, true, nil
		default:
			return "", false, nil
		}
	}

	return "", false, ErrEarlyWarningThresholdDirectionRequired
}

func DefaultServiceLatencyThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         "service_latency_ms",
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      150,
		MediumThreshold:   300,
		HighThreshold:     700,
		CriticalThreshold: 1500,
	}
}
