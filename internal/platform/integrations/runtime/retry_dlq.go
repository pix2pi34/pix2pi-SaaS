package integrationruntime

import (
	"fmt"
	"time"
)

type FailureKind string

const (
	FailureKindRetryable    FailureKind = "RETRYABLE"
	FailureKindNonRetryable FailureKind = "NON_RETRYABLE"
	FailureKindPoison       FailureKind = "POISON"
)

type RetryPolicy struct {
	MaxAttempts int
	DLQEnabled  bool
}

type FailureRecord struct {
	TenantID      string
	ProviderKey   string
	AppKey        string
	Operation     string
	Attempt       int
	Kind          FailureKind
	ErrorCode     string
	CorrelationID string
	Payload       string
}

type RetryDecision struct {
	ShouldRetry bool
	MoveToDLQ   bool
	NextAttempt int
	Reason      string
}

type DLQMessage struct {
	TenantID      string
	ProviderKey   string
	AppKey        string
	Operation     string
	Attempt       int
	ErrorCode     string
	CorrelationID string
	Payload       string
	Reason        string
	CreatedAt     time.Time
}

func DefaultRetryPolicy() RetryPolicy {
	return RetryPolicy{
		MaxAttempts: 3,
		DLQEnabled:  true,
	}
}

func EvaluateRetry(policy RetryPolicy, failure FailureRecord) RetryDecision {
	if policy.MaxAttempts <= 0 {
		policy.MaxAttempts = 3
	}

	if err := validateFailureRecord(failure); err != nil {
		return RetryDecision{ShouldRetry: false, MoveToDLQ: false, Reason: "invalid_failure_record"}
	}

	switch failure.Kind {
	case FailureKindRetryable:
		if failure.Attempt < policy.MaxAttempts {
			return RetryDecision{
				ShouldRetry: true,
				MoveToDLQ:   false,
				NextAttempt: failure.Attempt + 1,
				Reason:      "retryable_under_max_attempts",
			}
		}
		return RetryDecision{
			ShouldRetry: false,
			MoveToDLQ:   policy.DLQEnabled,
			NextAttempt: failure.Attempt,
			Reason:      "retryable_max_attempts_reached",
		}

	case FailureKindNonRetryable:
		return RetryDecision{
			ShouldRetry: false,
			MoveToDLQ:   false,
			NextAttempt: failure.Attempt,
			Reason:      "non_retryable_failure",
		}

	case FailureKindPoison:
		return RetryDecision{
			ShouldRetry: false,
			MoveToDLQ:   policy.DLQEnabled,
			NextAttempt: failure.Attempt,
			Reason:      "poison_message",
		}

	default:
		return RetryDecision{
			ShouldRetry: false,
			MoveToDLQ:   policy.DLQEnabled,
			NextAttempt: failure.Attempt,
			Reason:      "unknown_failure_kind",
		}
	}
}

func CreateDLQMessage(failure FailureRecord, reason string) (DLQMessage, error) {
	if err := validateFailureRecord(failure); err != nil {
		return DLQMessage{}, err
	}
	if err := requireNonEmpty(reason, "reason"); err != nil {
		return DLQMessage{}, err
	}

	return DLQMessage{
		TenantID:      normalize(failure.TenantID),
		ProviderKey:   normalize(failure.ProviderKey),
		AppKey:        normalize(failure.AppKey),
		Operation:     normalize(failure.Operation),
		Attempt:       failure.Attempt,
		ErrorCode:     normalize(failure.ErrorCode),
		CorrelationID: normalize(failure.CorrelationID),
		Payload:       failure.Payload,
		Reason:        normalize(reason),
		CreatedAt:     time.Now().UTC(),
	}, nil
}

func validateFailureRecord(failure FailureRecord) error {
	if err := requireNonEmpty(failure.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(failure.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(failure.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(failure.Operation, "operation"); err != nil {
		return err
	}
	if err := requireNonEmpty(failure.ErrorCode, "error_code"); err != nil {
		return err
	}
	if err := requireNonEmpty(failure.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if failure.Attempt <= 0 {
		return fmt.Errorf("%w: attempt must be positive", ErrInvalidIntegrationRequest)
	}
	if failure.Kind == "" {
		return fmt.Errorf("%w: failure kind required", ErrInvalidIntegrationRequest)
	}
	return nil
}
