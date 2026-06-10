package service

import (
	"errors"
)

var (
	ErrSecurityAuditSinkRequired = errors.New("security: audit sink required")
)

type SecurityAuditSink interface {
	WriteSecurityAuditEvent(event SecurityAuditEvent) error
}

type InMemorySecurityAuditSink struct {
	Events []SecurityAuditEvent
}

func NewInMemorySecurityAuditSink() *InMemorySecurityAuditSink {
	return &InMemorySecurityAuditSink{
		Events: make([]SecurityAuditEvent, 0),
	}
}

func (s *InMemorySecurityAuditSink) WriteSecurityAuditEvent(
	event SecurityAuditEvent,
) error {
	if s == nil {
		return ErrSecurityAuditSinkRequired
	}

	s.Events = append(s.Events, event)
	return nil
}

func EmitSecurityAuditEvent(
	sink SecurityAuditSink,
	event SecurityAuditEvent,
) error {
	if sink == nil {
		return ErrSecurityAuditSinkRequired
	}

	if err := event.Validate(); err != nil {
		return err
	}

	return sink.WriteSecurityAuditEvent(event)
}

func EmitAuthRejectedSecurityAudit(
	sink SecurityAuditSink,
	tenantID string,
	source string,
	reason string,
	requestID string,
	atUnix int64,
) error {
	event, err := NewAuthRejectedAuditEvent(
		tenantID,
		source,
		reason,
		requestID,
		unixTime(atUnix),
	)
	if err != nil {
		return err
	}

	return EmitSecurityAuditEvent(sink, event)
}

func EmitWebhookRejectedSecurityAudit(
	sink SecurityAuditSink,
	tenantID string,
	source string,
	reason string,
	requestID string,
	atUnix int64,
) error {
	event, err := NewWebhookRejectedAuditEvent(
		tenantID,
		source,
		reason,
		requestID,
		unixTime(atUnix),
	)
	if err != nil {
		return err
	}

	return EmitSecurityAuditEvent(sink, event)
}

func EmitPolicyRejectedSecurityAudit(
	sink SecurityAuditSink,
	tenantID string,
	source string,
	reason string,
	requestID string,
	atUnix int64,
) error {
	event, err := NewPolicyRejectedAuditEvent(
		tenantID,
		source,
		reason,
		requestID,
		unixTime(atUnix),
	)
	if err != nil {
		return err
	}

	return EmitSecurityAuditEvent(sink, event)
}
