package monitor

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrReportingPressureSourceRequired         = errors.New("monitor: reporting pressure source required")
	ErrReportingPressureObservedAtRequired     = errors.New("monitor: reporting pressure observed at required")
	ErrReportingPressureNegativeProjectionLag  = errors.New("monitor: reporting projection lag cannot be negative")
	ErrReportingPressureNegativeRebuildQueue   = errors.New("monitor: reporting rebuild queue cannot be negative")
	ErrReportingPressureNegativeQueryLoad      = errors.New("monitor: reporting query load cannot be negative")
)

const (
	ReportingPressureMetricProjectionLagSec   = "reporting_projection_lag_sec"
	ReportingPressureMetricRebuildQueueDepth  = "reporting_rebuild_queue_depth"
	ReportingPressureMetricQueryLoadPct       = "reporting_query_load_pct"
)

type ReportingPressureSnapshot struct {
	Source            string
	ProjectionLagSec  float64
	RebuildQueueDepth int
	QueryLoadPct      float64
	ObservedAt        time.Time
}

func (s ReportingPressureSnapshot) Validate() error {
	if strings.TrimSpace(s.Source) == "" {
		return ErrReportingPressureSourceRequired
	}
	if s.ObservedAt.IsZero() {
		return ErrReportingPressureObservedAtRequired
	}
	if s.ProjectionLagSec < 0 {
		return ErrReportingPressureNegativeProjectionLag
	}
	if s.RebuildQueueDepth < 0 {
		return ErrReportingPressureNegativeRebuildQueue
	}
	if s.QueryLoadPct < 0 {
		return ErrReportingPressureNegativeQueryLoad
	}

	return nil
}

type ReportingPressureThresholdProfile struct {
	ProjectionLagPolicy EarlyWarningThresholdPolicy
	RebuildQueuePolicy  EarlyWarningThresholdPolicy
	QueryLoadPolicy     EarlyWarningThresholdPolicy
}

func (p ReportingPressureThresholdProfile) Validate() error {
	if err := p.ProjectionLagPolicy.Validate(); err != nil {
		return err
	}
	if err := p.RebuildQueuePolicy.Validate(); err != nil {
		return err
	}
	if err := p.QueryLoadPolicy.Validate(); err != nil {
		return err
	}

	return nil
}

func DefaultReportingProjectionLagThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         ReportingPressureMetricProjectionLagSec,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      5,
		MediumThreshold:   20,
		HighThreshold:     60,
		CriticalThreshold: 180,
	}
}

func DefaultReportingRebuildQueueThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         ReportingPressureMetricRebuildQueueDepth,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      1,
		MediumThreshold:   5,
		HighThreshold:     20,
		CriticalThreshold: 100,
	}
}

func DefaultReportingQueryLoadThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         ReportingPressureMetricQueryLoadPct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      40,
		MediumThreshold:   60,
		HighThreshold:     80,
		CriticalThreshold: 95,
	}
}

func DefaultReportingPressureThresholdProfile() ReportingPressureThresholdProfile {
	return ReportingPressureThresholdProfile{
		ProjectionLagPolicy: DefaultReportingProjectionLagThresholdPolicy(),
		RebuildQueuePolicy:  DefaultReportingRebuildQueueThresholdPolicy(),
		QueryLoadPolicy:     DefaultReportingQueryLoadThresholdPolicy(),
	}
}

func EvaluateReportingPressureEarlyWarnings(
	snapshot ReportingPressureSnapshot,
	profile ReportingPressureThresholdProfile,
) ([]EarlyWarningSignal, error) {
	if err := snapshot.Validate(); err != nil {
		return nil, err
	}
	if err := profile.Validate(); err != nil {
		return nil, err
	}

	signals := make([]EarlyWarningSignal, 0)

	projectionLagSignal, ok, err := buildReportingPressureSignal(
		snapshot,
		profile.ProjectionLagPolicy,
		snapshot.ProjectionLagSec,
		"reporting projection lag detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, projectionLagSignal)
	}

	rebuildQueueSignal, ok, err := buildReportingPressureSignal(
		snapshot,
		profile.RebuildQueuePolicy,
		float64(snapshot.RebuildQueueDepth),
		"reporting rebuild queue pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, rebuildQueueSignal)
	}

	queryLoadSignal, ok, err := buildReportingPressureSignal(
		snapshot,
		profile.QueryLoadPolicy,
		snapshot.QueryLoadPct,
		"reporting query load pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, queryLoadSignal)
	}

	return signals, nil
}

func buildReportingPressureSignal(
	snapshot ReportingPressureSnapshot,
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
		SignalTypeReportingLag,
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
