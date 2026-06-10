package monitor

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrEarlyWarningSignalTypeRequired = errors.New("monitor: early warning signal type required")
	ErrEarlyWarningSourceRequired     = errors.New("monitor: early warning source required")
	ErrEarlyWarningSeverityRequired   = errors.New("monitor: early warning severity required")
	ErrEarlyWarningMetricKeyRequired  = errors.New("monitor: early warning metric key required")
	ErrEarlyWarningObservedAtRequired = errors.New("monitor: early warning observed at required")
)

const (
	EarlyWarningSeverityLow      = "low"
	EarlyWarningSeverityMedium   = "medium"
	EarlyWarningSeverityHigh     = "high"
	EarlyWarningSeverityCritical = "critical"
)

const (
	SignalTypeServiceHealth   = "service.health"
	SignalTypeDatabasePressure = "database.pressure"
	SignalTypeEventBacklog    = "event.backlog"
	SignalTypeReportingLag    = "reporting.lag"
	SignalTypeInfraPressure   = "infra.pressure"
	SignalTypeScaleDecision   = "scale.decision"
)

type EarlyWarningSignal struct {
	SignalType  string
	Source      string
	Severity    string
	MetricKey   string
	MetricValue float64
	Message     string
	ObservedAt  time.Time
}

func (s EarlyWarningSignal) Validate() error {
	if strings.TrimSpace(s.SignalType) == "" {
		return ErrEarlyWarningSignalTypeRequired
	}
	if strings.TrimSpace(s.Source) == "" {
		return ErrEarlyWarningSourceRequired
	}
	if strings.TrimSpace(s.Severity) == "" {
		return ErrEarlyWarningSeverityRequired
	}
	if strings.TrimSpace(s.MetricKey) == "" {
		return ErrEarlyWarningMetricKeyRequired
	}
	if s.ObservedAt.IsZero() {
		return ErrEarlyWarningObservedAtRequired
	}

	switch s.Severity {
	case EarlyWarningSeverityLow,
		EarlyWarningSeverityMedium,
		EarlyWarningSeverityHigh,
		EarlyWarningSeverityCritical:
	default:
		return ErrEarlyWarningSeverityRequired
	}

	return nil
}

func NewEarlyWarningSignal(
	signalType string,
	source string,
	severity string,
	metricKey string,
	metricValue float64,
	message string,
	observedAt time.Time,
) (EarlyWarningSignal, error) {
	signal := EarlyWarningSignal{
		SignalType:  strings.TrimSpace(signalType),
		Source:      strings.TrimSpace(source),
		Severity:    strings.TrimSpace(severity),
		MetricKey:   strings.TrimSpace(metricKey),
		MetricValue: metricValue,
		Message:     strings.TrimSpace(message),
		ObservedAt:  observedAt,
	}

	if err := signal.Validate(); err != nil {
		return EarlyWarningSignal{}, err
	}

	return signal, nil
}
