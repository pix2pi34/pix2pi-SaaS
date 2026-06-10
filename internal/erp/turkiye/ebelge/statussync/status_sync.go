package statussync

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type DocumentType string

const (
	DocumentTypeEFatura  DocumentType = "E_FATURA"
	DocumentTypeEArsiv   DocumentType = "E_ARSIV"
	DocumentTypeEAdisyon DocumentType = "E_ADISYON"
)

type SyncSource string

const (
	SyncSourceCallback SyncSource = "CALLBACK"
	SyncSourcePoll     SyncSource = "POLL"
)

type SyncDecisionStatus string

const (
	DecisionAccepted  SyncDecisionStatus = "ACCEPTED"
	DecisionIgnored   SyncDecisionStatus = "IGNORED"
	DecisionRejected  SyncDecisionStatus = "REJECTED"
	DecisionScheduled SyncDecisionStatus = "SCHEDULED"
)

type ProviderStatus string

const (
	ProviderStatusQueued    ProviderStatus = "PROVIDER_QUEUED"
	ProviderStatusSent      ProviderStatus = "SENT"
	ProviderStatusDelivered ProviderStatus = "DELIVERED"
	ProviderStatusAccepted  ProviderStatus = "ACCEPTED"
	ProviderStatusRejected  ProviderStatus = "REJECTED"
	ProviderStatusReported  ProviderStatus = "REPORTED"
	ProviderStatusCanceled  ProviderStatus = "CANCELED"
	ProviderStatusFailed    ProviderStatus = "FAILED"
)

type CanonicalStatus string

const (
	CanonicalStatusProviderQueued CanonicalStatus = "PROVIDER_QUEUED"
	CanonicalStatusSent           CanonicalStatus = "SENT"
	CanonicalStatusDelivered      CanonicalStatus = "DELIVERED"
	CanonicalStatusAccepted       CanonicalStatus = "ACCEPTED"
	CanonicalStatusRejected       CanonicalStatus = "REJECTED"
	CanonicalStatusReported       CanonicalStatus = "REPORTED"
	CanonicalStatusCanceled       CanonicalStatus = "CANCELED"
	CanonicalStatusFailed         CanonicalStatus = "FAILED"
)

type RuntimeConfig struct {
	CallbackSignatureRequired bool           `json:"callback_signature_required"`
	PollEnabled               bool           `json:"poll_enabled"`
	PollIntervalSeconds       int            `json:"poll_interval_seconds"`
	MaxPollBatchSize          int            `json:"max_poll_batch_size"`
	MaxRetryCount             int            `json:"max_retry_count"`
	AllowedDocumentTypes      []DocumentType `json:"allowed_document_types"`
	AllowedProviderCodes      []string       `json:"allowed_provider_codes"`
}

type StatusSyncRequest struct {
	TenantID            string         `json:"tenant_id"`
	CorrelationID       string         `json:"correlation_id"`
	RequestID           string         `json:"request_id"`
	IdempotencyKey      string         `json:"idempotency_key"`
	Source              SyncSource     `json:"source"`
	DocumentID          string         `json:"document_id"`
	DocumentNo          string         `json:"document_no"`
	DocumentType        DocumentType   `json:"document_type"`
	ProviderCode        string         `json:"provider_code"`
	ProviderDocumentID  string         `json:"provider_document_id"`
	ProviderEnvelopeID  string         `json:"provider_envelope_id"`
	ProviderStatus      ProviderStatus `json:"provider_status"`
	ProviderMessage     string         `json:"provider_message"`
	ProviderPayloadHash string         `json:"provider_payload_hash"`
	CallbackSignature   string         `json:"callback_signature"`
	ProviderEventTime   time.Time      `json:"provider_event_time"`
	ReceivedAt          time.Time      `json:"received_at"`
}

