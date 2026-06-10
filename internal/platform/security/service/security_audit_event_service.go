package service

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrSecurityAuditEventTypeRequired = errors.New("security: audit event type required")
	ErrSecurityAuditSeverityRequired  = errors.New("security: audit severity required")
	ErrSecurityAuditSourceRequired    = errors.New("security: audit source required")
	ErrSecurityAuditReasonRequired    = errors.New("security: audit reason required")
	ErrSecurityAuditTenantRequired    = errors.New("security: audit tenant required")
	ErrSecurityAuditAtRequired        = errors.New("security: audit occurred at required")
)

const (
	SecurityEventAuthRejected    = "auth.rejected"
	SecurityEventWebhookRejected = "webhook.rejected"
	SecurityEventPolicyRejected  = "policy.rejected"

	SecuritySeverityLow      = "low"
	SecuritySeverityMedium   = "medium"
	SecuritySeverityHigh     = "high"
	SecuritySeverityCritical = "critical"
)

type SecurityAuditEvent struct {
	EventType   string
	Severity    string
	Source      string
	TenantID    string
	Reason      string
	RequestID   string
	OccurredAt  time.Time
}

func (e SecurityAuditEvent) Validate() error {
	if strings.TrimSpace(e.EventType) == "" {
		return ErrSecurityAuditEventTypeRequired
	}
	if strings.TrimSpace(e.Severity) == "" {
		return ErrSecurityAuditSeverityRequired
	}
	if strings.TrimSpace(e.Source) == "" {
		return ErrSecurityAuditSourceRequired
	}
	if strings.TrimSpace(e.TenantID) == "" {
		return ErrSecurityAuditTenantRequired
	}
	if strings.TrimSpace(e.Reason) == "" {
		return ErrSecurityAuditReasonRequired
	}
	if e.OccurredAt.IsZero() {
		return ErrSecurityAuditAtRequired
	}

	switch e.Severity {
	case SecuritySeverityLow, SecuritySeverityMedium, SecuritySeverityHigh, SecuritySeverityCritical:
	default:
		return ErrSecurityAuditSeverityRequired
	}

	return nil
}

func NewAuthRejectedAuditEvent(
	tenantID string,
	source string,
	reason string,
	requestID string,
	at time.Time,
) (SecurityAuditEvent, error) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventAuthRejected,
		Severity:   SecuritySeverityHigh,
		Source:     strings.TrimSpace(source),
		TenantID:   strings.TrimSpace(tenantID),
		Reason:     strings.TrimSpace(reason),
		RequestID:  strings.TrimSpace(requestID),
		OccurredAt: at,
	}

	if err := event.Validate(); err != nil {
		return SecurityAuditEvent{}, err
	}

	return event, nil
}

func NewWebhookRejectedAuditEvent(
	tenantID string,
	source string,
	reason string,
	requestID string,
	at time.Time,
) (SecurityAuditEvent, error) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventWebhookRejected,
		Severity:   SecuritySeverityHigh,
		Source:     strings.TrimSpace(source),
		TenantID:   strings.TrimSpace(tenantID),
		Reason:     strings.TrimSpace(reason),
		RequestID:  strings.TrimSpace(requestID),
		OccurredAt: at,
	}

	if err := event.Validate(); err != nil {
		return SecurityAuditEvent{}, err
	}

	return event, nil
}

func NewPolicyRejectedAuditEvent(
	tenantID string,
	source string,
	reason string,
	requestID string,
	at time.Time,
) (SecurityAuditEvent, error) {
	event := SecurityAuditEvent{
		EventType:  SecurityEventPolicyRejected,
		Severity:   SecuritySeverityMedium,
		Source:     strings.TrimSpace(source),
		TenantID:   strings.TrimSpace(tenantID),
		Reason:     strings.TrimSpace(reason),
		RequestID:  strings.TrimSpace(requestID),
		OccurredAt: at,
	}

	if err := event.Validate(); err != nil {
		return SecurityAuditEvent{}, err
	}

	return event, nil
}
