package monitor

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrEventBacklogSourceRequired        = errors.New("monitor: event backlog source required")
	ErrEventBacklogObservedAtRequired    = errors.New("monitor: event backlog observed at required")
	ErrEventBacklogNegativeDepth         = errors.New("monitor: event backlog depth cannot be negative")
	ErrEventBacklogNegativeRetryRatio    = errors.New("monitor: event retry ratio cannot be negative")
	ErrEventBacklogNegativeDLQDepth      = errors.New("monitor: event dlq depth cannot be negative")
)

const (
	EventBacklogMetricDepth        = "event_backlog_depth"
	EventBacklogMetricRetryRatioPct = "event_retry_ratio_pct"
	EventBacklogMetricDLQDepth     = "event_dlq_depth"
)

type EventBacklogSnapshot struct {
	Source         string
	BacklogDepth   int
	RetryRatioPct  float64
	DLQDepth       int
	ObservedAt     time.Time
}

func (s EventBacklogSnapshot) Validate() error {
	if strings.TrimSpace(s.Source) == "" {
		return ErrEventBacklogSourceRequired
	}
	if s.ObservedAt.IsZero() {
		return ErrEventBacklogObservedAtRequired
	}
	if s.BacklogDepth < 0 {
		return ErrEventBacklogNegativeDepth
	}
	if s.RetryRatioPct < 0 {
		return ErrEventBacklogNegativeRetryRatio
	}
	if s.DLQDepth < 0 {
		return ErrEventBacklogNegativeDLQDepth
	}

	return nil
}

type EventBacklogThresholdProfile struct {
	BacklogDepthPolicy EarlyWarningThresholdPolicy
	RetryRatioPolicy   EarlyWarningThresholdPolicy
	DLQDepthPolicy     EarlyWarningThresholdPolicy
}

func (p EventBacklogThresholdProfile) Validate() error {
	if err := p.BacklogDepthPolicy.Validate(); err != nil {
		return err
	}
	if err := p.RetryRatioPolicy.Validate(); err != nil {
		return err
	}
	if err := p.DLQDepthPolicy.Validate(); err != nil {
		return err
	}

	return nil
}

func DefaultEventBacklogDepthThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         EventBacklogMetricDepth,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      100,
		MediumThreshold:   500,
		HighThreshold:     2000,
		CriticalThreshold: 10000,
	}
}

func DefaultEventRetryRatioThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         EventBacklogMetricRetryRatioPct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      1,
		MediumThreshold:   5,
		HighThreshold:     10,
		CriticalThreshold: 25,
	}
}

func DefaultEventDLQDepthThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         EventBacklogMetricDLQDepth,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      1,
		MediumThreshold:   10,
		HighThreshold:     50,
		CriticalThreshold: 200,
	}
}

func DefaultEventBacklogThresholdProfile() EventBacklogThresholdProfile {
	return EventBacklogThresholdProfile{
		BacklogDepthPolicy: DefaultEventBacklogDepthThresholdPolicy(),
		RetryRatioPolicy:   DefaultEventRetryRatioThresholdPolicy(),
		DLQDepthPolicy:     DefaultEventDLQDepthThresholdPolicy(),
	}
}

func EvaluateEventBacklogEarlyWarnings(
	snapshot EventBacklogSnapshot,
	profile EventBacklogThresholdProfile,
) ([]EarlyWarningSignal, error) {
	if err := snapshot.Validate(); err != nil {
		return nil, err
	}
	if err := profile.Validate(); err != nil {
		return nil, err
	}

	signals := make([]EarlyWarningSignal, 0)

	backlogSignal, ok, err := buildEventBacklogSignal(
		snapshot,
		profile.BacklogDepthPolicy,
		float64(snapshot.BacklogDepth),
		"event backlog pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, backlogSignal)
	}

	retrySignal, ok, err := buildEventBacklogSignal(
		snapshot,
		profile.RetryRatioPolicy,
		snapshot.RetryRatioPct,
		"event retry pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, retrySignal)
	}

	dlqSignal, ok, err := buildEventBacklogSignal(
		snapshot,
		profile.DLQDepthPolicy,
		float64(snapshot.DLQDepth),
		"event dlq pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, dlqSignal)
	}

	return signals, nil
}

func buildEventBacklogSignal(
	snapshot EventBacklogSnapshot,
	policy EarlyWarningThresholdPolicy,
	value float64,
	message string,
) (EarlyWarningSignal, bool, error) {
	severity, matched, err := EvaluateEarlyWarningThreshold(policy, value)
	if err != nil {
		return EarlyWarningSignal{}, false, err
	}
	if !matched {
		return EarlyWarningSignal{}, false, nil
	}

	signal, err := NewEarlyWarningSignal(
		SignalTypeEventBacklog,
		snapshot.Source,
		severity,
		policy.MetricKey,
		value,
		fmt.Sprintf("%s: %s", snapshot.Source, message),
		snapshot.ObservedAt,
	)
	if err != nil {
		return EarlyWarningSignal{}, false, err
	}

	return signal, true, nil
}
