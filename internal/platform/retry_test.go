package platform

import (
	"testing"
	"time"
)

func TestRetryPolicy_DelayFor_FirstAttempt(t *testing.T) {
	policy := RetryPolicy{
		MaxAttempts: 5,
		BaseDelay:   2 * time.Second,
		BackoffRate: 2,
	}

	got := policy.DelayFor(1)
	want := 2 * time.Second

	if got != want {
		t.Fatalf("beklenen %v, gelen %v", want, got)
	}
}

func TestRetryPolicy_DelayFor_Backoff(t *testing.T) {
	policy := RetryPolicy{
		MaxAttempts: 5,
		BaseDelay:   2 * time.Second,
		BackoffRate: 2,
	}

	got := policy.DelayFor(3)
	want := 8 * time.Second

	if got != want {
		t.Fatalf("beklenen %v, gelen %v", want, got)
	}
}

func TestRetryPolicy_CanRetry(t *testing.T) {
	policy := RetryPolicy{
		MaxAttempts: 5,
		BaseDelay:   2 * time.Second,
		BackoffRate: 2,
	}

	if !policy.CanRetry(1) {
		t.Fatalf("1. denemede retry true olmaliydi")
	}

	if !policy.CanRetry(4) {
		t.Fatalf("4. denemede retry true olmaliydi")
	}

	if policy.CanRetry(5) {
		t.Fatalf("5. denemede retry false olmaliydi")
	}
}
