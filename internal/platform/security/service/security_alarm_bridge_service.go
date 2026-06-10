package service

import "errors"

var (
	ErrSecurityAlarmSinkRequired = errors.New("security: alarm sink required")
)

type SecurityAlarmSignal struct {
	EventType          string
	Severity           string
	Category           string
	Escalation         string
	ShouldAlert        bool
	ShouldCreateTicket bool
}

func (s SecurityAlarmSignal) Validate() error {
	if s.EventType == "" {
		return ErrSecurityAuditEventTypeRequired
	}
	if s.Severity == "" {
		return ErrSecurityAuditSeverityRequired
	}
	if s.Escalation == "" {
		return ErrIncidentEscalationUndefined
	}
	return nil
}

type SecurityAlarmSink interface {
	PublishSecurityAlarm(signal SecurityAlarmSignal) error
}

type InMemorySecurityAlarmSink struct {
	Signals []SecurityAlarmSignal
}

func NewInMemorySecurityAlarmSink() *InMemorySecurityAlarmSink {
	return &InMemorySecurityAlarmSink{
		Signals: make([]SecurityAlarmSignal, 0),
	}
}

func (s *InMemorySecurityAlarmSink) PublishSecurityAlarm(
	signal SecurityAlarmSignal,
) error {
	if s == nil {
		return ErrSecurityAlarmSinkRequired
	}

	s.Signals = append(s.Signals, signal)
	return nil
}

func BuildSecurityAlarmSignal(
	decision IncidentReadinessDecision,
) (SecurityAlarmSignal, error) {
	if err := decision.Validate(); err != nil {
		return SecurityAlarmSignal{}, err
	}

	signal := SecurityAlarmSignal{
		EventType:          decision.EventType,
		Severity:           decision.Severity,
		Category:           decision.Category,
		Escalation:         decision.Escalation,
		ShouldAlert:        decision.ShouldAlert,
		ShouldCreateTicket: decision.ShouldCreateTicket,
	}

	if err := signal.Validate(); err != nil {
		return SecurityAlarmSignal{}, err
	}

	return signal, nil
}

func EmitSecurityAlarmFromDecision(
	sink SecurityAlarmSink,
	decision IncidentReadinessDecision,
) error {
	if sink == nil {
		return ErrSecurityAlarmSinkRequired
	}

	signal, err := BuildSecurityAlarmSignal(decision)
	if err != nil {
		return err
	}

	return sink.PublishSecurityAlarm(signal)
}
