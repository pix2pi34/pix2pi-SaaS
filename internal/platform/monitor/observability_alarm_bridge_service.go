package monitor

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrObservabilityAlarmKindRequired       = errors.New("monitor: observability alarm kind required")
	ErrObservabilityAlarmSourceRequired     = errors.New("monitor: observability alarm source required")
	ErrObservabilityAlarmSeverityRequired   = errors.New("monitor: observability alarm severity required")
	ErrObservabilityAlarmObservedAtRequired = errors.New("monitor: observability alarm observed at required")
	ErrObservabilityAlarmSinkRequired       = errors.New("monitor: observability alarm sink required")
)

const (
	ObservabilityAlarmKindEarlyWarning = "early_warning"
)

type ObservabilityAlarmRecord struct {
	Kind       string
	SignalType string
	Source     string
	Severity   string
	MetricKey  string
	Message    string
	ObservedAt time.Time
}

func (r ObservabilityAlarmRecord) Validate() error {
	if strings.TrimSpace(r.Kind) == "" {
		return ErrObservabilityAlarmKindRequired
	}
	if strings.TrimSpace(r.Source) == "" {
		return ErrObservabilityAlarmSourceRequired
	}
	if strings.TrimSpace(r.Severity) == "" {
		return ErrObservabilityAlarmSeverityRequired
	}
	if r.ObservedAt.IsZero() {
		return ErrObservabilityAlarmObservedAtRequired
	}

	switch r.Severity {
	case EarlyWarningSeverityLow,
		EarlyWarningSeverityMedium,
		EarlyWarningSeverityHigh,
		EarlyWarningSeverityCritical:
	default:
		return ErrObservabilityAlarmSeverityRequired
	}

	return nil
}

type ObservabilityAlarmSink interface {
	PublishObservabilityAlarm(record ObservabilityAlarmRecord) error
}

type InMemoryObservabilityAlarmSink struct {
	Records []ObservabilityAlarmRecord
}

func NewInMemoryObservabilityAlarmSink() *InMemoryObservabilityAlarmSink {
	return &InMemoryObservabilityAlarmSink{
		Records: make([]ObservabilityAlarmRecord, 0),
	}
}

func (s *InMemoryObservabilityAlarmSink) PublishObservabilityAlarm(
	record ObservabilityAlarmRecord,
) error {
	if s == nil {
		return ErrObservabilityAlarmSinkRequired
	}

	s.Records = append(s.Records, record)
	return nil
}

func BuildObservabilityAlarmFromEarlyWarning(
	signal EarlyWarningSignal,
) (ObservabilityAlarmRecord, error) {
	if err := signal.Validate(); err != nil {
		return ObservabilityAlarmRecord{}, err
	}

	record := ObservabilityAlarmRecord{
		Kind:       ObservabilityAlarmKindEarlyWarning,
		SignalType: signal.SignalType,
		Source:     signal.Source,
		Severity:   signal.Severity,
		MetricKey:  signal.MetricKey,
		Message:    signal.Message,
		ObservedAt: signal.ObservedAt,
	}

	if err := record.Validate(); err != nil {
		return ObservabilityAlarmRecord{}, err
	}

	return record, nil
}

func EmitObservabilityAlarmFromEarlyWarning(
	sink ObservabilityAlarmSink,
	signal EarlyWarningSignal,
) error {
	if sink == nil {
		return ErrObservabilityAlarmSinkRequired
	}

	record, err := BuildObservabilityAlarmFromEarlyWarning(signal)
	if err != nil {
		return err
	}

	return sink.PublishObservabilityAlarm(record)
}
