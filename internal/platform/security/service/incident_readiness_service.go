package service

import "errors"

var (
	ErrIncidentEscalationUndefined = errors.New("security: incident escalation undefined")
)

const (
	IncidentEscalationP1Immediate = "p1_immediate"
	IncidentEscalationP2Urgent    = "p2_urgent"
	IncidentEscalationP3Review    = "p3_review"
	IncidentEscalationP4Observe   = "p4_observe"
)

type IncidentReadinessDecision struct {
	EventType        string
	Severity         string
	ShouldAlert      bool
	ShouldCreateTicket bool
	Escalation       string
	Category         string
}

func (d IncidentReadinessDecision) Validate() error {
	if d.EventType == "" {
		return ErrSecurityAuditEventTypeRequired
	}
	if d.Severity == "" {
		return ErrSecurityAuditSeverityRequired
	}
	if d.Escalation == "" {
		return ErrIncidentEscalationUndefined
	}
	return nil
}

func BuildIncidentReadinessDecision(
	event SecurityAuditEvent,
) (IncidentReadinessDecision, error) {
	if err := event.Validate(); err != nil {
		return IncidentReadinessDecision{}, err
	}

	decision := IncidentReadinessDecision{
		EventType: event.EventType,
		Severity:  event.Severity,
		Category:  incidentCategory(event.EventType),
	}

	switch event.Severity {
	case SecuritySeverityCritical:
		decision.ShouldAlert = true
		decision.ShouldCreateTicket = true
		decision.Escalation = IncidentEscalationP1Immediate

	case SecuritySeverityHigh:
		decision.ShouldAlert = true
		decision.ShouldCreateTicket = true
		decision.Escalation = IncidentEscalationP2Urgent

	case SecuritySeverityMedium:
		decision.ShouldAlert = false
		decision.ShouldCreateTicket = true
		decision.Escalation = IncidentEscalationP3Review

	case SecuritySeverityLow:
		decision.ShouldAlert = false
		decision.ShouldCreateTicket = false
		decision.Escalation = IncidentEscalationP4Observe

	default:
		return IncidentReadinessDecision{}, ErrSecurityAuditSeverityRequired
	}

	if err := decision.Validate(); err != nil {
		return IncidentReadinessDecision{}, err
	}

	return decision, nil
}

func incidentCategory(eventType string) string {
	switch eventType {
	case SecurityEventAuthRejected:
		return "auth"
	case SecurityEventWebhookRejected:
		return "webhook"
	case SecurityEventPolicyRejected:
		return "policy"
	default:
		return "security"
	}
}