type StatusSyncResult struct {
	TenantID            string             `json:"tenant_id"`
	CorrelationID       string             `json:"correlation_id"`
	RequestID           string             `json:"request_id"`
	DocumentID          string             `json:"document_id"`
	DocumentNo          string             `json:"document_no"`
	DocumentType        DocumentType       `json:"document_type"`
	Source              SyncSource         `json:"source"`
	DecisionStatus      SyncDecisionStatus `json:"decision_status"`
	PreviousStatus      CanonicalStatus    `json:"previous_status"`
	NewStatus           CanonicalStatus    `json:"new_status"`
	StatusChanged       bool               `json:"status_changed"`
	Retryable           bool               `json:"retryable"`
	RetryScheduled      bool               `json:"retry_scheduled"`
	RetryAfter          time.Time          `json:"retry_after"`
	AuditAction         string             `json:"audit_action"`
	AuditDecisionReason string             `json:"audit_decision_reason"`
	ErrorCode           string             `json:"error_code"`
	ErrorMessage        string             `json:"error_message"`
	ProcessedAt         time.Time          `json:"processed_at"`
}

type PollCandidate struct {
	TenantID           string          `json:"tenant_id"`
	DocumentID         string          `json:"document_id"`
	DocumentNo         string          `json:"document_no"`
	DocumentType       DocumentType    `json:"document_type"`
	ProviderCode       string          `json:"provider_code"`
	ProviderDocumentID string          `json:"provider_document_id"`
	LastKnownStatus    CanonicalStatus `json:"last_known_status"`
	RetryCount         int             `json:"retry_count"`
	NextPollAt         time.Time       `json:"next_poll_at"`
}

type PollPlan struct {
	DecisionStatus SyncDecisionStatus `json:"decision_status"`
	Candidates     []PollCandidate    `json:"candidates"`
	SkippedCount   int                `json:"skipped_count"`
	Reason         string             `json:"reason"`
	PlannedAt      time.Time          `json:"planned_at"`
}

type StatusSyncRuntime struct {
	config RuntimeConfig
}

func NewStatusSyncRuntime(config RuntimeConfig) (*StatusSyncRuntime, error) {
	if config.PollIntervalSeconds <= 0 {
		return nil, errors.New("poll interval seconds must be positive")
	}
	if config.MaxPollBatchSize <= 0 {
		return nil, errors.New("max poll batch size must be positive")
	}
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max retry count cannot be negative")
	}
	if len(config.AllowedDocumentTypes) == 0 {
		return nil, errors.New("allowed document types are required")
	}
	if len(config.AllowedProviderCodes) == 0 {
		return nil, errors.New("allowed provider codes are required")
	}

	return &StatusSyncRuntime{config: config}, nil
}

func (r *StatusSyncRuntime) HandleCallback(req StatusSyncRequest, previous CanonicalStatus) (StatusSyncResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, previous, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Source != SyncSourceCallback {
		return rejected(req, previous, "INVALID_SOURCE", "callback handler requires CALLBACK source"), errors.New("callback handler requires CALLBACK source")
	}
	if r.config.CallbackSignatureRequired && strings.TrimSpace(req.CallbackSignature) == "" {
		return rejected(req, previous, "CALLBACK_SIGNATURE_REQUIRED", "callback signature is required"), errors.New("callback signature is required")
	}

	return r.applyStatus(req, previous), nil
}

func (r *StatusSyncRuntime) HandlePollResult(req StatusSyncRequest, previous CanonicalStatus) (StatusSyncResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, previous, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Source != SyncSourcePoll {
		return rejected(req, previous, "INVALID_SOURCE", "poll handler requires POLL source"), errors.New("poll handler requires POLL source")
	}

	return r.applyStatus(req, previous), nil
}

func (r *StatusSyncRuntime) BuildPollPlan(candidates []PollCandidate, now time.Time) PollPlan {
	if !r.config.PollEnabled {
		return PollPlan{
			DecisionStatus: DecisionIgnored,
			SkippedCount:   len(candidates),
			Reason:         "polling is disabled",
			PlannedAt:      now.UTC(),
		}
	}

	planned := make([]PollCandidate, 0, r.config.MaxPollBatchSize)
	skipped := 0

	for _, candidate := range candidates {
		if len(planned) >= r.config.MaxPollBatchSize {
			skipped++
			continue
		}
		if candidate.NextPollAt.After(now) {
			skipped++
			continue
		}
		if candidate.RetryCount > r.config.MaxRetryCount {
			skipped++
			continue
		}
		if !r.documentTypeAllowed(candidate.DocumentType) || !r.providerAllowed(candidate.ProviderCode) {
			skipped++
			continue
		}
		planned = append(planned, candidate)
	}

	decision := DecisionScheduled
	reason := "poll candidates scheduled"
	if len(planned) == 0 {
		decision = DecisionIgnored
		reason = "no eligible poll candidates"
	}

	return PollPlan{
		DecisionStatus: decision,
		Candidates:     planned,
		SkippedCount:   skipped,
		Reason:         reason,
		PlannedAt:      now.UTC(),
	}
}

