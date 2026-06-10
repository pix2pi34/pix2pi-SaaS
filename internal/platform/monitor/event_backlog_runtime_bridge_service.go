package monitor

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrEventBacklogRuntimeSourceRequired     = errors.New("monitor: event backlog runtime source required")
	ErrEventBacklogRuntimeObservedAtRequired = errors.New("monitor: event backlog runtime observed at required")
	ErrEventBacklogRuntimeNegativeDepth      = errors.New("monitor: event backlog runtime depth cannot be negative")
	ErrEventBacklogRuntimeNegativeRetryCount = errors.New("monitor: event backlog runtime retry count cannot be negative")
	ErrEventBacklogRuntimeNegativeProcessed  = errors.New("monitor: event backlog runtime processed count cannot be negative")
	ErrEventBacklogRuntimeNegativeDLQDepth   = errors.New("monitor: event backlog runtime dlq depth cannot be negative")
)

type RuntimeEventBacklogInput struct {
	Source         string
	BacklogDepth   int
	RetryCount     int
	ProcessedCount int
	DLQDepth       int
	ObservedAt     time.Time
}

func (i RuntimeEventBacklogInput) Validate() error {
	if strings.TrimSpace(i.Source) == "" {
		return ErrEventBacklogRuntimeSourceRequired
	}
	if i.ObservedAt.IsZero() {
		return ErrEventBacklogRuntimeObservedAtRequired
	}
	if i.BacklogDepth < 0 {
		return ErrEventBacklogRuntimeNegativeDepth
	}
	if i.RetryCount < 0 {
		return ErrEventBacklogRuntimeNegativeRetryCount
	}
	if i.ProcessedCount < 0 {
		return ErrEventBacklogRuntimeNegativeProcessed
	}
	if i.DLQDepth < 0 {
		return ErrEventBacklogRuntimeNegativeDLQDepth
	}

	return nil
}

func BuildRuntimeEventBacklogSnapshot(
	input RuntimeEventBacklogInput,
) (EventBacklogSnapshot, error) {
	if err := input.Validate(); err != nil {
		return EventBacklogSnapshot{}, err
	}

	retryRatioPct := 0.0

	switch {
	case input.ProcessedCount == 0 && input.RetryCount == 0:
		retryRatioPct = 0
	case input.ProcessedCount == 0 && input.RetryCount > 0:
		retryRatioPct = 100
	default:
		retryRatioPct = (float64(input.RetryCount) / float64(input.ProcessedCount)) * 100
	}

	snapshot := EventBacklogSnapshot{
		Source:        strings.TrimSpace(input.Source),
		BacklogDepth:  input.BacklogDepth,
		RetryRatioPct: retryRatioPct,
		DLQDepth:      input.DLQDepth,
		ObservedAt:    input.ObservedAt,
	}

	if err := snapshot.Validate(); err != nil {
		return EventBacklogSnapshot{}, err
	}

	return snapshot, nil
}

func EvaluateRuntimeEventBacklog(
	input RuntimeEventBacklogInput,
	profile EventBacklogThresholdProfile,
) ([]EarlyWarningSignal, error) {
	snapshot, err := BuildRuntimeEventBacklogSnapshot(input)
	if err != nil {
		return nil, err
	}

	return EvaluateEventBacklogEarlyWarnings(snapshot, profile)
}
