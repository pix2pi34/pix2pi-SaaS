package service

import (
	"strconv"
	"testing"
	"time"
)

func TestWebhookValidationPolicy_Validate_Success(t *testing.T) {
	policy := DefaultWebhookValidationPolicy()

	if err := policy.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestWebhookValidationPolicy_Validate_InvalidTolerance(t *testing.T) {
	policy := WebhookValidationPolicy{
		MaxAge: 0,
	}

	err := policy.Validate()
	if err == nil {
		t.Fatal("expected invalid tolerance error")
	}
	if err != ErrWebhookToleranceInvalid {
		t.Fatalf("expected ErrWebhookToleranceInvalid, got %v", err)
	}
}

func TestBuildWebhookSignedMessage_Success(t *testing.T) {
	msg, err := BuildWebhookSignedMessage("1713550000", `{"ok":true}`)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := `1713550000.{"ok":true}`
	if msg != expected {
		t.Fatalf("expected %s, got %s", expected, msg)
	}
}

func TestComputeWebhookSignature_Success(t *testing.T) {
	sig, err := ComputeWebhookSignature("super-secret", "1713550000", `{"ok":true}`)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if sig == "" {
		t.Fatal("expected non-empty signature")
	}
}

func TestValidateWebhookRequest_Success(t *testing.T) {
	now := time.Now()
	timestamp := strconv.FormatInt(now.Unix(), 10)

	signature, err := ComputeWebhookSignature(
		"super-secret",
		timestamp,
		`{"event":"payment.completed"}`,
	)
	if err != nil {
		t.Fatalf("unexpected signature error: %v", err)
	}

	err = ValidateWebhookRequest(
		"super-secret",
		timestamp,
		signature,
		`{"event":"payment.completed"}`,
		DefaultWebhookValidationPolicy(),
		now,
	)
	if err != nil {
		t.Fatalf("unexpected validation error: %v", err)
	}
}

func TestValidateWebhookRequest_InvalidSignature(t *testing.T) {
	now := time.Now()
	timestamp := strconv.FormatInt(now.Unix(), 10)

	err := ValidateWebhookRequest(
		"super-secret",
		timestamp,
		"deadbeef",
		`{"event":"payment.completed"}`,
		DefaultWebhookValidationPolicy(),
		now,
	)
	if err == nil {
		t.Fatal("expected invalid signature error")
	}
	if err != ErrWebhookSignatureInvalid {
		t.Fatalf("expected ErrWebhookSignatureInvalid, got %v", err)
	}
}

func TestValidateWebhookRequest_Expired(t *testing.T) {
	now := time.Now()
	oldTime := now.Add(-10 * time.Minute)
	timestamp := strconv.FormatInt(oldTime.Unix(), 10)

	signature, err := ComputeWebhookSignature(
		"super-secret",
		timestamp,
		`{"event":"payment.completed"}`,
	)
	if err != nil {
		t.Fatalf("unexpected signature error: %v", err)
	}

	err = ValidateWebhookRequest(
		"super-secret",
		timestamp,
		signature,
		`{"event":"payment.completed"}`,
		DefaultWebhookValidationPolicy(),
		now,
	)
	if err == nil {
		t.Fatal("expected expired timestamp error")
	}
	if err != ErrWebhookTimestampExpired {
		t.Fatalf("expected ErrWebhookTimestampExpired, got %v", err)
	}
}

func TestValidateWebhookRequest_InvalidTimestamp(t *testing.T) {
	err := ValidateWebhookRequest(
		"super-secret",
		"abc",
		"deadbeef",
		`{"event":"payment.completed"}`,
		DefaultWebhookValidationPolicy(),
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected invalid timestamp error")
	}
	if err != ErrWebhookTimestampInvalid {
		t.Fatalf("expected ErrWebhookTimestampInvalid, got %v", err)
	}
}

func TestValidateWebhookRequest_MissingSecret(t *testing.T) {
	err := ValidateWebhookRequest(
		"",
		"1713550000",
		"deadbeef",
		`{"event":"payment.completed"}`,
		DefaultWebhookValidationPolicy(),
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected missing secret error")
	}
	if err != ErrWebhookSecretRequired {
		t.Fatalf("expected ErrWebhookSecretRequired, got %v", err)
	}
}