func (r *StatusSyncRuntime) validateRequest(req StatusSyncRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(req.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if !r.documentTypeAllowed(req.DocumentType) {
		return fmt.Errorf("document_type is not allowed: %s", req.DocumentType)
	}
	if !r.providerAllowed(req.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", req.ProviderCode)
	}
	if strings.TrimSpace(req.ProviderDocumentID) == "" {
		return errors.New("provider_document_id is required")
	}
	if strings.TrimSpace(string(req.ProviderStatus)) == "" {
		return errors.New("provider_status is required")
	}
	if strings.TrimSpace(req.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if req.ProviderEventTime.IsZero() {
		return errors.New("provider_event_time is required")
	}
	if req.ReceivedAt.IsZero() {
		return errors.New("received_at is required")
	}
	return nil
}

func (r *StatusSyncRuntime) applyStatus(req StatusSyncRequest, previous CanonicalStatus) StatusSyncResult {
	next := canonicalize(req.ProviderStatus)
	changed := previous != next

	decision := DecisionAccepted
	action := "STATUS_SYNC_ACCEPTED"
	reason := "provider status accepted and canonical status updated"

	if !changed {
		decision = DecisionIgnored
		action = "STATUS_SYNC_NO_CHANGE"
		reason = "provider status accepted but canonical status already current"
	}

	retryable := next == CanonicalStatusFailed
	retryScheduled := retryable
	retryAfter := time.Time{}
	if retryScheduled {
		retryAfter = req.ReceivedAt.Add(time.Duration(r.config.PollIntervalSeconds) * time.Second).UTC()
	}

	return StatusSyncResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		DocumentType:        req.DocumentType,
		Source:              req.Source,
		DecisionStatus:      decision,
		PreviousStatus:      previous,
		NewStatus:           next,
		StatusChanged:       changed,
		Retryable:           retryable,
		RetryScheduled:      retryScheduled,
		RetryAfter:          retryAfter,
		AuditAction:         action,
		AuditDecisionReason: reason,
		ProcessedAt:         time.Now().UTC(),
	}
}

func rejected(req StatusSyncRequest, previous CanonicalStatus, code string, message string) StatusSyncResult {
	return StatusSyncResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		DocumentType:        req.DocumentType,
		Source:              req.Source,
		DecisionStatus:      DecisionRejected,
		PreviousStatus:      previous,
		StatusChanged:       false,
		Retryable:           false,
		RetryScheduled:      false,
		AuditAction:         "STATUS_SYNC_REJECTED",
		AuditDecisionReason: "request rejected by callback/poll validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		ProcessedAt:         time.Now().UTC(),
	}
}

func canonicalize(status ProviderStatus) CanonicalStatus {
	switch status {
	case ProviderStatusQueued:
		return CanonicalStatusProviderQueued
	case ProviderStatusSent:
		return CanonicalStatusSent
	case ProviderStatusDelivered:
		return CanonicalStatusDelivered
	case ProviderStatusAccepted:
		return CanonicalStatusAccepted
	case ProviderStatusRejected:
		return CanonicalStatusRejected
	case ProviderStatusReported:
		return CanonicalStatusReported
	case ProviderStatusCanceled:
		return CanonicalStatusCanceled
	case ProviderStatusFailed:
		return CanonicalStatusFailed
	default:
		return CanonicalStatusFailed
	}
}

func (r *StatusSyncRuntime) documentTypeAllowed(t DocumentType) bool {
	for _, allowed := range r.config.AllowedDocumentTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func (r *StatusSyncRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}
