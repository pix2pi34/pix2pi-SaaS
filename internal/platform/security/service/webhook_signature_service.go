package service

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strconv"
	"strings"
	"time"
)

var (
	ErrWebhookSecretRequired        = errors.New("security: webhook secret required")
	ErrWebhookPayloadRequired       = errors.New("security: webhook payload required")
	ErrWebhookSignatureRequired     = errors.New("security: webhook signature required")
	ErrWebhookTimestampRequired     = errors.New("security: webhook timestamp required")
	ErrWebhookTimestampInvalid      = errors.New("security: webhook timestamp invalid")
	ErrWebhookTimestampExpired      = errors.New("security: webhook timestamp expired")
	ErrWebhookSignatureInvalid      = errors.New("security: webhook signature invalid")
	ErrWebhookToleranceInvalid      = errors.New("security: webhook tolerance invalid")
)

type WebhookValidationPolicy struct {
	MaxAge time.Duration
}

func DefaultWebhookValidationPolicy() WebhookValidationPolicy {
	return WebhookValidationPolicy{
		MaxAge: 5 * time.Minute,
	}
}

func (p WebhookValidationPolicy) Validate() error {
	if p.MaxAge <= 0 {
		return ErrWebhookToleranceInvalid
	}
	return nil
}

func BuildWebhookSignedMessage(
	timestamp string,
	payload string,
) (string, error) {
	ts := strings.TrimSpace(timestamp)
	body := strings.TrimSpace(payload)

	if ts == "" {
		return "", ErrWebhookTimestampRequired
	}
	if body == "" {
		return "", ErrWebhookPayloadRequired
	}

	return ts + "." + body, nil
}

func ComputeWebhookSignature(
	secret string,
	timestamp string,
	payload string,
) (string, error) {
	sec := strings.TrimSpace(secret)
	if sec == "" {
		return "", ErrWebhookSecretRequired
	}

	message, err := BuildWebhookSignedMessage(timestamp, payload)
	if err != nil {
		return "", err
	}

	mac := hmac.New(sha256.New, []byte(sec))
	_, _ = mac.Write([]byte(message))

	return hex.EncodeToString(mac.Sum(nil)), nil
}

func ValidateWebhookRequest(
	secret string,
	timestamp string,
	signature string,
	payload string,
	policy WebhookValidationPolicy,
	now time.Time,
) error {
	if err := policy.Validate(); err != nil {
		return err
	}

	sec := strings.TrimSpace(secret)
	ts := strings.TrimSpace(timestamp)
	sig := strings.TrimSpace(signature)
	body := strings.TrimSpace(payload)

	if sec == "" {
		return ErrWebhookSecretRequired
	}
	if ts == "" {
		return ErrWebhookTimestampRequired
	}
	if sig == "" {
		return ErrWebhookSignatureRequired
	}
	if body == "" {
		return ErrWebhookPayloadRequired
	}

	tsUnix, err := strconv.ParseInt(ts, 10, 64)
	if err != nil {
		return ErrWebhookTimestampInvalid
	}

	webhookTime := time.Unix(tsUnix, 0)
	if now.Sub(webhookTime) > policy.MaxAge {
		return ErrWebhookTimestampExpired
	}
	if webhookTime.After(now.Add(policy.MaxAge)) {
		return ErrWebhookTimestampInvalid
	}

	expectedSig, err := ComputeWebhookSignature(sec, ts, body)
	if err != nil {
		return err
	}

	expectedBytes, err := hex.DecodeString(expectedSig)
	if err != nil {
		return ErrWebhookSignatureInvalid
	}

	actualBytes, err := hex.DecodeString(sig)
	if err != nil {
		return ErrWebhookSignatureInvalid
	}

	if !hmac.Equal(actualBytes, expectedBytes) {
		return ErrWebhookSignatureInvalid
	}

	return nil
}
