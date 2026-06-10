package service

import (
	"testing"
	"time"
)

func TestWebhookReplayPolicy_Validate_Success(t *testing.T) {
	policy := DefaultWebhookReplayPolicy()

	if err := policy.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestWebhookReplayPolicy_Validate_InvalidTTL(t *testing.T) {
	policy := WebhookReplayPolicy{TTL: 0}

	err := policy.Validate()
	if err == nil {
		t.Fatal("expected invalid ttl error")
	}
	if err != ErrWebhookReplayTTLInvalid {
		t.Fatalf("expected ErrWebhookReplayTTLInvalid, got %v", err)
	}
}

func TestWebhookReplayInput_Validate_Success(t *testing.T) {
	input := WebhookReplayInput{
		Source:  "iyzico",
		EventID: "evt_123",
	}

	if err := input.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestBuildWebhookReplayKey_Success(t *testing.T) {
	key, err := BuildWebhookReplayKey(WebhookReplayInput{
		Source:  "iyzico",
		EventID: "evt_123",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if key != "iyzico:evt_123" {
		t.Fatalf("expected iyzico:evt_123, got %s", key)
	}
}

func TestCheckAndStoreWebhookReplay_Success(t *testing.T) {
	store := NewInMemoryWebhookReplayStore()
	now := time.Now()

	err := CheckAndStoreWebhookReplay(
		store,
		WebhookReplayInput{
			Source:  "iyzico",
			EventID: "evt_123",
		},
		DefaultWebhookReplayPolicy(),
		now,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCheckAndStoreWebhookReplay_ReplayDetected(t *testing.T) {
	store := NewInMemoryWebhookReplayStore()
	now := time.Now()

	input := WebhookReplayInput{
		Source:  "iyzico",
		EventID: "evt_123",
	}

	err := CheckAndStoreWebhookReplay(
		store,
		input,
		DefaultWebhookReplayPolicy(),
		now,
	)
	if err != nil {
		t.Fatalf("unexpected first write error: %v", err)
	}

	err = CheckAndStoreWebhookReplay(
		store,
		input,
		DefaultWebhookReplayPolicy(),
		now.Add(1*time.Minute),
	)
	if err == nil {
		t.Fatal("expected replay detected error")
	}
	if err != ErrWebhookReplayDetected {
		t.Fatalf("expected ErrWebhookReplayDetected, got %v", err)
	}
}

func TestCheckAndStoreWebhookReplay_ExpiredRecordAllowsReuse(t *testing.T) {
	store := NewInMemoryWebhookReplayStore()
	now := time.Now()

	input := WebhookReplayInput{
		Source:  "iyzico",
		EventID: "evt_123",
	}

	policy := WebhookReplayPolicy{TTL: 1 * time.Minute}

	err := CheckAndStoreWebhookReplay(store, input, policy, now)
	if err != nil {
		t.Fatalf("unexpected first write error: %v", err)
	}

	err = CheckAndStoreWebhookReplay(store, input, policy, now.Add(2*time.Minute))
	if err != nil {
		t.Fatalf("expected expired replay window to allow reuse, got %v", err)
	}
}

func TestCheckAndStoreWebhookReplay_NilStore(t *testing.T) {
	err := CheckAndStoreWebhookReplay(
		nil,
		WebhookReplayInput{
			Source:  "iyzico",
			EventID: "evt_123",
		},
		DefaultWebhookReplayPolicy(),
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected nil store error")
	}
	if err != ErrWebhookReplayStoreRequired {
		t.Fatalf("expected ErrWebhookReplayStoreRequired, got %v", err)
	}
}

func TestCheckAndStoreWebhookReplay_MissingEventID(t *testing.T) {
	store := NewInMemoryWebhookReplayStore()

	err := CheckAndStoreWebhookReplay(
		store,
		WebhookReplayInput{
			Source:  "iyzico",
			EventID: "",
		},
		DefaultWebhookReplayPolicy(),
		time.Now(),
	)
	if err == nil {
		t.Fatal("expected missing event id error")
	}
	if err != ErrWebhookReplayEventIDRequired {
		t.Fatalf("expected ErrWebhookReplayEventIDRequired, got %v", err)
	}
}
