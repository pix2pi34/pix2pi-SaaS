package integrationruntime

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"
)

type ExternalEventIntakeRequest struct {
	TenantID        string
	ProviderKey     string
	ExternalEventID string
	EventType       string
	CorrelationID   string
	RawPayload      string
	Signature       string
	Secret          string
	Timestamp       time.Time
}

type ExternalEvent struct {
	TenantID        string
	ProviderKey     string
	ExternalEventID string
	EventType       string
	CorrelationID   string
	RawPayload      string
	ReceivedAt      time.Time
}

type WebhookIntakeRuntime struct {
	MaxTimestampSkew time.Duration
}

func DefaultWebhookIntakeRuntime() WebhookIntakeRuntime {
	return WebhookIntakeRuntime{MaxTimestampSkew: 5 * time.Minute}
}

func (runtime WebhookIntakeRuntime) VerifyAndBuildEvent(req ExternalEventIntakeRequest) (ExternalEvent, error) {
	if err := validateExternalEventIntakeRequest(req); err != nil {
		return ExternalEvent{}, err
	}

	if err := runtime.validateTimestamp(req.Timestamp); err != nil {
		return ExternalEvent{}, err
	}

	expected := BuildWebhookSignature(req.Secret, req.Timestamp, req.RawPayload)
	if !hmac.Equal([]byte(expected), []byte(req.Signature)) {
		return ExternalEvent{}, fmt.Errorf("%w: webhook signature mismatch", ErrInvalidIntegrationRequest)
	}

	return ExternalEvent{
		TenantID:        normalize(req.TenantID),
		ProviderKey:     normalize(req.ProviderKey),
		ExternalEventID: normalize(req.ExternalEventID),
		EventType:       normalize(req.EventType),
		CorrelationID:   normalize(req.CorrelationID),
		RawPayload:      req.RawPayload,
		ReceivedAt:      time.Now().UTC(),
	}, nil
}

func BuildWebhookSignature(secret string, timestamp time.Time, rawPayload string) string {
	base := fmt.Sprintf("%d.%s", timestamp.Unix(), rawPayload)
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(base))
	return hex.EncodeToString(mac.Sum(nil))
}

func validateExternalEventIntakeRequest(req ExternalEventIntakeRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ExternalEventID, "external_event_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.EventType, "event_type"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RawPayload, "raw_payload"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.Signature, "signature"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.Secret, "secret"); err != nil {
		return err
	}
	if req.Timestamp.IsZero() {
		return fmt.Errorf("%w: timestamp required", ErrInvalidIntegrationRequest)
	}
	return nil
}

func (runtime WebhookIntakeRuntime) validateTimestamp(ts time.Time) error {
	maxSkew := runtime.MaxTimestampSkew
	if maxSkew <= 0 {
		maxSkew = 5 * time.Minute
	}

	now := time.Now().UTC()
	if ts.Before(now.Add(-maxSkew)) || ts.After(now.Add(maxSkew)) {
		return fmt.Errorf("%w: webhook timestamp outside allowed skew", ErrInvalidIntegrationRequest)
	}

	return nil
}
